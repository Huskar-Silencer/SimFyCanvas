part of 'editor_controller.dart';

/// Clipboard, nudge, delete, and z-order for the current selection.
class SelectionCommands {
  SelectionCommands(this._editor);

  final EditorController _editor;

  List<Map<String, Object?>>? _clipboard;

  bool get canPaste => _clipboard != null && _clipboard!.isNotEmpty;

  void delete() {
    _editor.endTextEdit();
    if (_editor.selectedIds.isEmpty) {
      return;
    }
    for (final node in _editor.selectedNodes) {
      node.remove();
    }
    _editor.selectedIds.clear();
    _editor._history.commit();
    _editor._syncInteraction();
    _editor._notify();
  }

  void copy() {
    _clipboard = [
      for (final node in _editor.selectedNodes) NodeCodec.encode(node),
    ];
    _editor._notify();
  }

  void cut() {
    copy();
    delete();
  }

  /// Pastes at the pointer, or 12px down-right of the copied nodes.
  void paste() {
    final clip = _clipboard;
    if (clip == null || clip.isEmpty) {
      return;
    }
    var minX = double.infinity;
    var minY = double.infinity;
    for (final json in clip) {
      minX = math.min(minX, (json['x'] as num?)?.toDouble() ?? 0);
      minY = math.min(minY, (json['y'] as num?)?.toDouble() ?? 0);
    }
    final pointer = _editor.lastPointerView;
    final origin = pointer != null
        ? _editor._docFromView(pointer)
        : Offset(minX + 12, minY + 12);
    _editor.selectedIds.clear();
    for (final json in clip) {
      final node = NodeCodec.decode({...json, 'id': newNodeId()});
      node.x = origin.dx + node.x - minX;
      node.y = origin.dy + node.y - minY;
      _editor._document.add(node);
      _editor.selectedIds.add(node.id!);
    }
    _editor._history.commit();
    _editor._syncInteraction();
    _editor._notify();
  }

  void nudge(double dx, double dy) {
    final nodes = _editor.selectedNodes;
    if (nodes.isEmpty) {
      return;
    }
    for (final node in nodes) {
      node.x += dx;
      node.y += dy;
    }
    _editor._history.commit();
    _editor._syncInteraction();
    _editor._notify();
  }

  /// Selected nodes in document paint order (back → front).
  List<Node> _inPaintOrder() {
    return [
      for (final child in _editor._document.children)
        if (_editor.selectedIds.contains(child.id)) child,
    ];
  }

  bool _isContiguousPrefix() {
    final selected = _inPaintOrder();
    final kids = _editor._document.children;
    if (selected.isEmpty || selected.length > kids.length) {
      return false;
    }
    for (var i = 0; i < selected.length; i++) {
      if (kids[i] != selected[i]) {
        return false;
      }
    }
    return true;
  }

  bool _isContiguousSuffix() {
    final selected = _inPaintOrder();
    final kids = _editor._document.children;
    if (selected.isEmpty || selected.length > kids.length) {
      return false;
    }
    final start = kids.length - selected.length;
    for (var i = 0; i < selected.length; i++) {
      if (kids[start + i] != selected[i]) {
        return false;
      }
    }
    return true;
  }

  void bringToFront() {
    final nodes = _inPaintOrder();
    if (nodes.isEmpty || _isContiguousSuffix()) {
      return;
    }
    // Back-most first so relative order inside the selection is kept.
    for (final node in nodes) {
      node.moveToTop();
    }
    _editor._history.commit();
    _editor._notify();
  }

  void sendToBack() {
    final nodes = _inPaintOrder();
    if (nodes.isEmpty || _isContiguousPrefix()) {
      return;
    }
    // Front-most first so relative order inside the selection is kept.
    for (final node in nodes.reversed) {
      node.moveToBottom();
    }
    _editor._history.commit();
    _editor._notify();
  }

  void bringForward() {
    final nodes = _inPaintOrder();
    if (nodes.isEmpty) {
      return;
    }
    var changed = false;
    // Front-most first; skip swaps with other selected nodes.
    for (final node in nodes.reversed) {
      final kids = _editor._document.children;
      final index = kids.indexOf(node);
      if (index < 0 || index >= kids.length - 1) {
        continue;
      }
      if (_editor.selectedIds.contains(kids[index + 1].id)) {
        continue;
      }
      if (node.moveForward()) {
        changed = true;
      }
    }
    if (!changed) {
      return;
    }
    _editor._history.commit();
    _editor._notify();
  }

  void sendBackward() {
    final nodes = _inPaintOrder();
    if (nodes.isEmpty) {
      return;
    }
    var changed = false;
    // Back-most first; skip swaps with other selected nodes.
    for (final node in nodes) {
      final kids = _editor._document.children;
      final index = kids.indexOf(node);
      if (index <= 0) {
        continue;
      }
      if (_editor.selectedIds.contains(kids[index - 1].id)) {
        continue;
      }
      if (node.moveBackward()) {
        changed = true;
      }
    }
    if (!changed) {
      return;
    }
    _editor._history.commit();
    _editor._notify();
  }

  bool get canGroup => _inPaintOrder().length >= 2;

  bool get canUngroup =>
      _editor.selectedNodes.any((node) => node is Group);

  void group() {
    final nodes = _inPaintOrder();
    if (nodes.length < 2) {
      return;
    }
    _editor._stage.updateWorld();
    final bounds = unionBounds([
      for (final node in nodes) boundsInSpace(node, _editor._document),
    ]);
    final group = Group(
      id: newNodeId(),
      x: bounds.left,
      y: bounds.top,
    );
    for (final node in List<Node>.from(nodes)) {
      node
        ..x -= bounds.left
        ..y -= bounds.top;
      group.add(node);
    }
    _editor._document.add(group);
    _editor.selectedIds
      ..clear()
      ..add(group.id!);
    _editor._history.commit();
    _editor._syncInteraction();
    _editor._notify();
  }

  void ungroup() {
    final groups = [
      for (final node in _inPaintOrder())
        if (node is Group) node,
    ];
    if (groups.isEmpty) {
      return;
    }
    final released = <String>{};
    for (final group in groups) {
      for (final child in List<Node>.from(group.children)) {
        child
          ..x += group.x
          ..y += group.y;
        _editor._document.add(child);
        if (child.id case final id?) {
          released.add(id);
        }
      }
      group.remove();
    }
    _editor.selectedIds
      ..clear()
      ..addAll(released);
    _editor._history.commit();
    _editor._syncInteraction();
    _editor._notify();
  }
}
