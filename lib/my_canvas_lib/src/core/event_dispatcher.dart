import 'dart:ui';

import 'node.dart';
import 'node_event.dart';

typedef NodeHitTest = Node? Function(Offset stagePosition);

/// Owns pointer sessions and dispatches scene-graph events.
///
/// Events target the node hit on pointer down, then bubble through its
/// ancestors. Each pointer has an independent session, so touch input cannot
/// overwrite mouse or other touch state.
class NodeEventDispatcher {
  NodeEventDispatcher({
    required this.root,
    required this.hitTest,
    this.clickDistance = 3,
  });

  final Node root;
  final NodeHitTest hitTest;
  final double clickDistance;
  final Map<int, _PointerSession> _sessions = {};

  bool autoDragEnabled = true;

  void pointerDown(Offset position, {int pointer = 0, int buttons = 0}) {
    final target = hitTest(position) ?? root;
    final event = dispatch(
      NodeEvents.pointerDown,
      target,
      position,
      pointer: pointer,
      buttons: buttons,
    );
    final session = _PointerSession(
      target: target,
      downPosition: position,
      lastPosition: position,
      buttons: buttons,
    );
    _sessions[pointer] = session;

    if (!autoDragEnabled || event.defaultPrevented) {
      return;
    }
    final node = _draggableAncestor(target);
    if (node == null) {
      return;
    }
    session.drag = _DragSession(
      node: node,
      startPosition: Offset(node.x, node.y),
      startParentLocal: _toParentLocal(node, position),
    );
    dispatch(
      NodeEvents.dragStart,
      node,
      position,
      pointer: pointer,
      buttons: buttons,
    );
  }

  void pointerMove(Offset position, {int pointer = 0, int buttons = 0}) {
    final session = _sessions[pointer];
    final previous = session?.lastPosition ?? position;
    final target = session?.target ?? hitTest(position) ?? root;
    dispatch(
      NodeEvents.pointerMove,
      target,
      position,
      pointer: pointer,
      buttons: buttons,
      delta: position - previous,
    );
    if (session == null) {
      return;
    }
    session.lastPosition = position;

    final drag = session.drag;
    if (drag == null) {
      return;
    }
    final now = _toParentLocal(drag.node, position);
    final delta = now - drag.startParentLocal;
    drag.node.x = drag.startPosition.dx + delta.dx;
    drag.node.y = drag.startPosition.dy + delta.dy;
    dispatch(
      NodeEvents.dragMove,
      drag.node,
      position,
      pointer: pointer,
      buttons: buttons,
      delta: position - previous,
    );
  }

  void pointerUp(Offset position, {int pointer = 0, int buttons = 0}) {
    final session = _sessions.remove(pointer);
    final target = hitTest(position) ?? root;
    final previous = session?.lastPosition ?? position;
    dispatch(
      NodeEvents.pointerUp,
      target,
      position,
      pointer: pointer,
      buttons: buttons,
      delta: position - previous,
    );
    if (session == null) {
      return;
    }
    if (identical(target, session.target) &&
        (position - session.downPosition).distance < clickDistance) {
      dispatch(
        NodeEvents.click,
        target,
        position,
        pointer: pointer,
        buttons: session.buttons,
      );
    }
    final drag = session.drag;
    if (drag != null) {
      dispatch(
        NodeEvents.dragEnd,
        drag.node,
        position,
        pointer: pointer,
        buttons: buttons,
      );
    }
  }

  void pointerCancel(Offset position, {int pointer = 0, int buttons = 0}) {
    final session = _sessions.remove(pointer);
    final target = session?.target ?? root;
    dispatch(
      NodeEvents.pointerCancel,
      target,
      position,
      pointer: pointer,
      buttons: buttons == 0 ? session?.buttons ?? 0 : buttons,
      canceled: true,
    );
    final drag = session?.drag;
    if (drag != null) {
      dispatch(
        NodeEvents.dragEnd,
        drag.node,
        position,
        pointer: pointer,
        buttons: buttons == 0 ? session?.buttons ?? 0 : buttons,
        canceled: true,
      );
    }
  }

  NodeEvent dispatch(
    String type,
    Node target,
    Offset position, {
    int pointer = 0,
    int buttons = 0,
    Offset delta = Offset.zero,
    bool canceled = false,
  }) {
    final event = NodeEvent(
      type: type,
      target: target,
      stagePosition: position,
      pointer: pointer,
      buttons: buttons,
      delta: delta,
      canceled: canceled,
    );
    Node? current = target;
    while (current != null && !event.stopped) {
      event.currentTarget = current;
      current.emit(event);
      current = current.parent;
    }
    return event;
  }

  void cancelAll() {
    for (final pointer in _sessions.keys.toList()) {
      pointerCancel(_sessions[pointer]!.lastPosition, pointer: pointer);
    }
  }

  Offset _toParentLocal(Node node, Offset position) {
    return node.parent?.worldToLocal(position) ?? position;
  }

  Node? _draggableAncestor(Node node) {
    Node? current = node;
    while (current != null) {
      if (current.draggable) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }
}

class _PointerSession {
  _PointerSession({
    required this.target,
    required this.downPosition,
    required this.lastPosition,
    required this.buttons,
  });

  final Node target;
  final Offset downPosition;
  Offset lastPosition;
  final int buttons;
  _DragSession? drag;
}

class _DragSession {
  _DragSession({
    required this.node,
    required this.startPosition,
    required this.startParentLocal,
  });

  final Node node;
  final Offset startPosition;
  final Offset startParentLocal;
}
