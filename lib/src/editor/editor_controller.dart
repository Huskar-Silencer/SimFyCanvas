import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sim_fy_canvas/my_canvas_lib/fy_fl_canvas.dart';

import 'brush.dart';
import 'interaction.dart';
import 'geom.dart';
import 'handles.dart';
import 'history.dart';
import 'snap.dart';
import 'text_editor.dart';
import 'tool.dart';
import 'transform.dart';

part 'editor_gestures.dart';
part 'selection_commands.dart';
part 'scene_session.dart';

/// Color of the infinite paper behind the document, also used for exports.
const paperColor = Color(0xFFF7F8FA);

class EditorController extends ChangeNotifier {
  EditorController() {
    _stage.editMode = true;
    _stage.add(_background);
    _stage.add(_document);
    _stage.add(_interaction);
    _background.add(
      RectShape(
        id: 'paper',
        x: -6000,
        y: -6000,
        width: 12000,
        height: 12000,
        fill: paperColor,
        listening: false,
      ),
    );
    _background.add(GridShape(id: 'grid', spacing: 32));
    _history = DocumentHistory(_document);
    _textEditor = TextEditor(
      document: _document,
      onChanged: () {
        _syncInteraction();
        notifyListeners();
      },
    );
    _gestures = EditorGestures(this);
    _selection = SelectionCommands(this);
    _scene = SceneSession(this);
    _stage.on(NodeEvents.pointerDown, _gestures.onPointerDown);
    _stage.on(NodeEvents.pointerMove, _gestures.onPointerMove);
    _stage.on(NodeEvents.pointerUp, _gestures.onPointerUp);
    _stage.on(NodeEvents.pointerCancel, _gestures.onPointerUp);
    _scene.initSavedBaseline();
  }

  final Stage _stage = Stage();
  final Layer _background = Layer(id: 'background', listening: false);
  final Layer _document = Layer(id: 'document');
  final Layer _interaction = Layer(id: 'interaction');
  late final DocumentHistory _history;
  late final TextEditor _textEditor;
  late final EditorGestures _gestures;
  late final SelectionCommands _selection;
  late final SceneSession _scene;

  ToolType toolType = ToolType.selection;
  BrushStyle brush = const BrushStyle();
  final Set<String> selectedIds = <String>{};

  TextEditor get textEditor => _textEditor;
  bool get isEditingText => _textEditor.isEditing;
  Offset? lastPointerView;
  double? rotationHintDeg;

  bool snapEnabled = false;

  Stage get stage => _stage;
  Layer get background => _background;
  Layer get document => _document;
  List<Node> get elements => List<Node>.unmodifiable(_document.children);
  double get zoom => _stage.scaleX.abs();
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;
  bool get canPaste => _selection.canPaste;
  bool get canGroup => _selection.canGroup;
  bool get canUngroup => _selection.canUngroup;
  bool get hasUnsavedChanges => _scene.hasUnsavedChanges;
  SnapGuides get snapGuides => _gestures.snapGuides;

  void toggleSnap() {
    snapEnabled = !snapEnabled;
    notifyListeners();
  }

  List<Node> get selectedNodes {
    return [for (final id in selectedIds) ?_document.findOne('#$id')];
  }

  Node? get _singleNode {
    final nodes = selectedNodes;
    return nodes.length == 1 ? nodes.first : null;
  }

  BoxShape? get _singleBox {
    final node = _singleNode;
    return node is BoxShape ? node : null;
  }

  LinearShape? get _singleLine {
    final node = _singleNode;
    return node is LinearShape ? node : null;
  }

  Rect? _selectionAabb() {
    final targets = transformTargets(selectedNodes);
    if (targets.isEmpty) {
      return null;
    }
    return unionBounds([for (final n in targets) boundsInSpace(n, _document)]);
  }

  Offset _docFromView(Offset view) => _document.worldToLocal(view);

  Offset viewFromDoc(Offset doc) => _document.localToWorld(doc);

  void _notify() => notifyListeners();

