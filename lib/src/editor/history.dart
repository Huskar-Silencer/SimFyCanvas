import 'dart:convert';

import 'package:sim_fy_canvas/my_canvas_lib/fy_fl_canvas.dart';

class DocumentHistory {
  DocumentHistory(this._layer) {
    _stack.add(_snapshot());
  }

  final Layer _layer;
  final List<String> _stack = <String>[];
  int _index = 0;

  bool get canUndo => _index > 0;

  bool get canRedo => _index < _stack.length - 1;

  String _snapshot() {
    return jsonEncode([
      for (final child in _layer.children) NodeCodec.encode(child),
    ]);
  }

  void commit() {
    final next = _snapshot();
    if (next == _stack[_index]) {
      return;
    }
    if (_index < _stack.length - 1) {
      _stack.removeRange(_index + 1, _stack.length);
    }
    _stack.add(next);
    _index = _stack.length - 1;
  }

  bool undo() => _restore(_index - 1);

  bool redo() => _restore(_index + 1);

  void replaceCurrent() {
    _stack
      ..clear()
      ..add(_snapshot());
    _index = 0;
  }

  bool _restore(int index) {
    if (index < 0 || index >= _stack.length) {
      return false;
    }
    _index = index;
    final decoded = jsonDecode(_stack[_index]) as List<dynamic>;
    _layer.removeChildren();
    for (final item in decoded) {
      if (item is Map) {
        _layer.add(NodeCodec.decode(item));
      }
    }
    return true;
  }
}
