import 'dart:convert';
import 'dart:ui';

import '../shapes/box_shape.dart';
import '../shapes/diamond_shape.dart';
import '../shapes/ellipse_shape.dart';
import '../shapes/freehand_shape.dart';
import '../shapes/grid_shape.dart';
import '../shapes/linear_shape.dart';
import '../shapes/rect_shape.dart';
import '../shapes/shape.dart';
import '../shapes/text_shape.dart';
import 'collection.dart';
import 'group.dart';
import 'layer.dart';
import 'node.dart';
import 'stage.dart';

typedef NodeFactory = Node Function(Map<String, dynamic> json);

/// Encodes and decodes a scene graph as JSON. Event listeners are not stored.
class NodeCodec {
  NodeCodec._();

  static final Map<String, NodeFactory> _factories = <String, NodeFactory>{};

  static void register(String type, NodeFactory factory) {
    _factories[type] = factory;
  }

  static Map<String, Object?> encode(Node node) {
    final json = <String, Object?>{'type': typeOf(node)};
    _writeNode(node, json);
    if (node is Stage) {
      _put(json, 'width', node.width, 0);
      _put(json, 'height', node.height, 0);
    }
    if (node is Shape) {
      final fill = node.fill;
      if (fill != null) {
        json['fill'] = fill.toARGB32();
      }
      final stroke = node.stroke;
      if (stroke != null) {
        json['stroke'] = stroke.toARGB32();
      }
      _put(json, 'strokeWidth', node.strokeWidth, 1);
    }
    if (node is BoxShape) {
      _put(json, 'width', node.width, 0);
      _put(json, 'height', node.height, 0);
    }
    if (node is LinearShape) {
      json['points'] = _encodePoints(node.points);
      _put(json, 'isArrow', node.isArrow, false);
      if (node.isBent) {
        json['bend'] = <double>[node.bend.dx, node.bend.dy];
      }
    }
    if (node is FreehandShape) {
      json['points'] = _encodePoints(node.points);
    }
    if (node is TextShape) {
      _put(json, 'text', node.text, '');
      _put(json, 'fontSize', node.fontSize, 18);
    }
    if (node is Collection && node.children.isNotEmpty) {
      json['children'] = [for (final child in node.children) encode(child)];
    }
    return json;
  }

  static String encodeString(Node node, {String? indent}) {
    final map = encode(node);
    if (indent == null) {
      return jsonEncode(map);
    }
    return JsonEncoder.withIndent(indent).convert(map);
  }

  static Node decode(Map json) {
    final map = Map<String, dynamic>.from(json);
    final type = map['type'] as String?;
    if (type == null || type.isEmpty) {
      throw const FormatException('Missing node type');
    }
    final node = _instantiate(type, map);
    _apply(node, map);
    final children = map['children'];
    if (children is List && node is Collection) {
      for (final child in children) {
        if (child is Map) {
          node.add(decode(child));
        }
      }
    }
    return node;
  }

