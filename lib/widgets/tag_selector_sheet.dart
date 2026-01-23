import 'package:flutter/material.dart';
import '../models/tag.dart';

/// 태그 선택 시트 - 간단한 버전
class TagSelectorSheet {
  static void show({
    required BuildContext context,
    required List<Tag> tags,
    required List<String> selectedIds,
    required Function(List<String>) onChanged,
    Function(Tag)? onTagCreated,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TagSelectorContent(
        tags: tags,
        selectedIds: selectedIds,
        onChanged: onChanged,
        onTagCreated: onTagCreated,
      ),
    );
  }
}

class _TagSelectorContent extends StatefulWidget {
  final List<Tag> tags;
  final List<String> selectedIds;
  final Function(List<String>) onChanged;
  final Function(Tag)? onTagCreated;

  const _TagSelectorContent({
    required this.tags,
    required this.selectedIds,
    required this.onChanged,
    this.onTagCreated,
  });

  @override
  State<_TagSelectorContent> createState() => _TagSelectorContentState();
}

class _TagSelectorContentState extends State<_TagSelectorContent> {
  late List<String> _selected;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedIds);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
    widget.onChanged(_selected);
  }

  List<Tag> get _filteredTags {
    if (_searchQuery.isEmpty) return widget.tags;
    return widget.tags.where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF2D241F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFC9B8A3).withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text(
                  '태그 선택',
                  style: const TextStyle(color: Color(0xFFF5E6D3), fontSize: 17, fontWeight: FontWeight.w600),
                ),
                if (_selected.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A574),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_selected.length}',
                      style: const TextStyle(color: Color(0xFF1A1612), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text('완료', style: TextStyle(color: Color(0xFFD4A574), fontSize: 16, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),

          // 검색
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: Color(0xFFF5E6D3), fontSize: 14),
              decoration: InputDecoration(
                hintText: '태그 검색...',
                hintStyle: TextStyle(color: const Color(0xFFC9B8A3).withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: const Color(0xFFC9B8A3).withOpacity(0.6), size: 18),
                filled: true,
                fillColor: const Color(0xFF3D3328),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
              onSubmitted: (v) {
                // 엔터 시 첫 번째 결과 선택
                final results = _filteredTags;
                if (results.isNotEmpty) {
                  _toggle(results.first.id);
                }
              },
            ),
          ),

          // 태그 목록
          Expanded(
            child: _searchQuery.isNotEmpty
                ? _buildSearchResults()
                : _buildTagList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _filteredTags;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('검색 결과 없음', style: TextStyle(color: const Color(0xFFC9B8A3).withOpacity(0.5))),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _createTag(_searchQuery),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A574),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('"$_searchQuery" 만들기', style: const TextStyle(color: Color(0xFF1A1612), fontSize: 14)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: results.map((tag) => _buildTagChip(tag)).toList(),
        ),
      ],
    );
  }

  Widget _buildTagList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        // 선택된 태그
        if (_selected.isNotEmpty) ...[
          _buildSection('선택됨'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selected
                .map((id) => widget.tags.firstWhere((t) => t.id == id, orElse: () => widget.tags.first))
                .where((t) => widget.tags.contains(t))
                .map((tag) => _buildTagChip(tag))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // 전체 태그
        _buildSection('전체'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.tags.map((tag) => _buildTagChip(tag)).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTagChip(Tag tag) {
    final isSelected = _selected.contains(tag.id);
    return GestureDetector(
      onTap: () => _toggle(tag.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? tag.color : const Color(0xFF3D3328),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, color: Color(0xFF1A1612), size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              tag.name,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1A1612) : const Color(0xFFC9B8A3),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createTag(String name) {
    final tag = Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: Tag.defaultColors[0],
      isPinned: true,
    );
    widget.onTagCreated?.call(tag);
    setState(() {
      _selected.add(tag.id);
      _searchCtrl.clear();
      _searchQuery = '';
    });
    widget.onChanged(_selected);
  }
}
