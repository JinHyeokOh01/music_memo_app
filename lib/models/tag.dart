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

  /// 기본 색상 팔레트 (브라운 우드 톤)
  static const List<Color> defaultColors = [
    Color(0xFFD4A574), // 따뜻한 베이지/골드
    Color(0xFFC97D4A), // 오렌지 브라운
    Color(0xFFB85C3A), // 어두운 오렌지 브라운
    Color(0xFF8B6F47), // 중간 브라운
    Color(0xFFA67C52), // 황금 브라운
    Color(0xFFE8C5A0), // 밝은 베이지
    Color(0xFF9D7A5C), // 차콜 브라운
    Color(0xFFC4A082), // 따뜻한 브라운
  ];
}
