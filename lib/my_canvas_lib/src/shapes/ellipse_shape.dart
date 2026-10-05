import 'dart:ui';

import 'box_shape.dart';

/// Ellipse in local space, origin at top-left of the bounding box.
class EllipseShape extends BoxShape {
  EllipseShape({
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
    super.fill,
    super.stroke,
    super.strokeWidth,
    super.width,
    super.height,
  });

  @override
  bool hitTestLocal(Offset local) {
    if (width <= 0 || height <= 0) {
      return false;
    }
    final nx = (local.dx - width / 2) / (width / 2);
    final ny = (local.dy - height / 2) / (height / 2);
    return nx * nx + ny * ny <= 1;
  }

  @override
  void drawLocal(Canvas canvas) {
    stylePainter.paintEllipse(canvas, localBounds, shapeStyle);
  }
}
