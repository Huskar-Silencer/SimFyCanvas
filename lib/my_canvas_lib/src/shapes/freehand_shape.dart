import 'dart:math' as math;
import 'dart:ui';

import 'shape.dart';

/// Freehand stroke stored as local sample points.
class FreehandShape extends Shape {
  FreehandShape({
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
    List<Offset>? points,
  }) : _points = List<Offset>.from(points ?? const <Offset>[]);

  final List<Offset> _points;

  List<Offset> get points => List<Offset>.unmodifiable(_points);

  void setPoints(List<Offset> value) {
    _points
      ..clear()
      ..addAll(value);
    markContentDirty();
  }

  void addPoint(Offset value) {
    _points.add(value);
    markContentDirty();
  }

  @override
  Rect get localBounds {
    if (_points.isEmpty) {
      return Rect.zero;
    }
    var minX = _points.first.dx;
    var minY = _points.first.dy;
    var maxX = minX;
    var maxY = minY;
    for (final p in _points) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool hitTestLocal(Offset local) {
    final threshold = math.max(strokeWidth * 1.5, 8.0);
    for (final p in _points) {
      if ((p - local).distance <= threshold) {
        return true;
      }
    }
    for (var i = 1; i < _points.length; i++) {
      if (LinearHit.distanceToSegment(local, _points[i - 1], _points[i]) <=
          threshold) {
        return true;
      }
    }
    return false;
  }

  @override
  void drawLocal(Canvas canvas) {
    stylePainter.paintFreehand(canvas, _points, shapeStyle);
  }
}

class LinearHit {
  static double distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final length2 = ab.distanceSquared;
    if (length2 < 1e-8) {
      return (p - a).distance;
    }
    final t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / length2;
    final clamped = t.clamp(0.0, 1.0);
    final proj = a + ab * clamped;
    return (p - proj).distance;
  }
}
