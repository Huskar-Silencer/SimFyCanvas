import 'dart:math' as math;
import 'dart:ui' hide TextStyle;

import 'package:flutter/painting.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import '../shapes/text_layout.dart';
import 'shape_style.dart';
import 'shape_style_painter.dart';

/// Clean vector look: solid fills, round caps, slight corner radius.
class ModernStylePainter extends ShapeStylePainter {
  const ModernStylePainter({this.rectRadius = 8});

  final double rectRadius;

  @override
  void paintRect(Canvas canvas, Rect rect, ShapeStyle style) {
    if (rect.isEmpty) {
      return;
    }
    final radius = math.min(rectRadius, math.min(rect.width, rect.height) / 4);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    if (style.hasFill) {
      canvas.drawRRect(rrect, _fill(style));
    }
    if (style.hasStroke) {
      canvas.drawRRect(rrect, _stroke(style));
    }
  }

  @override
  void paintEllipse(Canvas canvas, Rect rect, ShapeStyle style) {
    if (rect.isEmpty) {
      return;
    }
    if (style.hasFill) {
      canvas.drawOval(rect, _fill(style));
    }
    if (style.hasStroke) {
      canvas.drawOval(rect, _stroke(style));
    }
  }

  @override
  void paintDiamond(Canvas canvas, Rect rect, ShapeStyle style) {
    if (rect.isEmpty) {
      return;
    }
    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.center.dx, rect.bottom)
      ..lineTo(rect.left, rect.center.dy)
      ..close();
    if (style.hasFill) {
      canvas.drawPath(path, _fill(style));
    }
    if (style.hasStroke) {
      canvas.drawPath(path, _stroke(style));
    }
  }

  @override
  void paintPolyline(
    Canvas canvas,
    List<Offset> points,
    ShapeStyle style, {
    bool arrow = false,
    Offset? control,
  }) {
    if (points.length < 2 || !style.hasStroke) {
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (control != null) {
      path.quadraticBezierTo(
        control.dx,
        control.dy,
        points.last.dx,
        points.last.dy,
      );
    } else {
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(path, _stroke(style));
    if (arrow) {
      final from = control ?? points[points.length - 2];
      _paintArrowHead(canvas, from, points.last, style);
    }
  }

  @override
  void paintFreehand(Canvas canvas, List<Offset> points, ShapeStyle style) {
    if (points.length < 2) {
      return;
    }
    final outline = getStroke(
      [for (final p in points) PointVector(p.dx, p.dy)],
      options: StrokeOptions(
        size: math.max(style.strokeWidth, 1) * 1.6,
        thinning: 0.35,
        smoothing: 0.6,
        streamline: 0.45,
        simulatePressure: true,
        isComplete: true,
      ),
    );
    if (outline.length < 3) {
      paintPolyline(canvas, points, style);
      return;
    }
    final path = Path()..moveTo(outline.first.dx, outline.first.dy);
    for (var i = 1; i < outline.length; i++) {
      path.lineTo(outline[i].dx, outline[i].dy);
    }
    path.close();
    final color = style.stroke ?? style.fill ?? const Color(0xFF111827);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color = color.withValues(alpha: color.a * style.opacity),
    );
  }

  @override
  void paintText(Canvas canvas, String text, Rect bounds, ShapeStyle style) {
    if (text.isEmpty || bounds.width <= 0) {
      return;
    }
    final color = style.fill ?? style.stroke ?? const Color(0xFF111827);
    layoutCanvasText(
      text,
      style.fontSize,
      color: color.withValues(alpha: color.a * style.opacity),
    ).paint(canvas, bounds.topLeft);
  }

  @override
  void paintGrid(Canvas canvas, Rect bounds, double spacing) {
    if (spacing <= 0 || bounds.isEmpty) {
      return;
    }
    final paint = Paint()
      ..color = const Color(0x14000000)
      ..strokeWidth = 1
      ..isAntiAlias = false;
    final startX = (bounds.left / spacing).floor() * spacing;
    final startY = (bounds.top / spacing).floor() * spacing;
    for (var x = startX; x <= bounds.right; x += spacing) {
      canvas.drawLine(Offset(x, bounds.top), Offset(x, bounds.bottom), paint);
    }
    for (var y = startY; y <= bounds.bottom; y += spacing) {
      canvas.drawLine(Offset(bounds.left, y), Offset(bounds.right, y), paint);
    }
  }

  void _paintArrowHead(
    Canvas canvas,
    Offset from,
    Offset to,
    ShapeStyle style,
  ) {
    final delta = to - from;
    final length = delta.distance;
    if (length < 1) {
      return;
    }
    final dir = delta / length;
    final size = math.max(10.0, style.strokeWidth * 3.5);
    final back = to - dir * size;
    final perp = Offset(-dir.dy, dir.dx) * (size * 0.45);
    final path = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(back.dx + perp.dx, back.dy + perp.dy)
      ..lineTo(back.dx - perp.dx, back.dy - perp.dy)
      ..close();
    canvas.drawPath(path, _fill(style, color: style.stroke));
  }

  Paint _fill(ShapeStyle style, {Color? color}) {
    final c = color ?? style.fill ?? const Color(0x00000000);
    return Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = c.withValues(alpha: c.a * style.opacity);
  }

  Paint _stroke(ShapeStyle style) {
    final c = style.stroke ?? const Color(0x00000000);
    return Paint()
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = style.strokeWidth
      ..color = c.withValues(alpha: c.a * style.opacity);
  }
}
