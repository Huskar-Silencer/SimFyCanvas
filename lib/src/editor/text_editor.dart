import 'package:flutter/widgets.dart';
import 'package:sim_fy_canvas/my_canvas_lib/fy_fl_canvas.dart';

/// One persistent [TextEditingController] / [FocusNode] for the editor.
/// The overlay stays mounted; [visible] only shows or hides the field.
class TextEditor {
  TextEditor({required this.document, required this.onChanged}) {
    controller.addListener(_onType);
  }

  final Layer document;
  final VoidCallback onChanged;
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  String? nodeId;
  bool visible = false;

  bool get isEditing => visible && nodeId != null;

  TextShape? get node {
    final id = nodeId;
    if (id == null) {
      return null;
    }
    final found = document.findOne('#$id');
    return found is TextShape ? found : null;
  }

  void open(TextShape shape) {
    nodeId = shape.id;
    visible = true;
    shape.editing = true;
    controller.value = TextEditingValue(
      text: shape.text,
      selection: TextSelection.collapsed(offset: shape.text.length),
    );
    _fit(shape);
    onChanged();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isEditing) {
        focusNode.requestFocus();
      }
    });
  }

  /// Writes the field into the node, then clears and hides the field.
  /// Returns true when history should record.
  bool commit() {
    if (!isEditing) {
      return false;
    }
    final shape = node;
    final text = controller.text;
    _hide();
    if (shape == null) {
      return false;
    }
    shape.editing = false;
    if (text.trim().isEmpty) {
      shape.remove();
      onChanged();
      return false;
    }
    shape.text = text;
    _fit(shape);
    onChanged();
    return true;
  }

  void discard() {
    final shape = node;
    _hide();
    if (shape != null) {
      shape.editing = false;
    }
    onChanged();
  }

  void dispose() {
    controller.removeListener(_onType);
    controller.dispose();
    focusNode.dispose();
  }

  void _hide() {
    visible = false;
    nodeId = null;
    controller.clear();
    if (focusNode.hasFocus) {
      focusNode.unfocus();
    }
  }

  void _onType() {
    if (!isEditing) {
      return;
    }
    final shape = node;
    if (shape == null) {
      return;
    }
    shape.text = controller.text;
    _fit(shape);
  }

  void _fit(TextShape shape) {
    final size = measureCanvasText(shape.text, shape.fontSize);
    shape.width = size.width;
    shape.height = size.height;
  }
}
