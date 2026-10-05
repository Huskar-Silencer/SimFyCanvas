import 'dart:async';
import 'dart:convert';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/widgets.dart';

import '../editor/editor_controller.dart';
import 'draft_store.dart';

/// Debounced recovery-draft persistence for one editor.
class DraftAutosave with WidgetsBindingObserver {
  DraftAutosave(
    this.editor,
    this.store, {
    this.delay = const Duration(milliseconds: 700),
  }) {
    editor.addListener(_schedule);
    editor.textEditor.controller.addListener(_schedule);
    WidgetsBinding.instance.addObserver(this);
  }

  final EditorController editor;
  final DraftStore store;
  final Duration delay;

  Timer? _timer;
  String? _lastSaved;
  String? _lastRequested;
  Future<void> _writes = Future.value();
  bool _restoring = false;

  Object? lastError;

  /// Restores the newest readable draft, falling back to its backup.
  Future<bool> restore() async {
    _restoring = true;
    try {
      for (final source in await store.readCandidates()) {
        if (!editor.loadDocumentString(source)) {
          continue;
        }
        _lastSaved = _encode();
        _lastRequested = _lastSaved;
        return true;
      }
      return false;
    } catch (error, stackTrace) {
      _report(error, stackTrace);
      return false;
    } finally {
      _restoring = false;
    }
  }

  /// Immediately queues the current document for persistence.
  Future<void> flush() {
    _timer?.cancel();
    final source = _encode();
    if (source == _lastRequested) {
      return _writes;
    }
    _lastRequested = source;
    _writes = _writes.then((_) async {
      try {
        await store.write(source);
        _lastSaved = source;
        lastError = null;
      } catch (error, stackTrace) {
        if (_lastRequested == source) {
          _lastRequested = _lastSaved;
        }
        _report(error, stackTrace);
      }
    });
    return _writes;
  }

  void _schedule() {
    if (_restoring) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(delay, flush);
  }

  String _encode() {
    final document = editor.encodeDocument();
    final textEditor = editor.textEditor;
    if (textEditor.isEditing && textEditor.controller.text.trim().isEmpty) {
      final editingId = textEditor.nodeId;
      final children = document['children'];
      if (children is List) {
        children.removeWhere(
          (child) => child is Map && child['id'] == editingId,
        );
      }
    }
    return jsonEncode(document);
  }

  void _report(Object error, StackTrace stackTrace) {
    lastError = error;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'draft autosave',
        context: ErrorDescription(
          'while reading or writing the recovery draft',
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(flush());
    }
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    await flush();
    return AppExitResponse.exit;
  }

  void dispose() {
    _timer?.cancel();
    editor.removeListener(_schedule);
    editor.textEditor.controller.removeListener(_schedule);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(flush());
  }
}