  void setToolType(ToolType type) {
    if (toolType == type) {
      return;
    }
    _gestures.cancelPreview();
    endTextEdit();
    toolType = type;
    _syncInteraction();
    notifyListeners();
  }

  void setSelection(Set<String> ids) {
    selectedIds
      ..clear()
      ..addAll(ids);
    _syncInteraction();
    notifyListeners();
  }

  void updateBrush({
    Color? stroke,
    Color? fill,
    double? strokeWidth,
    double? opacity,
  }) {
    brush = brush.copyWith(
      stroke: stroke,
      fill: fill,
      strokeWidth: strokeWidth,
      opacity: opacity,
    );
    var changed = false;
    for (final node in selectedNodes) {
      if (node is Shape) {
        if (stroke != null) {
          node.stroke = stroke;
        }
        if (fill != null) {
          node.fill = fill;
        }
        if (strokeWidth != null) {
          node.strokeWidth = strokeWidth;
        }
        if (opacity != null) {
          node.opacity = opacity;
        }
        changed = true;
      }
    }
    if (changed) {
      _history.commit();
    }
    notifyListeners();
  }

  void pointerDown(Offset view) {
    _stage.pointerDown(view);
  }

  void pointerMove(Offset view) {
    _stage.pointerMove(view);
  }

  void pointerUp(Offset view) {
    _stage.pointerUp(view);
  }

  void zoomAt(Offset view, double scrollDelta) {
    final factor = scrollDelta > 0 ? 0.9 : 1.1;
    final next = (zoom * factor).clamp(0.1, 8.0);
    final doc = _docFromView(view);
    _stage.scaleX = next;
    _stage.scaleY = next;
    _stage.x = view.dx - doc.dx * next;
    _stage.y = view.dy - doc.dy * next;
    _stage.updateWorld();
    _syncInteraction();
    notifyListeners();
  }

  void zoomIn() => zoomAt(Offset(_stage.width / 2, _stage.height / 2), -1);

  void zoomOut() => zoomAt(Offset(_stage.width / 2, _stage.height / 2), 1);

  void resetView() {
    _stage
      ..x = 0
      ..y = 0
      ..scaleX = 1
      ..scaleY = 1;
    _stage.updateWorld();
    _syncInteraction();
    notifyListeners();
  }

  void undo() {
    endTextEdit();
    if (_history.undo()) {
      selectedIds.clear();
      _syncInteraction();
      notifyListeners();
    }
  }

  void redo() {
    endTextEdit();
    if (_history.redo()) {
      selectedIds.clear();
      _syncInteraction();
      notifyListeners();
    }
  }

  void deleteSelection() => _selection.delete();

  void copySelection() => _selection.copy();

  void cutSelection() => _selection.cut();

  void paste() => _selection.paste();

  void nudge(double dx, double dy) => _selection.nudge(dx, dy);

  void bringToFront() => _selection.bringToFront();

  void sendToBack() => _selection.sendToBack();

  void bringForward() => _selection.bringForward();

  void sendBackward() => _selection.sendBackward();

  void groupSelection() => _selection.group();

  void ungroupSelection() => _selection.ungroup();

