import 'dart:math' as math;
import 'dart:ui';

import 'shape.dart';

/// Two endpoints in local coordinates. Optional [bend] is the on-curve
/// midpoint of a quadratic; null keeps the segment straight. [isArrow]
/// draws an arrowhead at the last point.
class LinearShape extends Shape {
  LinearShape({
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
    Offset? bend,
    bool isArrow = false,
  }) : _points = List<Offset>.from(points ?? const [Offset.zero, Offset(1, 0)]),
       _bend = bend,
       _isArrow = isArrow {
    _normalizePoints();
  }

  final List<Offset> _points;
  Offset? _bend;
  bool _isArrow;

  List<Offset> get points => List<Offset>.unmodifiable(_points);

  Offset get start => _points.isEmpty ? Offset.zero : _points.first;

  Offset get end => _points.length < 2 ? start : _points.last;

  Offset get chordMid => Offset.lerp(start, end, 0.5)!;

  /// On-curve midpoint shown as the bend handle.
  Offset get bend => _bend ?? chordMid;

  bool get isBent => _bend != null && (_bend! - chordMid).distance > 1;

  /// Quadratic control implied by [start], [bend], [end].
  Offset get quadraticControl {
    final m = bend;
    return Offset(
      2 * m.dx - 0.5 * start.dx - 0.5 * end.dx,
      2 * m.dy - 0.5 * start.dy - 0.5 * end.dy,
    );
  }

  bool get isArrow => _isArrow;
  set isArrow(bool value) {
    if (_isArrow == value) {
      return;
    }
    _isArrow = value;
    markContentDirty();
  }

  void setPoints(List<Offset> value) {
    if (value.length >= 3) {
      _points
        ..clear()
        ..add(value.first)
        ..add(value.last);
      _bend = value[1];
    } else {
      _points
        ..clear()
        ..addAll(value);
    }
    _normalizePoints();
    markContentDirty();
  }

  void setPoint(int index, Offset value) {
    if (index < 0 || index >= _points.length) {
      return;
    }
    _points[index] = value;
    markContentDirty();
  }

  void setBend(Offset? value) {
    _bend = value;
    markContentDirty();
  }

  void _normalizePoints() {
    if (_points.isEmpty) {
      _points.addAll(const [Offset.zero, Offset(1, 0)]);
      return;
    }
    if (_points.length == 1) {
      _points.add(_points.first + const Offset(1, 0));
    }
    if (_points.length > 2) {
      final first = _points.first;
      final last = _points.last;
      final mid = _points[1];
      _points
        ..clear()
        ..add(first)
        ..add(last);
      _bend ??= mid;
    }
  }

  @override
  Rect get localBounds {
    final control = isBent ? quadraticControl : null;
    var minX = start.dx;
    var minY = start.dy;
    var maxX = end.dx;
    var maxY = end.dy;
    void include(Offset p) {
      minX = math.min(minX, p.dx);
      minY = math.min(minY, p.dy);
      maxX = math.max(maxX, p.dx);
      maxY = math.max(maxY, p.dy);
    }

    include(end);
    if (control != null) {
      include(control);
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool hitTestLocal(Offset local) {
    final threshold = math.max(strokeWidth / 2 + 4, 6.0);
    if (!isBent) {
      return _distanceToSegment(local, start, end) <= threshold;
    }
    final control = quadraticControl;
    const steps = 16;
    var prev = start;
    for (var i = 1; i <= steps; i++) {
      final next = _quadratic(start, control, end, i / steps);
      if (_distanceToSegment(local, prev, next) <= threshold) {
        return true;
      }
      prev = next;
    }
    return false;
  }

  @override
  void drawLocal(Canvas canvas) {
    stylePainter.paintPolyline(
      canvas,
      [start, end],
      shapeStyle,
      arrow: isArrow,
      control: isBent ? quadraticControl : null,
    );
  }

  static Offset _quadratic(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * c.dx + t * t * b.dx,
      u * u * a.dy + 2 * u * t * c.dy + t * t * b.dy,
    );
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
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
