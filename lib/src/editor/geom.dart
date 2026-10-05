import 'dart:math' as math;
import 'dart:ui';

import 'package:sim_fy_canvas/my_canvas_lib/fy_fl_canvas.dart';

/// Unrotated top-left box plus a rotation around its center.
class BoxSnapshot {
  BoxSnapshot({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
  });

  BoxSnapshot.of(BoxShape node)
    : this(
        x: node.x,
        y: node.y,
        width: node.width,
        height: node.height,
        rotation: node.rotation,
      );

  BoxSnapshot.fromRect(Rect rect)
    : this(x: rect.left, y: rect.top, width: rect.width, height: rect.height);

  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  Offset get topLeft => Offset(x, y);

  /// The box before rotation.
  Rect get rect => Rect.fromLTWH(x, y, width, height);
  Offset get center => Offset(x + width / 2, y + height / 2);
}

Offset rotateAround(Offset point, Offset origin, double angle) {
  final v = point - origin;
  final cos = math.cos(angle);
  final sin = math.sin(angle);
  return Offset(
    origin.dx + v.dx * cos - v.dy * sin,
    origin.dy + v.dx * sin + v.dy * cos,
  );
}

/// Document-space AABB of a node's unpadded geometry.
Rect boundsInSpace(Node node, Node space) {
  final r = contentRect(node);
  return _pointsRect([
    for (final p in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight])
      space.worldToLocal(node.localToWorld(p)),
  ]);
}

/// Local-space rect of what a node actually draws.
Rect contentRect(Node node) {
  return switch (node) {
    LinearShape() => _pointsRect([
      ...node.points,
      if (node.isBent) node.quadraticControl,
    ]),
    FreehandShape() => _pointsRect(node.points),
    Group() => unionBounds([
      for (final child in node.children) boundsInSpace(child, node),
    ]),
    _ => node.localBounds,
  };
}

Rect _pointsRect(List<Offset> points) {
  if (points.isEmpty) {
    return Rect.zero;
  }
  var minX = points.first.dx;
  var minY = points.first.dy;
  var maxX = minX;
  var maxY = minY;
  for (final p in points) {
    minX = math.min(minX, p.dx);
    minY = math.min(minY, p.dy);
    maxX = math.max(maxX, p.dx);
    maxY = math.max(maxY, p.dy);
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

Rect unionBounds(Iterable<Rect> rects) {
  return rects.fold<Rect?>(null, (acc, r) => acc?.expandToInclude(r) ?? r) ??
      Rect.zero;
}

/// Flattens [Group] nodes so resize/rotate use the same path as a marquee
/// selection. Children must already be in document space; see [liftGroup].
List<Node> transformTargets(Iterable<Node> nodes) {
  return [
    for (final node in nodes)
      if (node is Group) ...transformTargets(node.children) else node,
  ];
}

/// Moves [group]'s translation onto its children and resets the group to the
/// origin, so child x/y match loose shapes in document space.
void liftGroup(Group group) {
  if (group.x == 0 && group.y == 0) {
    return;
  }
  final dx = group.x;
  final dy = group.y;
  for (final child in group.children) {
    child
      ..x += dx
      ..y += dy;
  }
  group
    ..x = 0
    ..y = 0;
}

/// Puts [group] back at the children's document-space top-left.
/// Children go back to coordinates relative to that origin.
void rebaseGroup(Group group, Node space) {
  if (group.children.isEmpty) {
    return;
  }
  final bounds = unionBounds([
    for (final child in group.children) boundsInSpace(child, space),
  ]);
  for (final child in group.children) {
    child
      ..x -= bounds.left
      ..y -= bounds.top;
  }
  group
    ..x += bounds.left
    ..y += bounds.top;
}

String newNodeId() {
  return 'n${DateTime.now().microsecondsSinceEpoch}'
      '${math.Random().nextInt(1 << 20)}';
}
