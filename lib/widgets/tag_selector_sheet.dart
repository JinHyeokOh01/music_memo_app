import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          // 핸들
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF555555),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Text(
                  'Select Tags',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                if (_selected.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC5A059),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_selected.length}',
                      style: GoogleFonts.inter(color: const Color(0xFF1A1A1A), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('Done', style: GoogleFonts.inter(color: const Color(0xFFC5A059), fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // 검색
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search tags...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF666666)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF888888), size: 18),
                filled: true,
                fillColor: Colors.white.withOpacity(0.04),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Text('No results found', style: GoogleFonts.inter(color: const Color(0xFF888888))),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _createTag(_searchQuery),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5A059).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Create "$_searchQuery"', style: GoogleFonts.inter(color: const Color(0xFFC5A059), fontSize: 14, fontWeight: FontWeight.w600)),
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
          _buildSection('Selected'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _selected
                .map((id) => widget.tags.firstWhere((t) => t.id == id, orElse: () => widget.tags.first))
                .where((t) => widget.tags.contains(t))
                .map((tag) => _buildTagChip(tag))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],

        // 전체 태그
        _buildSection('All Tags'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.tags.map((tag) => _buildTagChip(tag)).toList(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTagChip(Tag tag) {
    final isSelected = _selected.contains(tag.id);
    return GestureDetector(
      onTap: () => _toggle(tag.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? tag.color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? tag.color.withOpacity(0.5) : Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, color: tag.color, size: 14),
              const SizedBox(width: 6),
            ] else ...[
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: tag.color.withOpacity(0.5), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              tag.name,
              style: GoogleFonts.inter(
                color: isSelected ? tag.color : Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
