import 'package:flutter/material.dart';

import 'common.dart';

class StyleBar extends StatelessWidget {
  const StyleBar({super.key});

  static const _strokes = <Color>[
    Color(0xFF1F2937),
    Color(0xFF2563EB),
    Color(0xFFDC2626),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF7C3AED),
  ];

  static const _fills = <Color>[
    Color(0x00000000),
    // Soft fills
    Color(0x6693C5FD),
    Color(0x66FCA5A5),
    Color(0x66A7F3D0),
    Color(0x66FDE68A),
    Color(0x66DDD6FE),
    // Solid fills
    Color(0xFF93C5FD),
    Color(0xFFFCA5A5),
    Color(0xFFA7F3D0),
    Color(0xFFFDE68A),
    Color(0xFFDDD6FE),
  ];

  @override
  Widget build(BuildContext context) {
    return EditorBuilder(
      builder: (context, editor) {
        final brush = editor.brush;
        return Panel(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label('Stroke'),
              Wrap(
                spacing: 8,
                children: [
                  for (final color in _strokes)
                    _Swatch(
                      color: color,
                      selected: brush.stroke == color,
                      onTap: () => editor.updateBrush(stroke: color),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const _Label('Fill'),
              Wrap(
                spacing: 8,
                children: [
                  for (final color in _fills)
                    _Swatch(
                      color: color,
                      selected: brush.fill == color,
                      onTap: () => editor.updateBrush(fill: color),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _Label('Width ${brush.strokeWidth.toStringAsFixed(0)}'),
              Slider(
                value: brush.strokeWidth.clamp(1, 12),
                min: 1,
                max: 12,
                onChanged: (value) => editor.updateBrush(strokeWidth: value),
              ),
              _Label('Opacity ${(brush.opacity * 100).round()}%'),
              Slider(
                value: brush.opacity,
                min: 0.1,
                max: 1,
                onChanged: (value) => editor.updateBrush(opacity: value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.label,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final transparent = color.a == 0;
    final soft = !transparent && color.a < 1;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: transparent ? Colors.white : color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.accent : const Color(0xFFD1D5DB),
            width: selected ? 2 : 1,
          ),
        ),
        child: transparent
            ? const Icon(Icons.block, size: 14, color: Color(0xFF9CA3AF))
            : soft
            ? Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 1),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(11),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
