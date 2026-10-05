part of 'editor_controller.dart';

/// Document encode/load, new scene, and unsaved-change tracking.
class SceneSession {
  SceneSession(this._editor);

  final EditorController _editor;
  late String _savedDocument;

  void initSavedBaseline() {
    _savedDocument = _snapshot();
  }

  bool get hasUnsavedChanges => _snapshot() != _savedDocument;

  Map<String, Object?> encodeDocument() {
    final stage = _editor._stage;
    return <String, Object?>{
      'version': 1,
      'x': stage.x,
      'y': stage.y,
      'scale': _editor.zoom,
      'children': [
        for (final child in _editor._document.children)
          NodeCodec.encode(child),
      ],
    };
  }

  Map<String, Object?> encodeSelection() {
    return <String, Object?>{
      'version': 1,
      'children': [
        for (final node in _editor.selectedNodes) NodeCodec.encode(node),
      ],
    };
  }

  /// Marks the current document as explicitly saved by the user.
  void markSaved() {
    _savedDocument = _snapshot();
    _editor._notify();
  }

  /// Clears the current scene and establishes a new, clean document.
  void newScene() {
    _editor._gestures.reset();
    _editor._textEditor.discard();
    _editor._document.removeChildren();
    _editor.selectedIds.clear();
    _editor.toolType = ToolType.selection;
    _editor._stage
      ..x = 0
      ..y = 0
      ..scaleX = 1
      ..scaleY = 1;
    _editor._history.replaceCurrent();
    _savedDocument = _snapshot();
    _editor._syncInteraction();
    _editor._notify();
  }

  void loadDocument(Map json, {bool markSaved = false}) {
    _editor._textEditor.discard();
    _editor._document.removeChildren();
    _editor.selectedIds.clear();
    final children = json['children'];
    if (children is List) {
      for (final child in children) {
        if (child is Map) {
          _editor._document.add(NodeCodec.decode(child));
        }
      }
    }
    if (json['x'] is num) {
      _editor._stage.x = (json['x'] as num).toDouble();
    }
    if (json['y'] is num) {
      _editor._stage.y = (json['y'] as num).toDouble();
    }
    if (json['scale'] is num) {
      final s = (json['scale'] as num).toDouble().clamp(0.1, 8.0);
      _editor._stage.scaleX = s;
      _editor._stage.scaleY = s;
    }
    _editor._history.replaceCurrent();
    if (markSaved) {
      _savedDocument = _snapshot();
    }
    _editor._syncInteraction();
    _editor._notify();
  }

  bool loadDocumentString(String source, {bool markSaved = false}) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        return false;
      }
      loadDocument(decoded, markSaved: markSaved);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _snapshot() => jsonEncode(encodeDocument());
}