  void updateEditingText(String value) {
    _textEditor.controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void endTextEdit() {
    if (!_textEditor.isEditing) {
      return;
    }
    if (_textEditor.commit()) {
      _history.commit();
    }
    selectedIds.removeWhere((id) => _document.findOne('#$id') == null);
    _syncInteraction();
    notifyListeners();
  }

  void _openText(TextShape node) {
    selectedIds
      ..clear()
      ..addAll([?node.id]);
    _textEditor.open(node);
  }

  void _openTextAt(Offset doc) {
    final size = measureCanvasText('', 18);
    final node = TextShape(
      id: newNodeId(),
      x: doc.dx,
      y: doc.dy,
      width: size.width,
      height: size.height,
      fill: brush.stroke,
      stroke: brush.stroke,
      opacity: brush.opacity,
    );
    _document.add(node);
    _openText(node);
  }

  Map<String, Object?> encodeDocument() => _scene.encodeDocument();

  Map<String, Object?> encodeSelection() => _scene.encodeSelection();

  void markSaved() => _scene.markSaved();

  void newScene() => _scene.newScene();

  void loadDocument(Map json, {bool markSaved = false}) =>
      _scene.loadDocument(json, markSaved: markSaved);

  bool loadDocumentString(String source, {bool markSaved = false}) =>
      _scene.loadDocumentString(source, markSaved: markSaved);

  void prepareContextMenu(Offset view) {
    lastPointerView = view;
    _stage.updateWorld();
    final id = _documentHit(view)?.id;
    if (id != null && !selectedIds.contains(id)) {
      selectedIds
        ..clear()
        ..add(id);
      _syncInteraction();
    }
    notifyListeners();
  }

  Node? _documentHit(Offset view) {
    Node? current = _stage.intersect(view);
    while (current != null) {
      if (identical(current.parent, _document)) {
        return current;
      }
      current = current.parent;
    }
    return null;
  }

  List<HandleLayout> _handleLayouts() {
    if (selectedIds.isEmpty) {
      return const <HandleLayout>[];
    }
    _stage.updateWorld();
    if (_singleLine case final line?) {
      return vertexHandleLayouts(line, _document);
    }
    if (_singleBox case final box?) {
      return boxHandleLayouts(BoxSnapshot.of(box), zoom: zoom);
    }
    final aabb = _selectionAabb();
    return aabb == null
        ? const <HandleLayout>[]
        : aabbHandleLayouts(aabb, zoom: zoom);
  }

  Iterable<Node> _nodesInRect(Rect docRect) {
    return _document.children.where((node) {
      return boundsInSpace(node, _document).overlaps(docRect);
    });
  }

  /// Rebuilds the interaction layer: draft preview, snap guides, selection frame
  /// and handles.
  void _syncInteraction() {
    _interaction.removeChildren();
    if (_gestures.preview case final preview?) {
      _interaction.add(preview);
    }
    if (!_gestures.snapGuides.isEmpty) {
      _interaction.add(
        SnapGuideShape(
          segments: _gestures.snapGuides.segments,
          zoom: math.max(zoom, 0.05),
        ),
      );
    }
    if (selectedIds.isEmpty || _textEditor.isEditing) {
      return;
    }
    _stage.updateWorld();
    final z = math.max(zoom, 0.05);
    final box = _singleBox;
    if (box != null) {
      _interaction.add(
        SelectionFrame(
          x: box.x,
          y: box.y,
          rotation: box.rotation,
          aroundCenter: box is TextShape,
          zoom: z,
        )..setBox(box.width, box.height),
      );
    } else if (_singleLine == null) {
      final aabb = _selectionAabb();
      if (aabb != null) {
        _interaction.add(
          SelectionFrame(x: aabb.left, y: aabb.top, zoom: z)
            ..setBox(aabb.width, aabb.height),
        );
      }
    }
    for (final layout in _handleLayouts()) {
      final id = switch (layout.kind) {
        HandleKind.vertex => 'vertex_${layout.vertexIndex}',
        HandleKind.midpoint => 'mid_${layout.vertexIndex}',
        _ => 'h_${layout.kind.name}',
      };
      _interaction.add(
        HandleShape(
          id: id,
          kind: layout.kind,
          vertexIndex: layout.vertexIndex,
          x: layout.center.dx,
          y: layout.center.dy,
          zoom: z,
        ),
      );
    }
  }

  @override
  void dispose() {
    _stage.off(NodeEvents.pointerDown, _gestures.onPointerDown);
    _stage.off(NodeEvents.pointerMove, _gestures.onPointerMove);
    _stage.off(NodeEvents.pointerUp, _gestures.onPointerUp);
    _stage.off(NodeEvents.pointerCancel, _gestures.onPointerUp);
    _textEditor.dispose();
    _stage.dispose();
    super.dispose();
  }
}
