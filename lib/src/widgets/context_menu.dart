import 'package:flutter/material.dart';

import '../editor/editor_controller.dart';
import '../persistence/scene_io.dart';

Future<void> showEditorContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required EditorController editor,
}) {
  final hasSelection = editor.selectedIds.isNotEmpty;

  PopupMenuItem<void> item(String label, bool enabled, VoidCallback onTap) {
    return PopupMenuItem(enabled: enabled, onTap: onTap, child: Text(label));
  }

  return showMenu<void>(
    context: context,
    position: RelativeRect.fromRect(
      globalPosition & Size.zero,
      Offset.zero & MediaQuery.sizeOf(context),
    ),
    items: [
      item('Copy', hasSelection, editor.copySelection),
      item('Cut', hasSelection, editor.cutSelection),
      item('Paste', editor.canPaste, editor.paste),
      item('Delete', hasSelection, editor.deleteSelection),
      item('Group', editor.canGroup, editor.groupSelection),
      item('Ungroup', editor.canUngroup, editor.ungroupSelection),
      const PopupMenuDivider(),
      item('Bring to front', hasSelection, editor.bringToFront),
      item('Bring forward', hasSelection, editor.bringForward),
      item('Send backward', hasSelection, editor.sendBackward),
      item('Send to back', hasSelection, editor.sendToBack),
      const PopupMenuDivider(),
      item('Export selection as PNG', hasSelection, () {
        saveSelectionPng(editor);
      }),
      item('Export selection as JSON', hasSelection, () {
        saveSelectionJson(editor);
      }),
    ],
  );
}
