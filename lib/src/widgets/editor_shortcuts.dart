import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../editor/editor_controller.dart';
import '../editor/tool.dart';

/// Keyboard bindings for the canvas. While a text is being edited only
/// Escape is bound, so every other key reaches the text field.
class EditorShortcuts extends StatelessWidget {
  const EditorShortcuts({super.key, required this.editor, required this.child});

  final EditorController editor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: editor.isEditingText ? _editingBindings() : _canvasBindings(),
      child: child,
    );
  }

  Map<ShortcutActivator, VoidCallback> _editingBindings() {
    return {
      const SingleActivator(LogicalKeyboardKey.escape): editor.endTextEdit,
    };
  }

  Map<ShortcutActivator, VoidCallback> _canvasBindings() {
    return {
      const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
          editor.undo,
      const SingleActivator(LogicalKeyboardKey.keyY, control: true):
          editor.redo,
      const SingleActivator(LogicalKeyboardKey.keyC, control: true):
          editor.copySelection,
      const SingleActivator(LogicalKeyboardKey.keyX, control: true):
          editor.cutSelection,
      const SingleActivator(LogicalKeyboardKey.keyV, control: true):
          editor.paste,
      const SingleActivator(LogicalKeyboardKey.keyG, control: true):
          editor.groupSelection,
      const SingleActivator(
        LogicalKeyboardKey.keyG,
        control: true,
        shift: true,
      ): editor.ungroupSelection,
      const SingleActivator(LogicalKeyboardKey.delete): editor.deleteSelection,
      const SingleActivator(LogicalKeyboardKey.backspace):
          editor.deleteSelection,
      const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
          editor.nudge(0, -1),
      const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
          editor.nudge(0, 1),
      const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
          editor.nudge(-1, 0),
      const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
          editor.nudge(1, 0),
      const SingleActivator(LogicalKeyboardKey.bracketRight, control: true):
          editor.bringForward,
      const SingleActivator(
        LogicalKeyboardKey.bracketRight,
        control: true,
        shift: true,
      ): editor.bringToFront,
      const SingleActivator(LogicalKeyboardKey.bracketLeft, control: true):
          editor.sendBackward,
      const SingleActivator(
        LogicalKeyboardKey.bracketLeft,
        control: true,
        shift: true,
      ): editor.sendToBack,
      for (final tool in ToolType.values)
        SingleActivator(toolShortcut(tool)): () => editor.setToolType(tool),
    };
  }
}
