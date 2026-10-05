import 'dart:math' as math;
import 'dart:ui';

import 'package:sim_fy_canvas/my_canvas_lib/fy_fl_canvas.dart';

import 'geom.dart';

enum HandleKind { nw, n, ne, e, se, s, sw, w, rotate, vertex, midpoint }

class HandleLayout {
  const HandleLayout(this.kind, this.center, {this.vertexIndex});

  final HandleKind kind;
  final Offset center;
  final int? vertexIndex;
}

/// Handle centers in document space. Squares sit slightly outside the box and
/// orbit the unrotated center with the element's angle.
List<HandleLayout> boxHandleLayouts(
  BoxSnapshot box, {
  required double zoom,
  bool includeSides = true,
}) {
  final z = math.max(zoom, 0.05);
  final margin = 4 / z;
  final x1 = box.x - margin;
  final y1 = box.y - margin;
  final x2 = box.x + box.width + margin;
  final y2 = box.y + box.height + margin;
  final cx = box.center.dx;
  final cy = box.center.dy;

  HandleLayout at(HandleKind kind, double x, double y) =>
      HandleLayout(kind, rotateAround(Offset(x, y), box.center, box.rotation));

  final minForSides = 40 / z;
  final showSides =
      includeSides &&
      box.width.abs() > minForSides &&
      box.height.abs() > minForSides;
  return [
    at(HandleKind.nw, x1, y1),
    at(HandleKind.ne, x2, y1),
    at(HandleKind.se, x2, y2),
    at(HandleKind.sw, x1, y2),
    if (showSides) ...[
      at(HandleKind.n, cx, y1),
      at(HandleKind.s, cx, y2),
      at(HandleKind.w, x1, cy),
      at(HandleKind.e, x2, cy),
    ],
    at(HandleKind.rotate, cx, y1 - 16 / z),
  ];
}

/// Multi-selection handles: corners and rotation only (aspect is locked).
List<HandleLayout> aabbHandleLayouts(Rect aabb, {required double zoom}) {
  return boxHandleLayouts(
    BoxSnapshot.fromRect(aabb),
    zoom: zoom,
    includeSides: false,
  );
}

List<HandleLayout> vertexHandleLayouts(LinearShape line, Node space) {
  Offset toSpace(Offset p) => space.worldToLocal(line.localToWorld(p));
  return [
    HandleLayout(HandleKind.midpoint, toSpace(line.bend), vertexIndex: 0),
    for (var i = 0; i < line.points.length; i++)
      HandleLayout(HandleKind.vertex, toSpace(line.points[i]), vertexIndex: i),
  ];
}

/// Closest handle within the hit radius of [doc], or null.
HandleLayout? hitHandle(List<HandleLayout> handles, Offset doc, double zoom) {
  HandleLayout? best;
  // ~14 screen pixels, matching the visual handle size.
  var bestDist = 14 / math.max(zoom, 0.05);
  for (final handle in handles) {
    final dist = (handle.center - doc).distance;
    if (dist <= bestDist) {
      best = handle;
      bestDist = dist;
    }
  }
  return best;
}
