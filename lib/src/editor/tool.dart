import 'package:flutter/services.dart';

enum ToolType {
  selection,
  hand,
  rectangle,
  ellipse,
  diamond,
  line,
  arrow,
  freedraw,
  text,
}

LogicalKeyboardKey toolShortcut(ToolType tool) {
  return switch (tool) {
    ToolType.selection => LogicalKeyboardKey.keyV,
    ToolType.hand => LogicalKeyboardKey.keyH,
    ToolType.rectangle => LogicalKeyboardKey.keyR,
    ToolType.ellipse => LogicalKeyboardKey.keyO,
    ToolType.diamond => LogicalKeyboardKey.keyD,
    ToolType.line => LogicalKeyboardKey.keyL,
    ToolType.arrow => LogicalKeyboardKey.keyA,
    ToolType.freedraw => LogicalKeyboardKey.keyP,
    ToolType.text => LogicalKeyboardKey.keyT,
  };
}
