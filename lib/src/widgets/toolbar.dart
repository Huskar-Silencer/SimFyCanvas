import 'package:flutter/material.dart';

import '../editor/tool.dart';
import 'common.dart';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return EditorBuilder(
      builder: (context, editor) => Panel(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final tool in ToolType.values)
              ToggleIconButton(
                tooltip: tool.name,
                selected: editor.toolType == tool,
                onPressed: () => editor.setToolType(tool),
                icon: _toolIcon(tool),
              ),
            const SizedBox(width: 8),
            Container(width: 1, height: 24, color: AppColors.divider),
            IconButton(
              tooltip: 'undo',
              onPressed: editor.canUndo ? editor.undo : null,
              icon: const Icon(Icons.undo_rounded, size: 20),
            ),
            IconButton(
              tooltip: 'redo',
              onPressed: editor.canRedo ? editor.redo : null,
              icon: const Icon(Icons.redo_rounded, size: 20),
            ),
            IconButton(
              tooltip: 'reset to origin',
              onPressed: editor.resetView,
              icon: const Icon(Icons.filter_center_focus, size: 20),
            ),
            ToggleIconButton(
              tooltip: 'snap to objects',
              selected: editor.snapEnabled,
              onPressed: editor.toggleSnap,
              icon: const Icon(Icons.align_horizontal_center, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _toolIcon(ToolType tool) {
  final icon = switch (tool) {
    ToolType.selection => Icons.near_me_outlined,
    ToolType.hand => Icons.pan_tool_alt_outlined,
    ToolType.rectangle => Icons.rectangle_outlined,
    ToolType.ellipse => Icons.circle_outlined,
    ToolType.diamond => null,
    ToolType.line => Icons.remove,
    ToolType.arrow => Icons.arrow_right_alt,
    ToolType.freedraw => Icons.gesture,
    ToolType.text => Icons.title,
  };
  return icon == null ? const RhombusIcon(size: 18) : Icon(icon, size: 20);
}

/// Material has no outlined rhombus, only gem-shaped diamonds.
class RhombusIcon extends StatelessWidget {
  const RhombusIcon({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? AppColors.icon;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RhombusPainter(color)),
    );
  }
}

class _RhombusPainter extends CustomPainter {
  _RhombusPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = size.shortestSide * 0.12;
    final path = Path()
      ..moveTo(size.width / 2, inset)
      ..lineTo(size.width - inset, size.height / 2)
      ..lineTo(size.width / 2, size.height - inset)
      ..lineTo(inset, size.height / 2)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(_RhombusPainter oldDelegate) => oldDelegate.color != color;
}
