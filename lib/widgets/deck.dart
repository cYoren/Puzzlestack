import 'package:flutter/material.dart';

import '../utils/design_system.dart';

/// The Puzzlestack mark: three cards in a stack, the top one live.
///
/// Drawn rather than iconified, because it is the one shape the whole app is
/// built from: home is a stack, the feed deals one card at a time.
class DeckMark extends StatelessWidget {
  const DeckMark({super.key, this.size = 24, this.color, this.liveColor});

  final double size;
  final Color? color;
  final Color? liveColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DeckMarkPainter(
          ink: color ?? Theme.of(context).colorScheme.onSurface,
          live: liveColor ?? DesignSystem.accent(context),
        ),
      ),
    );
  }
}

class _DeckMarkPainter extends CustomPainter {
  const _DeckMarkPainter({required this.ink, required this.live});

  final Color ink;
  final Color live;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cardW = w * 0.60;
    final double cardH = h * 0.72;
    final double radius = w * 0.10;
    final double stroke = (w * 0.075).clamp(1.1, 2.4);

    // Two cards behind, peeking up and to the left, drawn as hairlines.
    final Paint back = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = ink.withValues(alpha: 0.40);

    for (int i = 1; i >= 0; i--) {
      final double dx = w * 0.16 * i;
      final double dy = h * 0.14 * i;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx, dy, cardW, cardH),
          Radius.circular(radius),
        ),
        back,
      );
    }

    // The live card: filled, sitting low and right, so the stack reads at any
    // size from a status bar to a store screenshot.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w - cardW, h - cardH, cardW, cardH),
        Radius.circular(radius),
      ),
      Paint()..color = live,
    );
  }

  @override
  bool shouldRepaint(_DeckMarkPainter old) =>
      old.ink != ink || old.live != live;
}

/// The wordmark: PUZZLE over STACK, tight enough to read as one object.
///
/// Two lines is the whole point. A single flat line is what every other
/// puzzle app does; stacked type is the name doing what the name says.
class StackWordmark extends StatelessWidget {
  const StackWordmark({
    super.key,
    this.size = 30,
    this.color,
    this.showMark = true,
    this.liveColor,
  });

  /// Cap height of each line, in logical pixels.
  final double size;
  final Color? color;
  final bool showMark;
  final Color? liveColor;

  @override
  Widget build(BuildContext context) {
    final Color ink = color ?? Theme.of(context).colorScheme.onSurface;
    final Color live = liveColor ?? DesignSystem.accent(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showMark) ...[
          DeckMark(size: size * 1.15, color: ink, liveColor: live),
          SizedBox(width: size * 0.42),
        ],
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PUZZLE',
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: size,
                height: 0.86,
                letterSpacing: size * 0.012,
                color: ink,
              ),
            ),
            Text(
              'STACK',
              style: TextStyle(
                fontFamily: 'Bebas Neue',
                fontSize: size,
                height: 0.86,
                letterSpacing: size * 0.012,
                color: live,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One paper card. [pile] puts empty cards behind it, so the surface reads as
/// a deck with more underneath.
class DeckCard extends StatelessWidget {
  const DeckCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DesignSystem.spaceMD),
    this.radius = 22,
    this.pile = 0,
    this.color,
    this.onTap,
    this.lift = 1,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final int pile;
  final Color? color;
  final VoidCallback? onTap;
  final double lift;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final Color cardColor = color ?? DesignSystem.cardOf(context);
    final Color hair = DesignSystem.hairline(context);

    final Widget front = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: hair, width: 1),
        boxShadow:
            DesignSystem.deckShadow(Theme.of(context).brightness, lift: lift),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: Padding(padding: padding, child: child),
      ),
    );

    Widget content = front;
    if (pile > 0) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = pile; i >= 1; i--)
            Positioned(
              left: i * 8.0,
              right: i * 8.0,
              top: 0,
              bottom: -i * 8.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    Colors.black.withValues(alpha: 0.03 * i),
                    cardColor,
                  ),
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: hair, width: 1),
                ),
              ),
            ),
          front,
        ],
      );
    }

    if (onTap == null) return content;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
    );
  }
}

/// A hairline chip with a label. Used for category, difficulty and counters.
class DeckChip extends StatelessWidget {
  const DeckChip({
    super.key,
    required this.label,
    this.icon,
    this.tint,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color? tint;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final Color color = tint ?? DesignSystem.muted(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignSystem.radiusFull),
        border: Border.all(color: DesignSystem.hairline(context), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize:
                  dense ? DesignSystem.fontSize2XS : DesignSystem.fontSizeXS,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bebas numerals, for counters and card numbers. Tabular by construction:
/// every glyph is the same height, which is what makes "003 / 313" sit still.
class DeckNumber extends StatelessWidget {
  const DeckNumber(
    this.text, {
    super.key,
    this.size = 20,
    this.color,
    this.weight,
  });

  final String text;
  final double size;
  final Color? color;
  final FontWeight? weight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Bebas Neue',
        fontSize: size,
        height: 1.0,
        letterSpacing: 0.4,
        fontWeight: weight,
        color: color ?? Theme.of(context).colorScheme.onSurface,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
