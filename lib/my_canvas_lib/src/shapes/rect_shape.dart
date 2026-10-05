import 'dart:ui';

import 'box_shape.dart';

/// Axis-aligned rectangle in local space, origin at top-left.
class RectShape extends BoxShape {
  RectShape({
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
    return localBounds.contains(local);
  }

  @override
  void drawLocal(Canvas canvas) {
    stylePainter.paintRect(canvas, localBounds, shapeStyle);
  }
}
