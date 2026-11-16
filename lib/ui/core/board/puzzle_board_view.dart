import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import 'board_motion.dart';
import 'board_verb.dart';
import 'puzzle_board.dart';

/// The one place in the app that turns touch into puzzle moves.
///
/// This is the Declarative Dragging engine: a puzzle declares which future
/// states a drag can reach (`movesFor`), and the engine synthesises the float,
/// the drop zones, the snapping and the settle from that. No puzzle writes
/// gesture code, so every puzzle feels the same.
///
/// Tap is first-class: a tap is a drag that resolved immediately, which is what
/// keeps every board playable without dragging.
class PuzzleBoardView<S extends PuzzleState> extends StatefulWidget {
  const PuzzleBoardView({
    super.key,
    required this.board,
    required this.onMove,
    this.onSolved,
    this.enabled = true,
  });

  final PuzzleBoard<S> board;
  final ValueChanged<PuzzleMove<S>> onMove;

  /// Called once the win cascade has finished, so the celebration is seen
  /// before a dialog covers it.
  final VoidCallback? onSolved;

  final bool enabled;

  @override
  State<PuzzleBoardView<S>> createState() => _PuzzleBoardViewState<S>();
}

class _DropTarget<S extends PuzzleState> {
  const _DropTarget(this.move, this.bounds);

  final PuzzleMove<S> move;
  final Rect bounds;
}

