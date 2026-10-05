import 'dart:ui';

import 'shape.dart';

/// Shape sized by a local box, origin at top-left.
abstract class BoxShape extends Shape {
  BoxShape({
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
    double width = 0,
    double height = 0,
  }) : _width = width,
       _height = height;

  double _width;
  double _height;

  double get width => _width;
  set width(double value) {
    if (_width == value) {
      return;
    }
    _width = value;
    markLocalDirty();
  }

  double get height => _height;
  set height(double value) {
    if (_height == value) {
      return;
    }
    _height = value;
    markLocalDirty();
  }

  @override
  Rect get localBounds => Rect.fromLTWH(0, 0, _width, _height);
}