  static Node decodeString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('JSON root must be an object');
    }
    return decode(decoded);
  }

  static String typeOf(Node node) {
    if (node is Stage) {
      return 'Stage';
    }
    if (node is Layer) {
      return 'Layer';
    }
    if (node is Group) {
      return 'Group';
    }
    if (node is RectShape) {
      return 'RectShape';
    }
    if (node is EllipseShape) {
      return 'EllipseShape';
    }
    if (node is DiamondShape) {
      return 'DiamondShape';
    }
    if (node is LinearShape) {
      return 'LinearShape';
    }
    if (node is FreehandShape) {
      return 'FreehandShape';
    }
    if (node is TextShape) {
      return 'TextShape';
    }
    if (node is GridShape) {
      return 'GridShape';
    }
    return node.runtimeType.toString();
  }

  static Node _instantiate(String type, Map<String, dynamic> json) {
    switch (type) {
      case 'Stage':
        return Stage();
      case 'Layer':
        return Layer();
      case 'Group':
        return Group();
      case 'RectShape':
        return RectShape();
      case 'EllipseShape':
        return EllipseShape();
      case 'DiamondShape':
        return DiamondShape();
      case 'LinearShape':
        return LinearShape();
      case 'FreehandShape':
        return FreehandShape();
      case 'TextShape':
        return TextShape();
      case 'GridShape':
        return GridShape();
      default:
        final factory = _factories[type];
        if (factory != null) {
          return factory(json);
        }
        throw FormatException('Unknown node type: $type');
    }
  }

  static void _apply(Node node, Map<String, dynamic> json) {
    if (json.containsKey('id')) {
      node.id = json['id'] as String?;
    }
    if (json.containsKey('name')) {
      node.name = json['name'] as String? ?? '';
    }
    if (json.containsKey('x')) {
      node.x = _num(json['x']);
    }
    if (json.containsKey('y')) {
      node.y = _num(json['y']);
    }
    if (json.containsKey('scaleX')) {
      node.scaleX = _num(json['scaleX'], 1);
    }
    if (json.containsKey('scaleY')) {
      node.scaleY = _num(json['scaleY'], 1);
    }
    if (json.containsKey('rotation')) {
      node.rotation = _num(json['rotation']);
    }
    if (json.containsKey('offsetX')) {
      node.offsetX = _num(json['offsetX']);
    }
    if (json.containsKey('offsetY')) {
      node.offsetY = _num(json['offsetY']);
    }
    if (json.containsKey('opacity')) {
      node.opacity = _num(json['opacity'], 1);
    }
    if (json.containsKey('visible')) {
      node.visible = json['visible'] as bool? ?? true;
    }
    if (json.containsKey('listening')) {
      node.listening = json['listening'] as bool? ?? true;
    }
    if (json.containsKey('draggable')) {
      node.draggable = json['draggable'] as bool? ?? false;
    }
    if (json.containsKey('zIndex')) {
      node.zIndex = (json['zIndex'] as num?)?.toInt() ?? 0;
    }
    if (node is Stage) {
      if (json.containsKey('width')) {
        node.width = _num(json['width']);
      }
      if (json.containsKey('height')) {
        node.height = _num(json['height']);
      }
    }
    if (node is Shape) {
      if (json.containsKey('fill')) {
        node.fill = _color(json['fill']);
      }
      if (json.containsKey('stroke')) {
        node.stroke = _color(json['stroke']);
      }
      if (json.containsKey('strokeWidth')) {
        node.strokeWidth = _num(json['strokeWidth'], 1);
      }
    }
    if (node is BoxShape) {
      if (json.containsKey('width')) {
        node.width = _num(json['width']);
      }
      if (json.containsKey('height')) {
        node.height = _num(json['height']);
      }
    }
    if (node is LinearShape) {
      if (json.containsKey('points')) {
        node.setPoints(_decodePoints(json['points']));
      }
      if (json.containsKey('isArrow')) {
        node.isArrow = json['isArrow'] as bool? ?? false;
      }
      if (json.containsKey('bend')) {
        final bend = _decodePoints([json['bend']]);
        if (bend.isNotEmpty) {
          node.setBend(bend.first);
        }
      }
    }
    if (node is FreehandShape) {
      if (json.containsKey('points')) {
        node.setPoints(_decodePoints(json['points']));
      }
    }
    if (node is TextShape) {
      if (json.containsKey('text')) {
        node.text = json['text'] as String? ?? '';
      }
      if (json.containsKey('fontSize')) {
        node.fontSize = _num(json['fontSize'], 18);
      }
    }
  }

  static void _writeNode(Node node, Map<String, Object?> json) {
    if (node.id != null) {
      json['id'] = node.id;
    }
    _put(json, 'name', node.name, '');
    _put(json, 'x', node.x, 0);
    _put(json, 'y', node.y, 0);
    _put(json, 'scaleX', node.scaleX, 1);
    _put(json, 'scaleY', node.scaleY, 1);
    _put(json, 'rotation', node.rotation, 0);
    _put(json, 'offsetX', node.offsetX, 0);
    _put(json, 'offsetY', node.offsetY, 0);
    _put(json, 'opacity', node.opacity, 1);
    _put(json, 'visible', node.visible, true);
    _put(json, 'listening', node.listening, true);
    _put(json, 'draggable', node.draggable, false);
    _put(json, 'zIndex', node.zIndex, 0);
  }

  static void _put(
    Map<String, Object?> json,
    String key,
    Object? value,
    Object? defaultValue,
  ) {
    if (value != defaultValue) {
      json[key] = value;
    }
  }

  static double _num(Object? value, [double fallback = 0]) {
    if (value is num) {
      return value.toDouble();
    }
    return fallback;
  }

  static List<List<double>> _encodePoints(List<Offset> points) {
    return [
      for (final p in points) <double>[p.dx, p.dy],
    ];
  }

  static List<Offset> _decodePoints(Object? value) {
    if (value is! List) {
      return const <Offset>[];
    }
    final points = <Offset>[];
    for (final item in value) {
      if (item is List && item.length >= 2) {
        points.add(Offset(_num(item[0]), _num(item[1])));
      }
    }
    return points;
  }

  static Color? _color(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return Color(value);
    }
    if (value is num) {
      return Color(value.toInt());
    }
    if (value is String) {
      var hex = value.startsWith('#') ? value.substring(1) : value;
      if (hex.startsWith('0x') || hex.startsWith('0X')) {
        hex = hex.substring(2);
      }
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    }
    return null;
  }
}

extension NodeJson on Node {
  Map<String, Object?> toJson() => NodeCodec.encode(this);

  String toJsonString({String? indent}) =>
      NodeCodec.encodeString(this, indent: indent);
}
