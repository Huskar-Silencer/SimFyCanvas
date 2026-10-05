import 'dart:math' as math;
import 'dart:ui';

import 'package:sim_fy_canvas/my_canvas_lib/fy_fl_canvas.dart';

import 'geom.dart';
import 'handles.dart';

/// Rotation step while Shift is held.
const lockAngle = math.pi / 12;

/// Per-node snapshot at pointer-down for multi-element transforms.
class NodeOrig {
  NodeOrig.of(this.node)
    : x = node.x,
      y = node.y,
      rotation = node.rotation,
      scaleX = node.scaleX,
      scaleY = node.scaleY,
      content = contentRect(node),
      points = switch (node) {
        LinearShape(:final points) ||
        FreehandShape(:final points) => List<Offset>.of(points),
        _ => null,
      },
      bend = node is LinearShape && node.isBent ? node.bend : null,
      fontSize = node is TextShape ? node.fontSize : null;

  final Node node;
  final double x;
  final double y;
  final double rotation;
  final double scaleX;
  final double scaleY;
  final Rect content;
  final List<Offset>? points;
  final Offset? bend;
  final double? fontSize;

  double get width => content.width;
  double get height => content.height;
  Offset get center => Offset(x, y) + content.center;
}

double rotationAngleToPointer(
  Offset center,
  Offset pointer, {
  bool snap = false,
}) {
  var angle =
      math.atan2(pointer.dy - center.dy, pointer.dx - center.dx) + math.pi / 2;
  if (snap) {
    angle = (angle / lockAngle).round() * lockAngle;
  }
  return angle;
}

/// [radians] as degrees in (-180, 180].
double rotationDegrees(double radians) {
  final deg = (radians * 180 / math.pi) % 360;
  return deg > 180 ? deg - 360 : deg;
}

/// Resizes [node] to the signed [width]/[height] so the point opposite the
/// dragged handle stays put in document space.
void applyBoxFromSnapshot(
  BoxShape node,
  BoxSnapshot orig,
  double width,
  double height,
  HandleKind kind,
) {
  width = width < 0 ? math.min(width, -1) : math.max(width, 1);
  height = height < 0 ? math.min(height, -1) : math.max(height, 1);
  final anchor = _resizeAnchor(orig, kind);
  final fx = orig.width == 0 ? 0.5 : (anchor.dx - orig.x) / orig.width;
  final fy = orig.height == 0 ? 0.5 : (anchor.dy - orig.y) / orig.height;
  final anchorDoc = rotateAround(anchor, orig.center, orig.rotation);
  final fromCenter = rotateAround(
    Offset((fx - 0.5) * width, (fy - 0.5) * height),
    Offset.zero,
    orig.rotation,
  );
  final center = anchorDoc - fromCenter;
  node
    ..width = width.abs()
    ..height = height.abs()
    ..x = center.dx - width.abs() / 2
    ..y = center.dy - height.abs() / 2;
}

/// Auto-resize text: uniform scale of fontSize, then remeasure.
void applyTextResizeFromPointer({
  required TextShape node,
  required BoxSnapshot orig,
  required double origFontSize,
  required HandleKind kind,
  required Offset pointer,
}) {
  final next = nextBoxSizeFromPointer(
    orig: orig,
    kind: kind,
    pointer: pointer,
    keepAspect: true,
  );
  final sx = orig.width.abs() < 1e-9
      ? 1.0
      : next.width.abs() / orig.width.abs();
  final sy = orig.height.abs() < 1e-9
      ? 1.0
      : next.height.abs() / orig.height.abs();
  node.fontSize = math.max(origFontSize * math.max(sx, sy), 4);
  final size = measureCanvasText(node.text, node.fontSize);
  applyBoxFromSnapshot(node, orig, size.width, size.height, kind);
}

/// Signed next width/height from a pointer in document space.
({double width, double height}) nextBoxSizeFromPointer({
  required BoxSnapshot orig,
  required HandleKind kind,
  required Offset pointer,
  bool keepAspect = false,
}) {
  final rotated = rotateAround(pointer, orig.center, -orig.rotation);
  var nextWidth = orig.width;
  var nextHeight = orig.height;
  final name = kind.name;
  if (name.contains('e')) {
    nextWidth = rotated.dx - orig.x;
  }
  if (name.contains('s')) {
    nextHeight = rotated.dy - orig.y;
  }
  if (name.contains('w')) {
    nextWidth = orig.x + orig.width - rotated.dx;
  }
  if (name.contains('n')) {
    nextHeight = orig.y + orig.height - rotated.dy;
  }

  if (keepAspect && orig.width != 0 && orig.height != 0) {
    final widthRatio = nextWidth.abs() / orig.width.abs();
    final heightRatio = nextHeight.abs() / orig.height.abs();
    if (name.length == 1) {
      nextHeight *= widthRatio;
      nextWidth *= heightRatio;
    } else {
      final ratio = math.max(widthRatio, heightRatio);
      nextWidth = orig.width.abs() * ratio * nextWidth.sign;
      nextHeight = orig.height.abs() * ratio * nextHeight.sign;
    }
  }
  return (width: nextWidth, height: nextHeight);
}

