import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../core/stage.dart';

/// Hosts a [Stage] in the Flutter tree. One RenderBox for the whole scene.
class StageView extends LeafRenderObjectWidget {
  const StageView({super.key, required this.stage});

  final Stage stage;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderStage(stage: stage);
  }

  @override
  void updateRenderObject(BuildContext context, RenderStage renderObject) {
    renderObject.stage = stage;
  }
}

class RenderStage extends RenderBox {
  RenderStage({required Stage stage}) : _stage = stage;

  Stage _stage;
  Stage get stage => _stage;
  set stage(Stage value) {
    if (identical(_stage, value)) {
      return;
    }
    if (attached) {
      _stage.removeListener(markNeedsPaint);
      value.addListener(markNeedsPaint);
    }
    _stage = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _stage.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _stage.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  bool get isRepaintBoundary => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performResize() {
    size = constraints.biggest;
    _stage.width = size.width;
    _stage.height = size.height;
  }

  @override
  bool hitTestSelf(Offset position) => size.contains(position);

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    final local = globalToLocal(event.position);
    if (event is PointerDownEvent) {
      if (event.buttons == kSecondaryMouseButton) {
        return;
      }
      _stage.pointerDown(local, pointer: event.pointer, buttons: event.buttons);
    } else if (event is PointerMoveEvent) {
      _stage.pointerMove(local, pointer: event.pointer, buttons: event.buttons);
    } else if (event is PointerUpEvent) {
      _stage.pointerUp(local, pointer: event.pointer, buttons: event.buttons);
    } else if (event is PointerCancelEvent) {
      _stage.pointerCancel(
        local,
        pointer: event.pointer,
        buttons: event.buttons,
      );
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _stage.width = size.width;
    _stage.height = size.height;
    _stage.paint(canvas);
    canvas.restore();
  }
}
