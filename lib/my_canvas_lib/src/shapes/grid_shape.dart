import 'dart:ui';

import 'shape.dart';

/// Infinite-feeling grid drawn in local space. Not interactive.
class GridShape extends Shape {
  GridShape({
    super.id,
    super.name,
    super.opacity,
    super.visible,
    super.listening = false,
    super.draggable = false,
    this.spacing = 32,
    double extent = 8000,
  }) : _extent = extent;

  final double spacing;
  final double _extent;

  @override
  Rect get localBounds =>
      Rect.fromLTWH(-_extent / 2, -_extent / 2, _extent, _extent);

  @override
  bool hitTestLocal(Offset local) => false;

  @override
  void drawLocal(Canvas canvas) {
    stylePainter.paintGrid(canvas, localBounds, spacing);
  }
}