/// Unrotated point that stays fixed while dragging [kind].
Offset _resizeAnchor(BoxSnapshot orig, HandleKind kind) {
  final minX = orig.x;
  final minY = orig.y;
  final maxX = orig.x + orig.width;
  final maxY = orig.y + orig.height;
  return switch (kind) {
    HandleKind.ne => Offset(minX, maxY),
    HandleKind.se => Offset(minX, minY),
    HandleKind.sw => Offset(maxX, minY),
    HandleKind.nw => Offset(maxX, maxY),
    HandleKind.e => Offset(minX, orig.center.dy),
    HandleKind.w => Offset(maxX, orig.center.dy),
    HandleKind.n => Offset(orig.center.dx, maxY),
    HandleKind.s => Offset(orig.center.dx, minY),
    HandleKind.rotate ||
    HandleKind.vertex ||
    HandleKind.midpoint => orig.center,
  };
}

/// Next multi-selection size from a pointer (groups always keep aspect).
({double width, double height, bool flipByX, bool flipByY})
_nextMultipleFromPointer({
  required BoxSnapshot orig,
  required HandleKind kind,
  required Offset pointer,
}) {
  final width = orig.width.abs() < 1e-9 ? 1.0 : orig.width.abs();
  final height = orig.height.abs() < 1e-9 ? 1.0 : orig.height.abs();
  final anchor = _resizeAnchor(orig, kind);
  final scale = math.max(
    (pointer.dx - anchor.dx).abs() / width,
    (pointer.dy - anchor.dy).abs() / height,
  );
  final flipByX = switch (kind) {
    HandleKind.ne || HandleKind.se || HandleKind.e => pointer.dx < anchor.dx,
    HandleKind.nw || HandleKind.sw || HandleKind.w => pointer.dx > anchor.dx,
    _ => false,
  };
  final flipByY = switch (kind) {
    HandleKind.se || HandleKind.sw || HandleKind.s => pointer.dy < anchor.dy,
    HandleKind.ne || HandleKind.nw || HandleKind.n => pointer.dy > anchor.dy,
    _ => false,
  };
  return (
    width: width * scale * (pointer.dx - anchor.dx).sign,
    height: height * scale * (pointer.dy - anchor.dy).sign,
    flipByX: flipByX,
    flipByY: flipByY,
  );
}

/// Resize multiple elements from original snapshots and their common AABB.
void applyMultipleResize({
  required List<NodeOrig> origs,
  required BoxSnapshot origBounds,
  required HandleKind kind,
  required Offset pointer,
}) {
  final next = _nextMultipleFromPointer(
    orig: origBounds,
    kind: kind,
    pointer: pointer,
  );
  if (next.width.abs() < 1e-6 || next.height.abs() < 1e-6) {
    return;
  }
  final width = origBounds.width.abs() < 1e-9 ? 1.0 : origBounds.width.abs();
  final height = origBounds.height.abs() < 1e-9 ? 1.0 : origBounds.height.abs();
  final scale = math.max(next.width.abs() / width, next.height.abs() / height);
  final flipX = next.flipByX ? -1.0 : 1.0;
  final flipY = next.flipByY ? -1.0 : 1.0;
  final anchor = _resizeAnchor(origBounds, kind);
  Offset scaled(Offset p) => Offset(p.dx * scale * flipX, p.dy * scale * flipY);

  for (final orig in origs) {
    final target = orig.node;
    final nextW = orig.width * scale;
    final nextH = orig.height * scale;
    final isLinear = orig.points != null;
    final shiftX = next.flipByX && !isLinear ? nextW : 0.0;
    final shiftY = next.flipByY && !isLinear ? nextH : 0.0;
    target.x = anchor.dx + flipX * ((orig.x - anchor.dx) * scale + shiftX);
    target.y = anchor.dy + flipY * ((orig.y - anchor.dy) * scale + shiftY);
    target.rotation = orig.rotation * flipX * flipY;
    if (target is BoxShape) {
      target.width = math.max(nextW.abs(), 1);
      target.height = math.max(nextH.abs(), 1);
    }
    if (orig.fontSize != null && target is TextShape) {
      target.fontSize = math.max(orig.fontSize! * scale, 4);
    }
    final points = orig.points;
    if (target is LinearShape && points != null) {
      target.setPoints(points.map(scaled).toList());
      if (orig.bend != null) {
        target.setBend(scaled(orig.bend!));
      }
    } else if (target is FreehandShape && points != null) {
      target.setPoints(points.map(scaled).toList());
    } else if (target is! BoxShape) {
      target.scaleX = orig.scaleX * scale * flipX;
      target.scaleY = orig.scaleY * scale * flipY;
    }
  }
}

/// Rotate multiple elements: each orig center orbits the common bounds
/// center; angle is `centerAngle + orig.angle`.
void applyMultipleRotate({
  required List<NodeOrig> origs,
  required Offset groupCenter,
  required Offset pointer,
  bool snap = false,
}) {
  final centerAngle = rotationAngleToPointer(groupCenter, pointer, snap: snap);
  for (final orig in origs) {
    final rotated = rotateAround(orig.center, groupCenter, centerAngle);
    orig.node.rotation = centerAngle + orig.rotation;
    orig.node.x = orig.x + (rotated.dx - orig.center.dx);
    orig.node.y = orig.y + (rotated.dy - orig.center.dy);
  }
}