class _PuzzleBoardViewState<S extends PuzzleState>
    extends State<PuzzleBoardView<S>> with TickerProviderStateMixin {
  late final AnimationController _lift =
      AnimationController.unbounded(vsync: this, value: 0);
  late final AnimationController _settle =
      AnimationController.unbounded(vsync: this, value: 0);
  late final AnimationController _zones =
      AnimationController(vsync: this, duration: BoardMotion.dropZone);
  late final AnimationController _invalid =
      AnimationController(vsync: this, duration: BoardMotion.invalid);
  late final AnimationController _win = AnimationController(vsync: this);
  late final AnimationController _press =
      AnimationController(vsync: this, duration: BoardMotion.press);
  late final AnimationController _transition = AnimationController(vsync: this);

  Size _size = Size.zero;
  Offset _down = Offset.zero;
  Offset _grab = Offset.zero;
  Offset _pointer = Offset.zero;

  ElementRef? _pressed;
  ElementRef? _lifted;

  /// The state the drag started from.
  ///
  /// The lifted copy is painted from this, not from the live state: once the
  /// move lands on finger-up the board's state is the *result*, and the thing
  /// under the finger is still the thing that was picked up. Painting it from
  /// the new state would turn a signpost arrow into its own destination
  /// mid-flight. The board underneath already paints the new state.
  S? _liftedState;
  List<_DropTarget<S>> _targets = const [];
  _DropTarget<S>? _hover;

  bool _settling = false;
  Offset _settleFrom = Offset.zero;
  Offset _settleTo = Offset.zero;

  /// True between handing this drag's move to the notifier and the first state
  /// change that lands after it.
  ///
  /// That one change is the point of the commit, not an interruption: it is what
  /// lets the same spring run over a model that has already moved. It is cleared
  /// by the very next change, so a reset or a new level arriving during the snap
  /// still drops the gesture — exempting a window of time instead would have
  /// missed exactly that.
  bool _committedDragChange = false;

  List<ElementRef> _celebrating = const [];
  Duration _winStagger = BoardMotion.winStagger;

  S? _transitionFrom;
  S? _transitionTo;

  /// Bumped on every transition so a cancelled ticker cannot clear a newer one.
  int _transitionToken = 0;

  bool get _isTransitioning => _transitionFrom != null;

  @override
  void didUpdateWidget(covariant PuzzleBoardView<S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = !identical(oldWidget.board.state, widget.board.state);
    if (changed && _lifted != null) {
      if (_committedDragChange) {
        // The change this drag asked for; keep the lifted copy flying.
        _committedDragChange = false;
      } else {
        // A reset or a new level landed mid-drag; drop the gesture, not the app.
        _clearDrag(notify: false);
      }
    }

    if (changed) {
      final duration =
          widget.board.transitionFor(oldWidget.board.state, widget.board.state);
      if (duration != null && duration > Duration.zero) {
        _transitionFrom = oldWidget.board.state;
        _transitionTo = widget.board.state;
        _transition.duration = duration;
        final token = ++_transitionToken;
        // `then` (not `whenComplete`) only runs when the controller reached its
        // end; a transition interrupted by the next move must not clear the new
        // one or fire a celebration.
        _transition.forward(from: 0).then((_) {
          if (!mounted || token != _transitionToken) return;
          setState(() {
            _transitionFrom = null;
            _transitionTo = null;
          });
          // The move is only now visible; the win waits for it.
          if (widget.board.isSolved) _celebrate();
        });
      } else if (_isTransitioning) {
        // A reset or a new level landed mid-transition: drop it with the state
        // it belonged to instead of painting the old move over the new board.
        _transitionToken++;
        _transition.stop();
        _transitionFrom = null;
        _transitionTo = null;
      }
    }

    if (!oldWidget.board.isSolved && widget.board.isSolved) {
      // A transition is running: the celebration is fired above when it ends.
      if (!_isTransitioning) _celebrate();
    }
  }

  @override
  void dispose() {
    _lift.dispose();
    _settle.dispose();
    _zones.dispose();
    _invalid.dispose();
    _win.dispose();
    _press.dispose();
    _transition.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- geometry

  Offset _normalize(Offset local) => _size.width <= 0
      ? Offset.zero
      : Offset(local.dx / _size.width, local.dy / _size.height);

  Offset get _liftOffset {
    if (_lifted == null) return Offset.zero;
    if (_settling) {
      return Offset.lerp(_settleFrom, _settleTo, _settle.value) ?? _settleTo;
    }
    final rise =
        -BoardMotion.fingerOffset * _lift.value.clamp(0.0, 1.5).toDouble();
    return _pointer - _grab + Offset(0, rise);
  }

  double get _liftScale =>
      1 + (BoardMotion.liftScale - 1) * _lift.value.clamp(0.0, 1.5).toDouble();

  BoardHighlight get _highlight {
    final pops = <ElementRef, double>{};
    final duration = _win.duration;
    if (_celebrating.isNotEmpty && duration != null && _win.isAnimating) {
      final elapsed = _win.value * duration.inMilliseconds;
      final stagger = _winStagger.inMilliseconds;
      for (var i = 0; i < _celebrating.length; i++) {
        final progress =
            (elapsed - i * stagger) / BoardMotion.winCell.inMilliseconds;
        if (progress > 0 && progress < 1) {
          pops[_celebrating[i]] = progress;
        }
      }
    }
    return BoardHighlight(
      pressed: _pressed,
      pressScale: 1 - (1 - BoardMotion.pressScale) * _press.value,
      lifted: _lifted,
      liftOffset: _liftOffset,
      liftScale: _liftScale,
      targets: {for (final target in _targets) target.move.target!},
      targetOpacity: _zones.value,
      hover: _hover?.move.target,
      invalidOpacity: _invalid.value,
      pops: pops,
    );
  }

  // ------------------------------------------------------------------ gestures

  void _handlePanDown(DragDownDetails details) {
    _down = details.localPosition;
  }

  void _handlePanStart(DragStartDetails details) {
    if (!widget.enabled || _settling) return;
    final element = widget.board.hitTest(_normalize(_down));
    if (element == null) return;

    final targets = <_DropTarget<S>>[];
    for (final move in widget.board.movesFor(element)) {
      final target = move.target;
      if (target == null) continue;
      final bounds = widget.board.boundsOf(target);
      if (bounds != null) targets.add(_DropTarget(move, bounds));
    }
    if (targets.isEmpty) return;

    setState(() {
      _pressed = null;
      _lifted = element;
      _liftedState = widget.board.state;
      // Grab from where the finger went down, not where the pan crossed its
      // slop: using the pan start made every lifted cell jump by ~18dp.
      _grab = _down;
      _pointer = _down;
      _targets = targets;
      _hover = null;
    });
    _lift.value = 0;
    _lift.animateWith(SpringSimulation(BoardMotion.liftSpring, 0, 1, 0));
    _zones.forward(from: 0);
    emitVerb(BoardVerb.lift);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_lifted == null || _settling) return;
    final point = _normalize(details.localPosition);
    setState(() {
      _pointer = details.localPosition;
      _hover = _targetAt(point);
    });
  }

  /// Containment first, then the nearest target inside a forgiving radius, so
  /// a thumb does not have to land dead centre on a 3dp edge.
  _DropTarget<S>? _targetAt(Offset point) {
    for (final target in _targets) {
      if (target.bounds.inflate(0.012).contains(point)) return target;
    }
    _DropTarget<S>? nearest;
    var best = 0.09;
    for (final target in _targets) {
      final distance = (target.bounds.center - point).distance;
      if (distance < best) {
        best = distance;
        nearest = target;
      }
    }
    return nearest;
  }

  void _handlePanEnd(DragEndDetails details) => _finishDrag();

  void _handlePanCancel() => _finishDrag();

  void _finishDrag() {
    final lifted = _lifted;
    if (lifted == null || _settling) return;
    final hover = _hover;
    final current = _liftOffset;

    setState(() => _settling = true);

    if (hover != null) {
      final origin =
          widget.board.boundsOf(lifted)?.center ?? hover.bounds.center;
      final delta = hover.bounds.center - origin;
      _settleFrom = current;
      _settleTo = Offset(delta.dx * _size.width, delta.dy * _size.height);
      // The state lands now, in the frame of the finger-up; the spring below
      // only paints the landing. This used to call back when the spring ended,
      // which put the snap's whole duration between the finger and the board.
      // Motion decorates a move, it never gates it (PUZZLE_STYLE.md §4), and a
      // board with a transition still paints it over the new state.
      _committedDragChange = true;
      _settle.value = 0;
      _emitVerbFor(hover.move);
      widget.onMove(hover.move);
      _settle
          .animateWith(SpringSimulation(BoardMotion.snapSpring, 0, 1, 0))
          .whenCompleteOrCancel(_clearDrag);
    } else {
      _settleFrom = current;
      _settleTo = Offset.zero;
      _invalid.forward(from: 0).whenComplete(() {
        if (mounted) _invalid.value = 0;
      });
      emitVerb(BoardVerb.invalid);
      _settle
          .animateWith(SpringSimulation(BoardMotion.recoilSpring, 0, 1, 0))
          .whenCompleteOrCancel(_clearDrag);
    }
  }

  void _emitVerbFor(PuzzleMove<S> move) => emitVerb(
      move.kind == MoveKind.select ? BoardVerb.select : BoardVerb.place);

  void _clearDrag({bool notify = true}) {
    if (!mounted) return;
    _lift.stop();
    _settle.stop();
    _zones.stop();
    _lift.value = 0;
    _settle.value = 0;
    _zones.value = 0;
    _lifted = null;
    _liftedState = null;
    _targets = const [];
    _hover = null;
    _settling = false;
    _committedDragChange = false;
    if (notify) setState(() {});
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled || _settling || _lifted != null) return;
    final element = widget.board.hitTest(_normalize(details.localPosition));
    if (element == null) return;
    setState(() => _pressed = element);
    _press.forward(from: 0);
  }

  void _handleTapCancel() {
    if (_pressed == null) return;
    _press.reverse().whenComplete(() {
      if (mounted) setState(() => _pressed = null);
    });
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled || _settling || _lifted != null) {
      _handleTapCancel();
      return;
    }
    final element = widget.board.hitTest(_normalize(details.localPosition));
    if (element == null) {
      _handleTapCancel();
      return;
    }

    _handleTapCancel();

    // A tap is a drag that resolved immediately, so it lands in this frame.
    //
    // This used to run the snap spring first and commit the move when it ended,
    // which put 160ms of animation between the finger and the board: a tap on a
    // cell and the arrow it draws were two different moments. Motion decorates
    // a move, it never gates it. A board with something to show (a pour, a
    // turn) declares `transitionFor`, and the engine paints that once the state
    // has already moved, so the move is instant and still animated.
    _playTap(element);
  }

  /// The tap path, shared by the gesture and by a semantics node.
  ///
  /// A screen reader's tap and a finger's tap must land on the same move, so
  /// they go through one function rather than two that drift apart.
  void _playTap(ElementRef element) {
    final move = widget.board.tapMove(element);
    if (move == null) {
      emitVerb(BoardVerb.select);
      return;
    }
    emitVerb(move.kind == MoveKind.select ? BoardVerb.select : BoardVerb.place);
    widget.onMove(move);
  }

  // -------------------------------------------------------------------- win

  void _celebrate() {
    final elements = widget.board.celebrationElements.take(96).toList();
    if (elements.isEmpty) {
      widget.onSolved?.call();
      return;
    }
    _celebrating = elements;
    _winStagger = BoardMotion.staggerFor(elements.length);
    final total = BoardMotion.winCell.inMilliseconds +
        _winStagger.inMilliseconds * (elements.length - 1);
    _win.duration = Duration(milliseconds: total);
    emitVerb(BoardVerb.solve);
    _win.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _celebrating = const []);
      widget.onSolved?.call();
    });
  }

  // ------------------------------------------------------------------ build

  /// The value a listener hears, with "fixed" on a given.
  String? _spokenValue(ElementRef element) {
    final value = widget.board.valueOf(element);
    final fixed = widget.board.isFixed(element);
    if (value != null && value.isNotEmpty) {
      return fixed ? '$value, fixed' : value;
    }
    return fixed ? 'fixed' : null;
  }

  /// The summary line, plus whatever the board says no element can carry.
  String _spokenSummary() {
    final details = widget.board.semanticsDetails;
    return details == null || details.isEmpty
        ? widget.board.semanticsSummary
        : '${widget.board.semanticsSummary}. $details';
  }

  /// One semantics node per element, laid over the paint at that element's own
  /// bounds, in the same order the elements are painted.
  ///
  /// The nodes ignore pointers, so the gesture detector underneath still gets
  /// every touch: they exist for a listener and for an agent, not for a finger.
  List<Widget> _semanticsNodes(Size size) {
    final nodes = <Widget>[];
    for (final element in widget.board.elements) {
      final bounds = widget.board.boundsOf(element);
      if (bounds == null) continue;
      final action = widget.enabled ? widget.board.describeTap(element) : null;
      nodes.add(
        Positioned.fromRect(
          rect: Rect.fromLTRB(
            bounds.left * size.width,
            bounds.top * size.height,
            bounds.right * size.width,
            bounds.bottom * size.height,
          ),
          child: Semantics(
            container: true,
            textDirection: TextDirection.ltr,
            label: widget.board.describeElement(element),
            value: _spokenValue(element),
            hint: action == null ? null : 'tap to $action',
            onTap: action == null ? null : () => _playTap(element),
            child: const IgnorePointer(child: SizedBox.expand()),
          ),
        ),
      );
    }
    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    final palette = PuzzlePalette.of(context);
    final listenable = Listenable.merge(
        [_press, _lift, _settle, _zones, _invalid, _win, _transition]);

    return AspectRatio(
      aspectRatio: 1 / widget.board.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = constraints.biggest;
          return Semantics(
            container: true,
            explicitChildNodes: true,
            textDirection: TextDirection.ltr,
            label: _spokenSummary(),
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanDown: _handlePanDown,
                    onPanStart: _handlePanStart,
                    onPanUpdate: _handlePanUpdate,
                    onPanEnd: _handlePanEnd,
                    onPanCancel: _handlePanCancel,
                    onTapDown: _handleTapDown,
                    onTapUp: _handleTapUp,
                    onTapCancel: _handleTapCancel,
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: listenable,
                        builder: (context, _) => CustomPaint(
                          size: _size,
                          painter: _BoardPainter<S>(
                            board: widget.board,
                            palette: palette,
                            highlight: _highlight,
                            liftedState: _liftedState,
                            transitionFrom: _transitionFrom,
                            transitionTo: _transitionTo,
                            transitionT: _transition.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                ..._semanticsNodes(_size),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BoardPainter<S extends PuzzleState> extends CustomPainter {
  _BoardPainter({
    required this.board,
    required this.palette,
    required this.highlight,
    this.liftedState,
    this.transitionFrom,
    this.transitionTo,
    this.transitionT = 0,
  });

  final PuzzleBoard<S> board;
  final PuzzlePalette palette;
  final BoardHighlight highlight;
  final S? liftedState;
  final S? transitionFrom;
  final S? transitionTo;
  final double transitionT;

  @override
  void paint(Canvas canvas, Size size) {
    final view = PuzzleCanvas(
      canvas: canvas,
      size: size,
      palette: palette,
      highlight: highlight,
    );

    final from = transitionFrom;
    final to = transitionTo;
    if (from != null && to != null) {
      board.paintTransition(view, from, to, transitionT);
      return;
    }

    board.paint(view, board.state);

    final pressed = highlight.pressed;
    if (pressed != null) {
      _transformed(canvas, view, pressed, highlight.pressScale, Offset.zero,
          () => board.paintElement(view, board.state, pressed));
    }

    final lifted = highlight.lifted;
    if (lifted != null) {
      final carried = liftedState ?? board.state;
      _transformed(
          canvas,
          view,
          lifted,
          highlight.liftScale,
          highlight.liftOffset,
          () => board.paintElement(view, carried, lifted));

      // The refused drop: a red wash over the element on its way home.
      if (highlight.invalidOpacity > 0) {
        final rect = view
            .toPixels(board.boundsOf(lifted)!)
            .translate(highlight.liftOffset.dx, highlight.liftOffset.dy);
        final pulse = math.sin(math.pi * highlight.invalidOpacity);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          Paint()..color = palette.error.withValues(alpha: 0.22 * pulse),
        );
      }
    }

    for (final entry in highlight.pops.entries) {
      final progress = entry.value;
      if (progress <= 0 || progress >= 1) continue;
      final scale = 1 + 0.06 * math.sin(math.pi * progress);
      _transformed(canvas, view, entry.key, scale, Offset.zero,
          () => board.paintElement(view, board.state, entry.key));
    }
  }

  void _transformed(
    Canvas canvas,
    PuzzleCanvas view,
    ElementRef element,
    double scale,
    Offset offset,
    VoidCallback draw,
  ) {
    final bounds = board.boundsOf(element);
    if (bounds == null) return;
    final rect = view.toPixels(bounds);
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.scale(scale);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    draw();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoardPainter<S> oldDelegate) =>
      oldDelegate.board != board ||
      oldDelegate.highlight != highlight ||
      oldDelegate.palette != palette ||
      oldDelegate.liftedState != liftedState ||
      oldDelegate.transitionFrom != transitionFrom ||
      oldDelegate.transitionTo != transitionTo ||
      oldDelegate.transitionT != transitionT;
}
