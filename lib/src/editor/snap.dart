import 'dart:math' as math;
import 'dart:ui';

/// Snap distance in screen pixels.
const snapDistancePx = 8.0;

/// Points other shapes align to: the four corners and the center.
List<Offset> snapPointsOf(Rect rect) {
  return [
    rect.topLeft,
    rect.topRight,
    rect.bottomLeft,
    rect.bottomRight,
    rect.center,
  ];
}

/// Alignment lines to draw, each from one snapped point to another.
class SnapGuides {
  const SnapGuides([this.segments = const []]);

  final List<(Offset, Offset)> segments;

  bool get isEmpty => segments.isEmpty;
}

class SnapResult {
  const SnapResult(this.offset, this.guides);

  static const none = SnapResult(Offset.zero, SnapGuides());

  /// Shift to apply to the moving points.
  final Offset offset;
  final SnapGuides guides;
}

/// Finds the smallest shift (per axis, within [threshold]) that lines up one
/// of [moving] with one of [targets], plus the guides for every alignment the
/// shift produces.
SnapResult snapPoints(
  List<Offset> moving,
  List<Offset> targets, {
  required double threshold,
}) {
  double? dx;
  double? dy;
  for (final m in moving) {
    for (final t in targets) {
      final ddx = t.dx - m.dx;
      final ddy = t.dy - m.dy;
      if (ddx.abs() <= threshold && (dx == null || ddx.abs() < dx.abs())) {
        dx = ddx;
      }
      if (ddy.abs() <= threshold && (dy == null || ddy.abs() < dy.abs())) {
        dy = ddy;
      }
    }
  }
  if (dx == null && dy == null) {
    return SnapResult.none;
  }

  final offset = Offset(dx ?? 0, dy ?? 0);
  final moved = [for (final m in moving) m + offset];
  return SnapResult(
    offset,
    SnapGuides([
      if (dx != null) ..._alignedSegments(moved, targets, vertical: true),
      if (dy != null) ..._alignedSegments(moved, targets, vertical: false),
    ]),
  );
}

/// One segment per shared x (vertical) or y (horizontal) line, spanning every
/// moved and target point on that line.
List<(Offset, Offset)> _alignedSegments(
  List<Offset> moved,
  List<Offset> targets, {
  required bool vertical,
}) {
  const epsilon = 0.01;
  double along(Offset p) => vertical ? p.dx : p.dy;
  double across(Offset p) => vertical ? p.dy : p.dx;
  Offset at(double line, double t) =>
      vertical ? Offset(line, t) : Offset(t, line);

  final segments = <(Offset, Offset)>[];
  final done = <double>[];
  for (final m in moved) {
    final line = along(m);
    if (done.any((d) => (d - line).abs() < epsilon)) {
      continue;
    }
    final onLine = [
      for (final t in targets)
        if ((along(t) - line).abs() < epsilon) across(t),
    ];
    if (onLine.isEmpty) {
      continue;
    }
    done.add(line);
    final all = [
      ...onLine,
      for (final p in moved)
        if ((along(p) - line).abs() < epsilon) across(p),
    ];
    segments.add((
      at(line, all.reduce(math.min)),
      at(line, all.reduce(math.max)),
    ));
  }
  return segments;
}
