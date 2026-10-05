import 'package:flutter/material.dart';

import '../editor/editor_controller.dart';
import 'canvas_viewport.dart';
import 'file_menu.dart';
import 'style_bar.dart';
import 'toolbar.dart';
import 'zoom_controls.dart';

class EditorShell extends StatelessWidget {
  const EditorShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: paperColor,
      body: Stack(
        children: [
          Positioned.fill(child: CanvasViewport()),
          Positioned(top: 16, left: 16, child: FileMenuButton()),
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(child: EditorToolbar()),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: SizedBox(width: 220, child: StyleBar()),
          ),
          Positioned(right: 16, bottom: 16, child: ZoomControls()),
        ],
      ),
    );
  }
}
