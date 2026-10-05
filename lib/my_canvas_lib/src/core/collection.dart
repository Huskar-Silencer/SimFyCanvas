import 'node.dart';

/// Parent node that owns an ordered list of children.
abstract class Collection extends Node {
  Collection({
    super.id,
    super.name,
    super.x,
    super.y,
    super.scaleX,
    super.scaleY,
    super.rotation,
    super.offsetX,
    super.offsetY,
    super.opacity,
    super.visible,
    super.listening,
    super.draggable,
    super.zIndex,
  });

  final List<Node> children = <Node>[];
  int _nextOrder = 0;

  int get childCount => children.length;

  void add(Node node) {
    node.parent?.removeChild(node);
    node.parent = this;
    node.order = _nextOrder++;
    children.add(node);
    sortChildren();
    node.markLocalDirty();
    markContentDirty();
  }

  void addAll(Iterable<Node> nodes) {
    for (final node in nodes) {
      add(node);
    }
  }

  void removeChild(Node node) {
    if (children.remove(node)) {
      node.parent = null;
      markContentDirty();
    }
  }

  void removeChildren() {
    for (final child in List<Node>.from(children)) {
      child.parent = null;
    }
    children.clear();
    markContentDirty();
  }

  void sortChildren() {
    children.sort((a, b) {
      final z = a.zIndex.compareTo(b.zIndex);
      if (z != 0) {
        return z;
      }
      return a.order.compareTo(b.order);
    });
  }

  void moveChildToTop(Node node) {
    if (!children.contains(node)) {
      return;
    }
    node.order = _nextOrder++;
    sortChildren();
    markContentDirty();
  }

  void moveChildToBottom(Node node) {
    if (!children.contains(node)) {
      return;
    }
    var minOrder = 0;
    for (final child in children) {
      if (child.order < minOrder) {
        minOrder = child.order;
      }
    }
    node.order = minOrder - 1;
    sortChildren();
    markContentDirty();
  }

  /// Moves [node] one step toward the front (later in paint order).
  /// Returns false if [node] is missing or already at the front.
  bool moveChildForward(Node node) {
    final index = children.indexOf(node);
    if (index < 0 || index >= children.length - 1) {
      return false;
    }
    final above = children[index + 1];
    final tmp = node.order;
    node.order = above.order;
    above.order = tmp;
    sortChildren();
    markContentDirty();
    return true;
  }

  /// Moves [node] one step toward the back (earlier in paint order).
  /// Returns false if [node] is missing or already at the back.
  bool moveChildBackward(Node node) {
    final index = children.indexOf(node);
    if (index <= 0) {
      return false;
    }
    final below = children[index - 1];
    final tmp = node.order;
    node.order = below.order;
    below.order = tmp;
    sortChildren();
    markContentDirty();
    return true;
  }

  List<Node> find(String selector) {
    final result = <Node>[];
    _collect(this, selector, result);
    return result;
  }

  Node? findOne(String selector) {
    final result = find(selector);
    return result.isEmpty ? null : result.first;
  }

  static void _collect(Node node, String selector, List<Node> out) {
    if (_matches(node, selector)) {
      out.add(node);
    }
    if (node is Collection) {
      for (final child in node.children) {
        _collect(child, selector, out);
      }
    }
  }

  static bool _matches(Node node, String selector) {
    if (selector.startsWith('#')) {
      return node.id == selector.substring(1);
    }
    if (selector.startsWith('.')) {
      final token = selector.substring(1);
      return node.name.split(RegExp(r'\s+')).contains(token);
    }
    return node.runtimeType.toString() == selector;
  }
}
