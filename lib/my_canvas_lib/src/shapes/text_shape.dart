import 'dart:ui';

import '../paint/shape_style.dart';
import 'box_shape.dart';

/// Wrapped text in a local box, origin at top-left.
class TextShape extends BoxShape {
  TextShape({
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
    String text = '',
    double fontSize = 18,
    super.width = 160,
    super.height = 40,
  }) : _text = text,
       _fontSize = fontSize;

  String _text;
  double _fontSize;
  bool _editing = false;

  bool get editing => _editing;
  set editing(bool value) {
    if (_editing == value) {
      return;
    }
    _editing = value;
    markContentDirty();
  }

  String get text => _text;
  set text(String value) {
    if (_text == value) {
      return;
    }
    _text = value;
    markContentDirty();
  }

  double get fontSize => _fontSize;
  set fontSize(double value) {
    if (_fontSize == value) {
      return;
    }
    _fontSize = value;
    markContentDirty();
  }

  @override
  ShapeStyle get shapeStyle => ShapeStyle(
    fill: fill,
    stroke: stroke,
    strokeWidth: strokeWidth,
    opacity: worldOpacity,
    fontSize: _fontSize,
  );

  @override
  bool get rotateAroundCenter => true;

  @override
  bool hitTestLocal(Offset local) => localBounds.contains(local);

  @override
  void drawLocal(Canvas canvas) {
    if (editing) {
      return;
    }
    stylePainter.paintText(canvas, _text, localBounds, shapeStyle);
  }
}
