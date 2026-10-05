part of 'editor_controller.dart';

enum _Gesture {
  none,
  pan,
  marquee,
  move,
  resize,
  rotate,
  create,
  freehand,
  vertex,
}

/// Snapshot of what a move / resize / rotate / vertex drag started from.
class _DragStart {
  _DragStart({this.handle, this.box, this.origs = const []});

  final HandleLayout? handle;

  /// The single box being edited, or the selection AABB for anything else.
  final BoxSnapshot? box;
  final List<NodeOrig> origs;
}

/// Pointer state machine: pan, marquee, move, create, freehand, handles.
class EditorGestures {
  EditorGestures(this._editor);

  final EditorController _editor;

  _Gesture _gesture = _Gesture.none;
  Offset _downView = Offset.zero;
  Offset _downDoc = Offset.zero;
  Node? _preview;
  _DragStart? _drag;
  bool _blockToolUntilUp = false;
  List<Offset> _snapTargets = const [];
  SnapGuides snapGuides = const SnapGuides();
  final List<Group> _liftedGroups = [];

  Node? get preview => _preview;

  void cancelPreview() {
    _preview?.remove();
    _preview = null;
  }

  /// Clears in-flight gesture state (e.g. new scene).
  void reset() {
    cancelPreview();
    _gesture = _Gesture.none;
    _drag = null;
    _snapTargets = const [];
    snapGuides = const SnapGuides();
    _blockToolUntilUp = false;
    _editor.rotationHintDeg = null;
    _liftedGroups.clear();
  }

  List<Offset> _collectSnapTargets() {
    if (!_editor.snapEnabled) {
      return const [];
    }
    _editor._stage.updateWorld();
    return [
      for (final node in _editor._document.children)
        if (!_editor.selectedIds.contains(node.id))
          ...snapPointsOf(boundsInSpace(node, _editor._document)),
    ];
  }

  Offset _snap(List<Offset> moving) {
    final result = _snapTargets.isEmpty
        ? SnapResult.none
        : snapPoints(
            moving,
            _snapTargets,
            threshold: snapDistancePx / _editor.zoom,
          );
    snapGuides = result.guides;
    return result.offset;
  }

  Offset _snapPoint(Offset doc) => doc + _snap([doc]);

  void onPointerDown(NodeEvent event) {
    if (event.currentTarget != _editor._stage) {
      return;
    }
    final view = event.stagePosition;
    _editor.lastPointerView = view;
    _downView = view;
    _downDoc = _editor._docFromView(view);
    _editor._stage.updateWorld();

    if (_blockToolUntilUp) {
      return;
    }
    if (_editor._textEditor.isEditing) {
      _editor.endTextEdit();
      _blockToolUntilUp = true;
      return;
    }

    if (_editor.toolType == ToolType.hand) {
      _gesture = _Gesture.pan;
      return;
    }

    if (_editor.toolType == ToolType.freedraw) {
      _gesture = _Gesture.freehand;
      final stroke = FreehandShape(
        id: newNodeId(),
        x: _downDoc.dx,
        y: _downDoc.dy,
        stroke: _editor.brush.stroke,
        fill: _editor.brush.stroke,
        strokeWidth: _editor.brush.strokeWidth,
        opacity: _editor.brush.opacity,
        points: const [Offset.zero],
      );
      _preview = stroke;
      _editor._interaction.add(stroke);
      _editor.selectedIds.clear();
      return;
    }

    if (_createDraft(_downDoc) case final draft?) {
      _gesture = _Gesture.create;
      _preview = draft;
      _editor.selectedIds.clear();
      _snapTargets = _collectSnapTargets();
      _downDoc = _snapPoint(_downDoc);
      _editor._syncInteraction();
      return;
    }

    if (_editor.toolType == ToolType.text) {
      final hit = _editor._documentHit(view);
      if (hit is TextShape) {
        _editor._openText(hit);
      } else {
        _editor._openTextAt(_downDoc);
      }
      _blockToolUntilUp = true;
      return;
    }

    final handle = hitHandle(_editor._handleLayouts(), _downDoc, _editor.zoom);
    if (handle != null) {
      _beginHandleGesture(handle);
      return;
    }

    final shift = _isShiftPressed();
    final id = _editor._documentHit(view)?.id;
    if (id != null) {
      if (shift) {
        if (!_editor.selectedIds.remove(id)) {
          _editor.selectedIds.add(id);
        }
      } else if (!_editor.selectedIds.contains(id)) {
        _editor.selectedIds
          ..clear()
          ..add(id);
      }
      _gesture = _Gesture.move;
      final aabb = _editor._selectionAabb();
      _drag = _DragStart(
        box: aabb == null ? null : BoxSnapshot.fromRect(aabb),
        origs: [for (final n in _editor.selectedNodes) NodeOrig.of(n)],
      );
      _snapTargets = _collectSnapTargets();
      _editor._syncInteraction();
      _editor._notify();
      return;
    }

    if (!shift) {
      _editor.selectedIds.clear();
    }
    _gesture = _Gesture.marquee;
    _preview = MarqueeShape(x: _downDoc.dx, y: _downDoc.dy);
    _editor._syncInteraction();
    _editor._notify();
  }

