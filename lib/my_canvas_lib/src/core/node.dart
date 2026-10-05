import 'dart:ui';

import '../math/matrix2d.dart';
import 'collection.dart';
import 'layer.dart';
import 'node_event.dart';
import 'stage.dart';

/// Scene-graph node: hierarchy, transform, visibility, and events.
abstract class Node {
  Node({
    this.id,
    this.name = '',
    this._x = 0,
    this._y = 0,
    this._scaleX = 1,
    this._scaleY = 1,
    this._rotation = 0,
    this._offsetX = 0,
    this._offsetY = 0,
    this._opacity = 1,
    this._visible = true,
    this.listening = true,
    this.draggable = false,
    this._zIndex = 0,
  });

  String? id;
  String name;
  Collection? parent;

  double _x;
  double _y;
  double _scaleX;
  double _scaleY;
  double _rotation;
  double _offsetX;
  double _offsetY;
  double _opacity;
  bool _visible;
  bool listening;
  bool draggable;
  int _zIndex;
  int order = 0;

  final Matrix2D localMatrix = Matrix2D.identity();
  final Matrix2D worldMatrix = Matrix2D.identity();
  bool localDirty = true;
  bool worldDirty = true;

  double worldOpacity = 1;

  final Map<String, List<NodeEventListener>> _listeners =
      <String, List<NodeEventListener>>{};

  double get x => _x;
  set x(double value) {
    if (_x == value) {
      return;
    }
    _x = value;
    markLocalDirty();
  }

  double get y => _y;
  set y(double value) {
    if (_y == value) {
      return;
    }
    _y = value;
    markLocalDirty();
  }

  Offset get position => Offset(_x, _y);
  set position(Offset value) {
    if (_x == value.dx && _y == value.dy) {
      return;
    }
    _x = value.dx;
    _y = value.dy;
    markLocalDirty();
  }

  double get scaleX => _scaleX;
  set scaleX(double value) {
    if (_scaleX == value) {
      return;
    }
    _scaleX = value;
    markLocalDirty();
  }

  double get scaleY => _scaleY;
  set scaleY(double value) {
    if (_scaleY == value) {
      return;
    }
    _scaleY = value;
    markLocalDirty();
  }

  /// Rotation in radians. Positive is clockwise on a y-down canvas.
  double get rotation => _rotation;
  set rotation(double value) {
    if (_rotation == value) {
      return;
    }
    _rotation = value;
    markLocalDirty();
  }

  double get rotationDeg => _rotation * 180 / 3.141592653589793;
  set rotationDeg(double value) {
    rotation = value * 3.141592653589793 / 180;
  }

  double get offsetX => _offsetX;
  set offsetX(double value) {
    if (_offsetX == value) {
      return;
    }
    _offsetX = value;
    markLocalDirty();
  }

  double get offsetY => _offsetY;
  set offsetY(double value) {
    if (_offsetY == value) {
      return;
    }
    _offsetY = value;
    markLocalDirty();
  }

  double get opacity => _opacity;
  set opacity(double value) {
    if (_opacity == value) {
      return;
    }
    _opacity = value;
    markContentDirty();
  }

  bool get visible => _visible;
  set visible(bool value) {
    if (_visible == value) {
      return;
    }
    _visible = value;
    markContentDirty();
  }

  int get zIndex => _zIndex;
  set zIndex(int value) {
    if (_zIndex == value) {
      return;
    }
    _zIndex = value;
    parent?.sortChildren();
    markContentDirty();
  }

  Stage? get stage {
    Node? node = this;
    while (node != null) {
      if (node is Stage) {
        return node;
      }
      node = node.parent;
    }
    return null;
  }

  Layer? get layer {
    Node? node = this;
    while (node != null) {
      if (node is Layer) {
        return node;
      }
      node = node.parent;
    }
    return null;
  }

  void markLocalDirty() {
    localDirty = true;
    markWorldDirty();
    if (this is Stage || this is Layer) {
      stage?.requestPaint();
      return;
    }
    layer?.markPictureDirty();
    stage?.requestPaint();
  }

  void markWorldDirty() {
    worldDirty = true;
    final self = this;
    if (self is Collection) {
      for (final child in self.children) {
        child.markWorldDirty();
      }
    }
  }

  void markContentDirty() {
    if (this is Stage) {
      stage?.requestPaint();
      return;
    }
    if (this is Layer) {
      (this as Layer).markPictureDirty();
      stage?.requestPaint();
      return;
    }
    layer?.markPictureDirty();
    stage?.requestPaint();
  }

