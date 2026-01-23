import 'package:flutter/material.dart';
import '../models/tag.dart';

/// 태그 필터 바 - 여러 태그 동시 선택 가능
class TagFilterBar extends StatelessWidget {
  final List<Tag> tags;
  final List<String> selectedTagIds;
  final Function(String) onTagSelected;

  const TagFilterBar({
    super.key,
    required this.tags,
    required this.selectedTagIds,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(
          '태그 관리에서 표시할 태그를 선택하세요',
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
        ),
      );
    }

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tags.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final tag = tags[index];
          final isSelected = selectedTagIds.contains(tag.id);

          return GestureDetector(
            onTap: () => onTagSelected(tag.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? tag.color : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? tag.color : const Color(0xFF3A3A3C),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  tag.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
