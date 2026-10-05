import 'dart:ui';

import '../core/node.dart';
import '../math/matrix2d.dart';
import '../paint/modern_style_painter.dart';
import '../paint/shape_style.dart';
import '../paint/shape_style_painter.dart';

abstract class Shape extends Node {
  Shape({
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
    Color? fill,
    Color? stroke,
    double strokeWidth = 1,
  }) : _fill = fill,
       _stroke = stroke,
       _strokeWidth = strokeWidth;

  Color? _fill;
  Color? _stroke;
  double _strokeWidth;

  Color? get fill => _fill;
  set fill(Color? value) {
    if (_fill == value) {
      return;
    }
    _fill = value;
    markContentDirty();
  }

  Color? get stroke => _stroke;
  set stroke(Color? value) {
    if (_stroke == value) {
      return;
    }
    _stroke = value;
    markContentDirty();
  }

  double get strokeWidth => _strokeWidth;
  set strokeWidth(double value) {
    if (_strokeWidth == value) {
      return;
    }
    _strokeWidth = value;
    markContentDirty();
  }

  ShapeStyle get shapeStyle => ShapeStyle(
    fill: fill,
    stroke: stroke,
    strokeWidth: strokeWidth,
    opacity: worldOpacity,
  );

  ShapeStylePainter get stylePainter =>
      stage?.stylePainter ?? const ModernStylePainter();

  void drawLocal(Canvas canvas);

  /// Rotate and scale around the local-bounds center.
  /// [x]/[y] remain the unrotated top-left (or circle center).
  @override
  void updateLocalMatrix() {
    final pivot = localBounds.center;
    localMatrix.setIdentity();
    localMatrix.translate(x, y);
    localMatrix.translate(pivot.dx, pivot.dy);
    localMatrix.rotate(rotation);
    localMatrix.scale(scaleX, scaleY);
    localMatrix.translate(-pivot.dx - offsetX, -pivot.dy - offsetY);
    localDirty = false;
  }

  @override
  void paintOn(Canvas canvas, Matrix2D inverseLayer) {
    canvas.save();
    final relative = Matrix2D.copy(inverseLayer);
    relative.multiply(worldMatrix);
    relative.applyToCanvas(canvas);
    drawLocal(canvas);
    canvas.restore();
  }

  Paint fillPaint() {
    return Paint()
      ..style = PaintingStyle.fill
      ..color = (_fill ?? const Color(0x00000000)).withValues(
        alpha: (_fill?.a ?? 0) * worldOpacity,
      );
  }

  Paint strokePaint() {
    return Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..color = (_stroke ?? const Color(0x00000000)).withValues(
        alpha: (_stroke?.a ?? 0) * worldOpacity,
      );
  }
}
