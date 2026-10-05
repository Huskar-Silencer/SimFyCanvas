import 'dart:ui';

import '../math/matrix2d.dart';
import 'collection.dart';
import 'node.dart';

/// Independent redraw unit. Child content is baked into a [Picture] so
/// stage pan/zoom only re-composites the cached picture.
class Layer extends Collection {
  Layer({
    super.id,
    super.name,
    super.x,
    super.y,
    super.scaleX,
    super.scaleY,
    super.rotation,
    super.offsetX,
    super.offsetY,
    super.opacity,
    super.visible,
    super.listening,
    super.draggable,
    super.zIndex,
  });

  Picture? _picture;
  bool _pictureDirty = true;
  int pictureRebuilds = 0;

  bool get isPictureDirty => _pictureDirty;

  void markPictureDirty() {
    _pictureDirty = true;
  }

  void paint(Canvas canvas) {
    if (!visible || worldOpacity <= 0) {
      return;
    }
    if (_pictureDirty || _picture == null) {
      _picture?.dispose();
      final recorder = PictureRecorder();
      final recording = Canvas(recorder);
      final inverse = worldMatrix.inverted();
      _paintSubtree(recording, this, inverse);
      _picture = recorder.endRecording();
      _pictureDirty = false;
      pictureRebuilds++;
    }
    canvas.save();
    worldMatrix.applyToCanvas(canvas);
    canvas.drawPicture(_picture!);
    canvas.restore();
  }

  void _paintSubtree(Canvas canvas, Node node, Matrix2D inverseLayer) {
    if (!node.visible || node.worldOpacity <= 0) {
      return;
    }
    if (node != this) {
      node.paintOn(canvas, inverseLayer);
    }
    if (node is Collection) {
      for (final child in node.children) {
        _paintSubtree(canvas, child, inverseLayer);
      }
    }
  }

  @override
  void destroy() {
    _picture?.dispose();
    _picture = null;
    super.destroy();
  }
}
