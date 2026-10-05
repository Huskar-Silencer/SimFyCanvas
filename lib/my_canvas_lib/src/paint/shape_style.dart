import 'dart:ui';

/// Visual attributes passed to a [ShapeStylePainter]. Geometry stays on the node.
class ShapeStyle {
  const ShapeStyle({
    this.fill,
    this.stroke,
    this.strokeWidth = 2,
    this.opacity = 1,
    this.fontSize = 18,
  });

  final Color? fill;
  final Color? stroke;
  final double strokeWidth;
  final double opacity;
  final double fontSize;

  bool get hasFill => fill != null && fill!.a > 0;

  bool get hasStroke => stroke != null && stroke!.a > 0 && strokeWidth > 0;
}
