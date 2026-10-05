import 'package:flutter/material.dart';

import 'common.dart';

class ZoomControls extends StatelessWidget {
  const ZoomControls({super.key});

  @override
  Widget build(BuildContext context) {
    return EditorBuilder(
      builder: (context, editor) => Panel(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'zoom out',
              onPressed: editor.zoomOut,
              icon: const Icon(Icons.remove, size: 18),
            ),
            Text(
              '${(editor.zoom * 100).round()}%',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            IconButton(
              tooltip: 'zoom in',
              onPressed: editor.zoomIn,
              icon: const Icon(Icons.add, size: 18),
            ),
            IconButton(
              tooltip: 'reset to origin',
              onPressed: editor.resetView,
              icon: const Icon(Icons.filter_center_focus, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
