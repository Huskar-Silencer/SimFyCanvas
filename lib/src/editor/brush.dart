import 'dart:ui';

class BrushStyle {
  const BrushStyle({
    this.stroke = const Color(0xFF1F2937),
    this.fill = const Color(0x6693C5FD),
    this.strokeWidth = 2,
    this.opacity = 1,
  });

  final Color stroke;
  final Color fill;
  final double strokeWidth;
  final double opacity;

  BrushStyle copyWith({
    Color? stroke,
    Color? fill,
    double? strokeWidth,
    double? opacity,
  }) {
    return BrushStyle(
      stroke: stroke ?? this.stroke,
      fill: fill ?? this.fill,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      opacity: opacity ?? this.opacity,
    );
  }
}