  void onPointerMove(NodeEvent event) {
    if (event.currentTarget != _editor._stage) {
      return;
    }
    final view = event.stagePosition;
    _editor.lastPointerView = view;
    final doc = _editor._docFromView(view);

    switch (_gesture) {
      case _Gesture.pan:
        _editor._stage.x += view.dx - _downView.dx;
        _editor._stage.y += view.dy - _downView.dy;
        _downView = view;
        _editor._stage.updateWorld();
        _editor._syncInteraction();
      case _Gesture.marquee:
        final box = _preview;
        if (box is MarqueeShape) {
          box.x = math.min(_downDoc.dx, doc.dx);
          box.y = math.min(_downDoc.dy, doc.dy);
          box.width = (doc.dx - _downDoc.dx).abs();
          box.height = (doc.dy - _downDoc.dy).abs();
        }
      case _Gesture.move:
        _updateMove(doc);
      case _Gesture.create:
        _updateCreate(doc);
      case _Gesture.freehand:
        final stroke = _preview;
        if (stroke is FreehandShape) {
          stroke.addPoint(Offset(doc.dx - stroke.x, doc.dy - stroke.y));
        }
      case _Gesture.resize:
        _updateResize(doc);
      case _Gesture.rotate:
        _updateRotate(doc);
      case _Gesture.vertex:
        _updateVertex(doc);
      case _Gesture.none:
        break;
    }
  }

  void onPointerUp(NodeEvent event) {
    if (event.currentTarget != _editor._stage) {
      return;
    }
    _editor.lastPointerView = event.stagePosition;

    switch (_gesture) {
      case _Gesture.marquee:
        final box = _preview;
        if (box is MarqueeShape && box.width > 2 && box.height > 2) {
          final rect = Rect.fromLTWH(box.x, box.y, box.width, box.height);
          _editor.selectedIds
            ..clear()
            ..addAll(
              _editor._nodesInRect(rect).map((n) => n.id).whereType<String>(),
            );
        }
        cancelPreview();
      case _Gesture.create:
        _commitCreate();
      case _Gesture.freehand:
        _commitFreehand();
      case _Gesture.move:
      case _Gesture.vertex:
        _editor._history.commit();
      case _Gesture.resize:
      case _Gesture.rotate:
        _rebaseLiftedGroups();
        _editor._history.commit();
      case _Gesture.pan:
      case _Gesture.none:
        break;
    }

    _gesture = _Gesture.none;
    _drag = null;
    _snapTargets = const [];
    snapGuides = const SnapGuides();
    _editor.rotationHintDeg = null;
    _blockToolUntilUp = false;
    _editor._syncInteraction();
    _editor._notify();
  }

  void _updateMove(Offset doc) {
    final drag = _drag;
    if (drag == null || drag.origs.isEmpty) {
      return;
    }
    var delta = doc - _downDoc;
    if (drag.box case final start?) {
      delta += _snap(snapPointsOf(start.rect.shift(delta)));
    }
    for (final orig in drag.origs) {
      orig.node.x = orig.x + delta.dx;
      orig.node.y = orig.y + delta.dy;
    }
    _editor._syncInteraction();
  }

  Node? _createDraft(Offset doc) {
    final Shape? shape = switch (_editor.toolType) {
      ToolType.rectangle => RectShape(fill: _editor.brush.fill),
      ToolType.ellipse => EllipseShape(fill: _editor.brush.fill),
      ToolType.diamond => DiamondShape(fill: _editor.brush.fill),
      ToolType.line || ToolType.arrow => LinearShape(
        isArrow: _editor.toolType == ToolType.arrow,
        points: const [Offset.zero, Offset(1, 0)],
      ),
      _ => null,
    };
    return shape
      ?..id = newNodeId()
      ..x = doc.dx
      ..y = doc.dy
      ..stroke = _editor.brush.stroke
      ..strokeWidth = _editor.brush.strokeWidth
      ..opacity = _editor.brush.opacity;
  }

