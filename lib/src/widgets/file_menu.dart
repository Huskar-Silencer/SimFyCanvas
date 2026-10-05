import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/scene_io.dart';
import '../state/providers.dart';
import 'common.dart';

enum _FileAction { newScene, open, save, exportPng }

class FileMenuButton extends ConsumerWidget {
  const FileMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.read(editorProvider);
    return Panel(
      child: PopupMenuButton<_FileAction>(
        tooltip: 'file',
        icon: const Icon(Icons.menu, size: 20),
        onSelected: (action) async {
          switch (action) {
            case _FileAction.newScene:
              if (await _confirmNewScene(context, editor.hasUnsavedChanges)) {
                editor.newScene();
              }
            case _FileAction.open:
              await openSceneJson(editor);
            case _FileAction.save:
              await saveSceneJson(editor);
            case _FileAction.exportPng:
              await savePng(editor);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: _FileAction.newScene, child: Text('New Scene')),
          PopupMenuDivider(),
          PopupMenuItem(
            value: _FileAction.open,
            child: Text('Open Scene(.json)'),
          ),
          PopupMenuItem(
            value: _FileAction.save,
            child: Text('Save Scene(.json)'),
          ),
          PopupMenuItem(
            value: _FileAction.exportPng,
            child: Text('Export to PNG'),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirmNewScene(
  BuildContext context,
  bool hasUnsavedChanges,
) async {
  if (!hasUnsavedChanges) {
    return true;
  }
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved changes'),
          content: const Text(
            'The current scene has not been saved as JSON. '
            'Creating a new scene will discard these changes.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('New Scene'),
            ),
          ],
        ),
      ) ??
      false;
}
