import 'dart:ui';

import 'shape_style.dart';

/// Swappable drawing backend. Nodes keep geometry; painters keep look.
abstract class ShapeStylePainter {
  const ShapeStylePainter();

  void paintRect(Canvas canvas, Rect rect, ShapeStyle style);

  void paintEllipse(Canvas canvas, Rect rect, ShapeStyle style);

  void paintDiamond(Canvas canvas, Rect rect, ShapeStyle style);

  void paintPolyline(
    Canvas canvas,
    List<Offset> points,
    ShapeStyle style, {
    bool arrow = false,
    Offset? control,
  });

  void paintFreehand(Canvas canvas, List<Offset> points, ShapeStyle style);

  void paintText(Canvas canvas, String text, Rect bounds, ShapeStyle style);

  void paintGrid(Canvas canvas, Rect bounds, double spacing);
}
