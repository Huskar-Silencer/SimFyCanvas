import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sim_fy_canvas/my_canvas_lib/fy_fl_canvas.dart';

import '../editor/tool.dart';
import 'common.dart';
import 'context_menu.dart';
import 'editor_shortcuts.dart';
import 'text_overlay.dart';

/// The drawing surface: hosts the stage, the text edit overlay and the
/// rotation hint, and routes wheel / hover / right-click to the editor.
/// Primary-button drags go straight to the stage via [StageView].
class CanvasViewport extends StatelessWidget {
  const CanvasViewport({super.key});

  @override
  Widget build(BuildContext context) {
    return EditorBuilder(
      builder: (context, editor) => EditorShortcuts(
        editor: editor,
        child: Focus(
          autofocus: true,
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                editor.zoomAt(event.localPosition, event.scrollDelta.dy);
              }
            },
            onPointerHover: (event) {
              editor.lastPointerView = event.localPosition;
            },
            onPointerDown: (event) {
              if (event.buttons != kSecondaryMouseButton) {
                return;
              }
              editor.prepareContextMenu(event.localPosition);
              showEditorContextMenu(
                context: context,
                globalPosition: event.position,
                editor: editor,
              );
            },
            child: MouseRegion(
              cursor: editor.toolType == ToolType.hand
                  ? SystemMouseCursors.grab
                  : SystemMouseCursors.basic,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  StageView(stage: editor.stage),
                  Positioned.fill(
                    child: Visibility(
                      visible: editor.textEditor.visible,
                      maintainState: true,
                      child: const TextEditorOverlay(),
                    ),
                  ),
                  if (editor.rotationHintDeg case final deg?)
                    if (editor.lastPointerView case final pointer?)
                      Positioned(
                        left: pointer.dx + 16,
                        top: pointer.dy + 16,
                        child: _RotationHint(degrees: deg),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RotationHint extends StatelessWidget {
  const _RotationHint({required this.degrees});

  final double degrees;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: const Color(0xE6111827),
        elevation: 6,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '${degrees.round()}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
