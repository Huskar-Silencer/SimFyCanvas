import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../editor/editor_controller.dart';
import '../persistence/draft_autosave.dart';
import '../persistence/draft_store.dart';

final editorProvider = Provider<EditorController>((ref) {
  final editor = EditorController();
  ref.onDispose(editor.dispose);
  return editor;
});

final draftStoreProvider = Provider<DraftStore>((ref) => FileDraftStore());

final draftAutosaveProvider = Provider<DraftAutosave>((ref) {
  final autosave = DraftAutosave(
    ref.watch(editorProvider),
    ref.watch(draftStoreProvider),
  );
  ref.onDispose(autosave.dispose);
  return autosave;
});
