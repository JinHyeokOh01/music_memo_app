import 'package:flutter/material.dart';

/// 태그 데이터 모델
class Tag {
  final String id;
  final String name;
  final Color color;
  final bool isPinned; // 메인 메뉴에 표시할지 여부

  const Tag({
    required this.id,
    required this.name,
    required this.color,
    this.isPinned = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.value,
    'isPinned': isPinned,
  };

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
    id: json['id'] as String,
    name: json['name'] as String,
    color: Color(json['color'] as int),
    isPinned: json['isPinned'] as bool? ?? false,
  );

  Tag copyWith({
    String? id,
    String? name,
    Color? color,
    bool? isPinned,
  }) => Tag(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    isPinned: isPinned ?? this.isPinned,
  );

  /// 기본 색상 팔레트
  static const List<Color> defaultColors = [
    Color(0xFF30D158), // 녹색
    Color(0xFF0A84FF), // 파랑
    Color(0xFFFF9F0A), // 주황
    Color(0xFFFF453A), // 빨강
    Color(0xFFBF5AF2), // 보라
    Color(0xFF64D2FF), // 하늘
    Color(0xFFFFD60A), // 노랑
    Color(0xFFFF375F), // 핑크
  ];
}
