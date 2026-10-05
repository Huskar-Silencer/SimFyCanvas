import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../paint/modern_style_painter.dart';
import '../paint/shape_style_painter.dart';
import 'collection.dart';
import 'event_dispatcher.dart';
import 'layer.dart';
import 'node.dart';

/// Root of the scene graph. Notifies [StageView] when a repaint is needed.
class Stage extends Collection with ChangeNotifier {
  Stage({
    this.width = 0,
    this.height = 0,
    super.id,
    super.name,
    super.x,
    super.y,
    super.scaleX,
    super.scaleY,
    super.rotation,
    super.offsetX,
    super.offsetY,
    super.listening,
  }) {
    events = NodeEventDispatcher(root: this, hitTest: intersect);
  }

  double width;
  double height;

  /// When true, the stage only dispatches pointer events and does not
  /// auto-drag [Node.draggable] ancestors. Editors own those gestures.
  bool get editMode => !events.autoDragEnabled;
  set editMode(bool value) => events.autoDragEnabled = !value;

  ShapeStylePainter stylePainter = const ModernStylePainter();
  late final NodeEventDispatcher events;
  bool _paintScheduled = false;
  bool _disposed = false;

  @override
  void add(Node node) {
    if (node is! Layer) {
      throw ArgumentError('Stage can only contain Layer nodes');
    }
    super.add(node);
  }

  void requestPaint() {
    if (_disposed || _paintScheduled) {
      return;
    }
    _paintScheduled = true;
    scheduleMicrotask(() {
      _paintScheduled = false;
      if (_disposed) {
        return;
      }
      notifyListeners();
    });
  }

  void updateWorld() {
    updateTransform(null, parentWorldChanged: true);
  }

  void paint(Canvas canvas) {
    updateWorld();
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, width, height));
    for (final child in children) {
      (child as Layer).paint(canvas);
    }
    canvas.restore();
  }

  Node? intersect(Offset stagePoint) {
    updateWorld();
    for (var i = children.length - 1; i >= 0; i--) {
      final hit = children[i].hitTest(stagePoint);
      if (hit != null) {
        return hit;
      }
    }
    return null;
  }

  void pointerDown(Offset stagePoint, {int pointer = 0, int buttons = 0}) {
    updateWorld();
    events.pointerDown(stagePoint, pointer: pointer, buttons: buttons);
  }

  void pointerMove(Offset stagePoint, {int pointer = 0, int buttons = 0}) {
    updateWorld();
    events.pointerMove(stagePoint, pointer: pointer, buttons: buttons);
  }

  void pointerUp(Offset stagePoint, {int pointer = 0, int buttons = 0}) {
    updateWorld();
    events.pointerUp(stagePoint, pointer: pointer, buttons: buttons);
  }

  void pointerCancel(Offset stagePoint, {int pointer = 0, int buttons = 0}) {
    updateWorld();
    events.pointerCancel(stagePoint, pointer: pointer, buttons: buttons);
  }

  @override
  void dispose() {
    _disposed = true;
    events.cancelAll();
    for (final child in List<Node>.from(children)) {
      child.destroy();
    }
    super.dispose();
  }
}
