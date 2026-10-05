import 'dart:ui';

import 'package:sim_fy_canvas/my_canvas_lib/fy_fl_canvas.dart';

import 'handles.dart';

// Shapes drawn only on the interaction layer, above the document: handles,
// marquee, selection frame and snap guides. They are never saved.

/// Resize / rotate / vertex handle. Sized in screen pixels so zoom does not
/// change how large it looks.
class HandleShape extends Shape {
  HandleShape({
    required this.kind,
    this.vertexIndex,
    super.id,
    super.x,
    super.y,
    super.offsetX,
    super.offsetY,
    required double zoom,
  }) : _unit = 1 / zoom.clamp(0.05, double.infinity),
       super(
         listening: false,
         fill: const Color(0xFFFFFFFF),
         stroke: const Color(0xFF2563EB),
         strokeWidth: 1.5 / zoom.clamp(0.05, double.infinity),
       );

  final HandleKind kind;
  final int? vertexIndex;

  /// One screen pixel in document space.
  final double _unit;

  double get size => 8 * _unit;

  @override
  Rect get localBounds =>
      Rect.fromCenter(center: Offset.zero, width: size, height: size);

  @override
  bool hitTestLocal(Offset local) {
    return Rect.fromCenter(
      center: Offset.zero,
      width: size * 2,
      height: size * 2,
    ).contains(local);
  }

  @override
  void drawLocal(Canvas canvas) {
    if (kind == HandleKind.rotate) {
      canvas.drawCircle(Offset.zero, size / 2, fillPaint());
      canvas.drawCircle(Offset.zero, size / 2, strokePaint());
      return;
    }
    if (kind == HandleKind.midpoint) {
      final r = size * 0.4;
      canvas.drawCircle(Offset.zero, r, fillPaint());
      canvas.drawCircle(Offset.zero, r, strokePaint());
      return;
    }
    final rrect = RRect.fromRectAndRadius(
      localBounds,
      Radius.circular(1.5 * _unit),
    );
    canvas.drawRRect(rrect, fillPaint());
    canvas.drawRRect(rrect, strokePaint());
  }
}

class MarqueeShape extends Shape {
  MarqueeShape({super.x, super.y, double width = 0, double height = 0})
    : _width = width,
      _height = height,
      super(
        listening: false,
        fill: const Color(0x332563EB),
        stroke: const Color(0xFF2563EB),
        strokeWidth: 1,
      );

  double _width;
  double _height;

  double get width => _width;
  set width(double value) {
    if (_width == value) {
      return;
    }
    _width = value;
    markContentDirty();
  }

  double get height => _height;
  set height(double value) {
    if (_height == value) {
      return;
    }
    _height = value;
    markContentDirty();
  }

  @override
  Rect get localBounds => Rect.fromLTWH(0, 0, _width, _height);

  @override
  bool hitTestLocal(Offset local) => false;

  @override
  void drawLocal(Canvas canvas) {
    canvas.drawRect(localBounds, fillPaint());
    canvas.drawRect(localBounds, strokePaint()..strokeWidth = 1);
  }
}

/// Selection outline. Stroke width is screen-constant so zoom leaves it alone.
class SelectionFrame extends Shape {
  SelectionFrame({
    super.x,
    super.y,
    super.rotation,
    double width = 0,
    double height = 0,
    bool aroundCenter = false,
    required double zoom,
  }) : _width = width,
       _height = height,
       _aroundCenter = aroundCenter,
       super(
         listening: false,
         stroke: const Color(0xFF2563EB),
         strokeWidth: 1 / zoom.clamp(0.05, double.infinity),
       );

  double _width;
  double _height;
  final bool _aroundCenter;

  @override
  bool get rotateAroundCenter => _aroundCenter;

  void setBox(double width, double height) {
    _width = width;
    _height = height;
    markContentDirty();
  }

  @override
  Rect get localBounds => Rect.fromLTWH(0, 0, _width, _height);

  @override
  bool hitTestLocal(Offset local) => false;

  @override
  void drawLocal(Canvas canvas) {
    canvas.drawRect(localBounds, strokePaint());
  }
}

/// Alignment segments with a small cross on every end point.
class SnapGuideShape extends Shape {
  SnapGuideShape({required this.segments, required double zoom})
    : _unit = 1 / zoom,
      super(
        listening: false,
        stroke: const Color(0xFFEC4899),
        strokeWidth: 1 / zoom,
      );

  final List<(Offset, Offset)> segments;
  final double _unit;

  @override
  Rect get localBounds => segments.fold(
    Rect.zero,
    (acc, s) => acc.expandToInclude(Rect.fromPoints(s.$1, s.$2)),
  );

  @override
  bool hitTestLocal(Offset local) => false;

  @override
  void drawLocal(Canvas canvas) {
    final paint = strokePaint();
    final r = 3 * _unit;
    void cross(Offset p) {
      canvas.drawLine(p + Offset(-r, -r), p + Offset(r, r), paint);
      canvas.drawLine(p + Offset(-r, r), p + Offset(r, -r), paint);
    }

    for (final (a, b) in segments) {
      canvas.drawLine(a, b, paint);
      cross(a);
      cross(b);
    }
  }
}
