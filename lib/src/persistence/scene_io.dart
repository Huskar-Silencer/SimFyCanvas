import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';

import '../editor/editor_controller.dart';
import '../editor/geom.dart';

Future<void> saveSceneJson(EditorController editor) async {
  editor.endTextEdit();
  final saved = await _saveJson(
    editor.encodeDocument(),
    suggestedName: 'canvas.json',
  );
  if (saved) {
    editor.markSaved();
  }
}

Future<void> saveSelectionJson(EditorController editor) async {
  if (editor.selectedIds.isEmpty) {
    return;
  }
  await _saveJson(editor.encodeSelection(), suggestedName: 'selection.json');
}

Future<bool> _saveJson(
  Map<String, Object?> data, {
  required String suggestedName,
}) async {
  final location = await getSaveLocation(
    suggestedName: suggestedName,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'Canvas', extensions: ['json']),
    ],
  );
  if (location == null) {
    return false;
  }
  final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(data));
  final file = XFile.fromData(
    Uint8List.fromList(bytes),
    mimeType: 'application/json',
    name: suggestedName,
  );
  await file.saveTo(location.path);
  return true;
}

Future<void> openSceneJson(EditorController editor) async {
  const type = XTypeGroup(label: 'Canvas', extensions: ['json']);
  final file = await openFile(acceptedTypeGroups: [type]);
  if (file == null) {
    return;
  }
  editor.loadDocumentString(await file.readAsString(), markSaved: true);
}

Future<void> savePng(EditorController editor) async {
  await _savePng(await exportPng(editor), suggestedName: 'canvas.png');
}

Future<void> saveSelectionPng(EditorController editor) async {
  if (editor.selectedIds.isEmpty) {
    return;
  }
  await _savePng(
    await exportPng(editor, selectionOnly: true),
    suggestedName: 'selection.png',
  );
}

/// Renders the document (or only the selection) at 1:1 document scale.
Future<Uint8List> exportPng(
  EditorController editor, {
  double pixelRatio = 2,
  bool selectionOnly = false,
}) async {
  final stage = editor.stage;
  final document = editor.document;
  stage.updateWorld();
  final targets = selectionOnly ? editor.selectedNodes : editor.elements;
  final bounds = targets.isEmpty
      ? const Rect.fromLTWH(0, 0, 800, 600)
      : unionBounds([for (final node in targets) boundsInSpace(node, document)])
            .inflate(selectionOnly ? 24 : 48);
  final width = (bounds.width * pixelRatio).round().clamp(1, 4096);
  final height = (bounds.height * pixelRatio).round().clamp(1, 4096);

  final saved = (stage.x, stage.y, stage.scaleX, stage.scaleY);
  final hidden = [
    if (selectionOnly)
      for (final node in document.children)
        if (!targets.contains(node) && node.visible) node,
  ];
  for (final node in hidden) {
    node.visible = false;
  }
  stage
    ..x = -bounds.left
    ..y = -bounds.top
    ..scaleX = 1
    ..scaleY = 1;
  stage.updateWorld();
  try {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = paperColor,
    );
    canvas.scale(pixelRatio, pixelRatio);
    if (!selectionOnly) {
      editor.background.paint(canvas);
    }
    document.paint(canvas);
    final image = await recorder.endRecording().toImage(width, height);
    final data = await image.toByteData(format: ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    for (final node in hidden) {
      node.visible = true;
    }
    stage
      ..x = saved.$1
      ..y = saved.$2
      ..scaleX = saved.$3
      ..scaleY = saved.$4;
    stage.updateWorld();
  }
}

Future<void> _savePng(Uint8List bytes, {required String suggestedName}) async {
  final location = await getSaveLocation(
    suggestedName: suggestedName,
    acceptedTypeGroups: const [
      XTypeGroup(label: 'PNG', extensions: ['png']),
    ],
  );
  if (location == null) {
    return;
  }
  final file = XFile.fromData(
    bytes,
    mimeType: 'image/png',
    name: suggestedName,
  );
  await file.saveTo(location.path);
}
