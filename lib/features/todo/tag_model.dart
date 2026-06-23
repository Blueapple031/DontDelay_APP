import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class TagItem {
  final String id;
  final String name;
  final String colorHex;

  TagItem({
    String? id,
    required this.name,
    required this.colorHex,
  }) : id = id ?? _uuid.v4();

  static const defaultId = 'default';

  static TagItem get defaultTag => TagItem(
        id: defaultId,
        name: '기본값',
        colorHex: '#6B7280',
      );

  static const List<String> palette = [
    '#EF4444',
    '#F97316',
    '#EAB308',
    '#22C55E',
    '#3B82F6',
    '#6366F1',
    '#8B5CF6',
  ];

  TagItem copyWith({String? name, String? colorHex}) => TagItem(
        id: id,
        name: name ?? this.name,
        colorHex: colorHex ?? this.colorHex,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
      };

  factory TagItem.fromJson(Map<String, dynamic> json) => TagItem(
        id: json['id'] as String,
        name: json['name'] as String,
        colorHex: json['colorHex'] as String,
      );
}

Color hexToColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
