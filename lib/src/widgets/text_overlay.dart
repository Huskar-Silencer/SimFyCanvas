import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sim_fy_canvas/my_canvas_lib/fy_fl_canvas.dart';

import '../state/providers.dart';

/// The one persistent [TextField] used to edit a [TextShape]. It is laid
/// over the node in view space; the node itself skips painting meanwhile.
class TextEditorOverlay extends ConsumerWidget {
  const TextEditorOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorProvider);
    final session = editor.textEditor;
    return ListenableBuilder(
      listenable: Listenable.merge([editor, session.controller]),
      builder: (context, _) {
        final node = session.node;
        final zoom = editor.zoom;
        final color = node?.fill ?? node?.stroke ?? const Color(0xFF111827);
        editor.stage.updateWorld();
        final origin = node == null
            ? Offset.zero
            : editor.viewFromDoc(Offset(node.x, node.y));
        return Stack(
          children: [
            Positioned(
              left: origin.dx,
              top: origin.dy,
              width: node == null ? 2 : (node.width + 4) * zoom,
              height: node == null ? 2 : (node.height + 2) * zoom,
              child: MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.noScaling),
                child: TextField(
                  controller: session.controller,
                  focusNode: session.focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  cursorColor: color,
                  style: canvasTextStyle(
                    (node?.fontSize ?? 18) * zoom,
                    color: color,
                  ),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onTapOutside: (_) {},
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
