import 'package:flutter/material.dart';
import 'package:puzzle/utils/haptic_feedback.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'tangle_fix_engine.dart';

part 'tangle_fix_provider.g.dart';

class TangleFixState {
  final List<TangleNode> nodes;
  final List<TangleEdge> edges;
  final bool isSolved;
  final String? draggingNodeId;
  final Set<int> intersectingEdgeIndices;
  final bool gameCompleted;

  TangleFixState({
    required this.nodes,
    required this.edges,
    this.isSolved = false,
    this.draggingNodeId,
    this.intersectingEdgeIndices = const {},
    this.gameCompleted = false,
  });

  TangleFixState copyWith({
    List<TangleNode>? nodes,
    List<TangleEdge>? edges,
    bool? isSolved,
    String? draggingNodeId,
    bool clearDraggingNodeId = false,
    Set<int>? intersectingEdgeIndices,
    bool? gameCompleted,
  }) {
    return TangleFixState(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      isSolved: isSolved ?? this.isSolved,
      draggingNodeId:
          clearDraggingNodeId ? null : (draggingNodeId ?? this.draggingNodeId),
      intersectingEdgeIndices:
          intersectingEdgeIndices ?? this.intersectingEdgeIndices,
      gameCompleted: gameCompleted ?? this.gameCompleted,
    );
  }
}

@riverpod
class TangleFixNotifier extends _$TangleFixNotifier {
  final _engine = TangleFixEngine();
  static const int defaultNodeCount = 8;

  @override
  TangleFixState build() {
    return TangleFixState(nodes: [], edges: []);
  }

  void initGame(Size bounds) {
    List<TangleNode> nodes;
    List<TangleEdge> edges = _engine.generateEdges(defaultNodeCount);
    Set<int> intersecting;

    int attempts = 0;
    do {
      nodes = _engine.generateNodes(bounds, defaultNodeCount);
      intersecting = _engine.getIntersectingEdgeIndices(nodes, edges);
      attempts++;
    } while (intersecting.isEmpty && attempts < 15);

    state = TangleFixState(
      nodes: nodes,
      edges: edges,
      isSolved: intersecting.isEmpty,
      intersectingEdgeIndices: intersecting,
      gameCompleted: false,
    );
  }

  String? _findClosestNodeId(Offset position) {
    String? closestNodeId;
    double minDistance = 45.0; // Generous hitbox
    for (final node in state.nodes) {
      final dist = (node.position - position).distance;
      if (dist < minDistance) {
        minDistance = dist;
        closestNodeId = node.id;
      }
    }
    return closestNodeId;
  }

  void _moveNodeTo(
    String nodeId,
    Offset position,
    Size bounds, {
    bool completeIfSolved = false,
  }) {
    const padding = 25.0;
    final clampedPosition = Offset(
      position.dx.clamp(padding, bounds.width - padding),
      position.dy.clamp(padding, bounds.height - padding),
    );

    final updatedNodes = state.nodes.map((node) {
      if (node.id == nodeId) {
        return TangleNode(id: node.id, position: clampedPosition);
      }
      return node;
    }).toList();

    final intersecting =
        _engine.getIntersectingEdgeIndices(updatedNodes, state.edges);
    final solved = intersecting.isEmpty;

    state = state.copyWith(
      nodes: updatedNodes,
      intersectingEdgeIndices: intersecting,
      isSolved: solved,
      clearDraggingNodeId: completeIfSolved,
      gameCompleted: completeIfSolved && solved,
    );

    if (completeIfSolved && solved) {
      HapticFeedbackUtil.victory();
    }
  }

  void onTap(Offset position, Size bounds) {
    if (state.gameCompleted || state.nodes.isEmpty) return;

    final tappedNodeId = _findClosestNodeId(position);
    if (tappedNodeId != null) {
      HapticFeedbackUtil.lightImpact();
      if (state.draggingNodeId == tappedNodeId) {
        state = state.copyWith(clearDraggingNodeId: true);
      } else {
        state = state.copyWith(draggingNodeId: tappedNodeId);
      }
      return;
    }

    final selectedId = state.draggingNodeId;
    if (selectedId != null) {
      HapticFeedbackUtil.lightImpact();
      _moveNodeTo(selectedId, position, bounds, completeIfSolved: true);
    }
  }

  void onDragStart(Offset position) {
    if (state.gameCompleted) return;

    final closestNodeId = _findClosestNodeId(position);
    if (closestNodeId != null) {
      state = state.copyWith(draggingNodeId: closestNodeId);
      HapticFeedbackUtil.lightImpact();
    }
  }

  void onDragUpdate(Offset position, Size bounds) {
    if (state.draggingNodeId == null || state.gameCompleted) return;
    _moveNodeTo(state.draggingNodeId!, position, bounds);
  }

  void onDragEnd() {
    if (state.draggingNodeId == null) return;

    final isSolved = state.isSolved;
    state = state.copyWith(
      clearDraggingNodeId: true,
      gameCompleted: isSolved,
    );

    if (isSolved) {
      HapticFeedbackUtil.victory();
    }
  }
}
