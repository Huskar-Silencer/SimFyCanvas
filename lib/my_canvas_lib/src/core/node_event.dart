import 'dart:ui';

import 'node.dart';

typedef NodeEventListener = void Function(NodeEvent event);

/// Event names emitted by the scene graph.
abstract final class NodeEvents {
  static const pointerDown = 'pointerdown';
  static const pointerMove = 'pointermove';
  static const pointerUp = 'pointerup';
  static const pointerCancel = 'pointercancel';
  static const click = 'click';
  static const dragStart = 'dragstart';
  static const dragMove = 'dragmove';
  static const dragEnd = 'dragend';
}

class NodeEvent {
  NodeEvent({
    required this.type,
    required this.target,
    required this.stagePosition,
    this.pointer = 0,
    this.buttons = 0,
    this.delta = Offset.zero,
    this.canceled = false,
  }) : currentTarget = target;

  final String type;
  final Node target;
  Node currentTarget;
  final Offset stagePosition;
  final int pointer;
  final int buttons;
  final Offset delta;
  final bool canceled;
  bool _stopped = false;
  bool _defaultPrevented = false;

  bool get stopped => _stopped;

  /// Position in the coordinate system of the node currently receiving the
  /// event. This changes correctly while the event bubbles through parents.
  Offset get localPosition => currentTarget.worldToLocal(stagePosition);

  bool get defaultPrevented => _defaultPrevented;

  void stopPropagation() {
    _stopped = true;
  }

  /// Prevents built-in behavior such as dragging a [Node.draggable] node.
  void preventDefault() {
    _defaultPrevented = true;
  }
}