  void _updateCreate(Offset doc) {
    final node = _preview;
    if (node == null) {
      return;
    }
    final start = _downDoc;
    final end = _snapPoint(doc);
    var dx = end.dx - start.dx;
    var dy = end.dy - start.dy;
    if (_isShiftPressed()) {
      final m = math.max(dx.abs(), dy.abs());
      dx = m * dx.sign;
      dy = m * dy.sign;
    }
    if (node is LinearShape) {
      node.x = start.dx;
      node.y = start.dy;
      node.setPoints([Offset.zero, Offset(dx, dy)]);
    } else if (node is BoxShape) {
      final rect = Rect.fromPoints(start, start + Offset(dx, dy));
      node
        ..x = rect.left
        ..y = rect.top
        ..width = rect.width
        ..height = rect.height;
    }
    _editor._syncInteraction();
  }

  void _commitCreate() {
    final node = _preview;
    cancelPreview();
    final bigEnough = switch (node) {
      LinearShape(:final points) => points.last.distance >= 4,
      BoxShape(:final width, :final height) => math.min(width, height) >= 4,
      _ => false,
    };
    if (node == null || !bigEnough) {
      return;
    }
    _editor._document.add(node);
    _editor.selectedIds
      ..clear()
      ..add(node.id!);
    _editor._history.commit();
  }

  void _commitFreehand() {
    final node = _preview;
    cancelPreview();
    if (node is! FreehandShape || node.points.length < 2) {
      return;
    }
    _editor._document.add(node);
    _editor._history.commit();
  }

  void _beginHandleGesture(HandleLayout handle) {
    _snapTargets = _collectSnapTargets();
    if (handle.kind == HandleKind.vertex ||
        handle.kind == HandleKind.midpoint) {
      _gesture = _Gesture.vertex;
      _drag = _DragStart(handle: handle);
      return;
    }
    for (final node in _editor.selectedNodes) {
      if (node is Group) {
        liftGroup(node);
        _liftedGroups.add(node);
      }
    }
    _editor._stage.updateWorld();
    final single = _editor._singleBox;
    final box = single != null
        ? BoxSnapshot.of(single)
        : BoxSnapshot.fromRect(_editor._selectionAabb()!);
    _gesture = handle.kind == HandleKind.rotate
        ? _Gesture.rotate
        : _Gesture.resize;
    _drag = _DragStart(
      handle: handle,
      box: box,
      origs: [
        for (final n in transformTargets(_editor.selectedNodes)) NodeOrig.of(n),
      ],
    );
  }

  void _updateVertex(Offset doc) {
    final line = _editor._singleLine;
    final handle = _drag?.handle;
    if (line == null || handle == null) {
      return;
    }
    final local = line.worldToLocal(
      _editor.viewFromDoc(_snapPoint(doc)),
    );
    if (handle.kind == HandleKind.midpoint) {
      line.setBend((local - line.chordMid).distance < 6 ? null : local);
    } else {
      line.setPoint(handle.vertexIndex!, local);
    }
    _editor._syncInteraction();
  }

  void _updateRotate(Offset doc) {
    final drag = _drag!;
    final center = drag.box!.center;
    final snap = _isShiftPressed();
    final angle = rotationAngleToPointer(center, doc, snap: snap);
    final single = _editor._singleBox;
    if (single != null) {
      single.rotation = angle;
    } else {
      applyMultipleRotate(
        origs: drag.origs,
        groupCenter: center,
        pointer: doc,
        snap: snap,
      );
    }
    _editor.rotationHintDeg = rotationDegrees(angle);
    _editor._syncInteraction();
    _editor._notify();
  }

  void _updateResize(Offset doc) {
    final drag = _drag!;
    final box = drag.box!;
    final kind = drag.handle!.kind;
    doc = _snapPoint(doc);
    final single = _editor._singleBox;
    if (single is TextShape) {
      applyTextResizeFromPointer(
        node: single,
        orig: box,
        origFontSize: drag.origs.first.fontSize!,
        kind: kind,
        pointer: doc,
      );
    } else if (single != null) {
      final next = nextBoxSizeFromPointer(
        orig: box,
        kind: kind,
        pointer: doc,
        keepAspect: _isShiftPressed(),
      );
      applyBoxFromSnapshot(single, box, next.width, next.height, kind);
    } else {
      applyMultipleResize(
        origs: drag.origs,
        origBounds: box,
        kind: kind,
        pointer: doc,
      );
    }
    _editor._syncInteraction();
  }

  void _rebaseLiftedGroups() {
    if (_liftedGroups.isEmpty) {
      return;
    }
    _editor._stage.updateWorld();
    for (final group in _liftedGroups) {
      if (group.parent != null) {
        rebaseGroup(group, _editor._document);
      }
    }
    _liftedGroups.clear();
    _editor._stage.updateWorld();
  }

  bool _isShiftPressed() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight);
  }
}