  bool get rotateAroundCenter => false;

  void updateLocalMatrix() {
    localMatrix.setIdentity();
    if (rotateAroundCenter) {
      final pivot = localBounds.center;
      localMatrix.translate(_x + pivot.dx, _y + pivot.dy);
      localMatrix.rotate(_rotation);
      localMatrix.scale(_scaleX, _scaleY);
      localMatrix.translate(-pivot.dx - _offsetX, -pivot.dy - _offsetY);
    } else {
      localMatrix.translate(_x, _y);
      localMatrix.rotate(_rotation);
      localMatrix.scale(_scaleX, _scaleY);
      localMatrix.translate(-_offsetX, -_offsetY);
    }
    localDirty = false;
  }

  void updateTransform(
    Matrix2D? parentWorld, {
    bool parentWorldChanged = false,
  }) {
    if (localDirty) {
      updateLocalMatrix();
      worldDirty = true;
    }
    var worldChanged = parentWorldChanged || worldDirty;
    if (worldChanged) {
      if (parentWorld == null) {
        worldMatrix.copyFrom(localMatrix);
      } else {
        worldMatrix.copyFrom(parentWorld);
        worldMatrix.multiply(localMatrix);
      }
      worldDirty = false;
    }
    final ancestor = parent;
    final parentOpacity = ancestor == null ? 1.0 : ancestor.worldOpacity;
    worldOpacity = parentOpacity * _opacity;
    final self = this;
    if (self is Collection) {
      for (final child in self.children) {
        child.updateTransform(worldMatrix, parentWorldChanged: worldChanged);
      }
    }
  }

  Offset worldToLocal(Offset world) => worldMatrix.inverseTransformPoint(world);

  Offset localToWorld(Offset local) => worldMatrix.transformPoint(local);

  Rect get localBounds => Rect.zero;

  Rect getClientRect() {
    final bounds = localBounds;
    final p1 = localToWorld(bounds.topLeft);
    final p2 = localToWorld(bounds.topRight);
    final p3 = localToWorld(bounds.bottomLeft);
    final p4 = localToWorld(bounds.bottomRight);
    final xs = <double>[p1.dx, p2.dx, p3.dx, p4.dx];
    final ys = <double>[p1.dy, p2.dy, p3.dy, p4.dy];
    final left = xs.reduce((a, b) => a < b ? a : b);
    final top = ys.reduce((a, b) => a < b ? a : b);
    final right = xs.reduce((a, b) => a > b ? a : b);
    final bottom = ys.reduce((a, b) => a > b ? a : b);
    return Rect.fromLTRB(left, top, right, bottom);
  }

  bool hitTestLocal(Offset local) => false;

  /// Draw this node in [layer]-relative space. Collections skip drawing.
  void paintOn(Canvas canvas, Matrix2D inverseLayer) {}

  /// Returns the top-most listening node under [stagePoint], or null.
  Node? hitTest(Offset stagePoint) {
    if (!_visible || !listening) {
      return null;
    }
    final self = this;
    if (self is Collection) {
      for (var i = self.children.length - 1; i >= 0; i--) {
        final hit = self.children[i].hitTest(stagePoint);
        if (hit != null) {
          return hit;
        }
      }
    }
    final local = worldToLocal(stagePoint);
    if (hitTestLocal(local)) {
      return this;
    }
    return null;
  }

  void on(String type, NodeEventListener listener) {
    _listeners.putIfAbsent(type, () => <NodeEventListener>[]).add(listener);
  }

  void off(String type, [NodeEventListener? listener]) {
    if (listener == null) {
      _listeners.remove(type);
      return;
    }
    _listeners[type]?.remove(listener);
  }

  void emit(NodeEvent event) {
    final list = _listeners[event.type];
    if (list == null) {
      return;
    }
    for (final listener in List<NodeEventListener>.from(list)) {
      listener(event);
    }
  }

  void remove() {
    parent?.removeChild(this);
  }

  void moveToTop() {
    parent?.moveChildToTop(this);
  }

  void moveToBottom() {
    parent?.moveChildToBottom(this);
  }

  bool moveForward() => parent?.moveChildForward(this) ?? false;

  bool moveBackward() => parent?.moveChildBackward(this) ?? false;

  void destroy() {
    remove();
    _listeners.clear();
  }
}
