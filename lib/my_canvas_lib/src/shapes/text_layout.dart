import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Single source of truth for how [TextShape] text is laid out, shared by
/// painting, measuring and the edit overlay.
const canvasTextFont = 'Segoe UI';
const canvasTextHeight = 1.25;

TextStyle canvasTextStyle(double fontSize, {Color? color}) {
  return TextStyle(
    fontSize: fontSize,
    fontFamily: canvasTextFont,
    height: canvasTextHeight,
    color: color,
  );
}

TextPainter layoutCanvasText(String text, double fontSize, {Color? color}) {
  return TextPainter(
    text: TextSpan(
      text: text,
      style: canvasTextStyle(fontSize, color: color),
    ),
    textDirection: TextDirection.ltr,
    textScaler: TextScaler.noScaling,
    textWidthBasis: TextWidthBasis.longestLine,
  )..layout();
}

/// Box that fits [text] on one unwrapped line per paragraph.
Size measureCanvasText(String text, double fontSize) {
  final painter = layoutCanvasText(text.isEmpty ? ' ' : text, fontSize);
  return Size(
    math.max(1, painter.width + 8),
    math.max(fontSize * canvasTextHeight, painter.height),
  );
}
