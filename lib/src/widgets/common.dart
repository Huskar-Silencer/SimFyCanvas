import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../editor/editor_controller.dart';
import '../state/providers.dart';

abstract final class AppColors {
  static const accent = Color(0xFF2563EB);
  static const accentSoft = Color(0xFFEFF6FF);
  static const icon = Color(0xFF4B5563);
  static const divider = Color(0xFFE5E7EB);
  static const label = Color(0xFF6B7280);
}

/// Rebuilds [builder] every time the editor notifies.
class EditorBuilder extends ConsumerWidget {
  const EditorBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, EditorController editor) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    return ListenableBuilder(
      listenable: editor,
      builder: (context, _) => builder(context, editor),
    );
  }
}

/// Floating white card used by every toolbar and control around the canvas.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: padding, child: child),
    );
  }
}

class ToggleIconButton extends StatelessWidget {
  const ToggleIconButton({
    super.key,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: selected ? AppColors.accentSoft : null,
        foregroundColor: selected ? AppColors.accent : AppColors.icon,
      ),
      icon: icon,
    );
  }
}
