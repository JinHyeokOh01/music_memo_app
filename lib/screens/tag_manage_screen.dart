import 'package:flutter/material.dart';
import '../models/tag.dart';

/// 태그 관리 화면 - 태그만 관리
class TagManageScreen extends StatefulWidget {
  final List<Tag> tags;
  final Function(List<Tag>) onTagsChanged;

  const TagManageScreen({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  State<TagManageScreen> createState() => _TagManageScreenState();
}

class _TagManageScreenState extends State<TagManageScreen> {
  late List<Tag> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.tags);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF0A84FF), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('태그 관리', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildAddButton(),
          Expanded(child: _buildTagList()),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: _createTag,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, color: Color(0xFF0A84FF), size: 18),
              const SizedBox(width: 8),
              const Text('태그 추가', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagList() {
    if (_tags.isEmpty) {
      return Center(
        child: Text('등록된 태그가 없어요', style: TextStyle(color: Colors.white.withOpacity(0.4))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _tags.length + 1,
      itemBuilder: (context, index) {
        if (index == _tags.length) return const SizedBox(height: 80);
        final tag = _tags[index];
        return _buildTagItem(tag);
      },
    );
  }

  Widget _buildTagItem(Tag tag) {
    return GestureDetector(
      onLongPress: () => _showTagOptions(tag),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tag.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: tag.color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: tag.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tag.name,
                style: TextStyle(color: tag.color, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createTag() async {
    final result = await showDialog<Tag>(
      context: context,
      builder: (_) => const _TagDialog(),
    );
    if (result != null) {
      setState(() => _tags.add(result));
      widget.onTagsChanged(_tags);
    }
  }

  void _showTagOptions(Tag tag) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white70),
              title: const Text('편집', style: TextStyle(color: Colors.white)),
              onTap: () { Navigator.pop(context); _editTag(tag); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Color(0xFFFF453A)),
              title: const Text('삭제', style: TextStyle(color: Color(0xFFFF453A))),
              onTap: () { Navigator.pop(context); _deleteTag(tag); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _editTag(Tag tag) async {
    final result = await showDialog<Tag>(
      context: context,
      builder: (_) => _TagDialog(tag: tag),
    );
    if (result != null) {
      setState(() {
        final index = _tags.indexWhere((t) => t.id == tag.id);
        if (index != -1) _tags[index] = result;
      });
      widget.onTagsChanged(_tags);
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    final confirm = await _showConfirm('태그 삭제', '"${tag.name}" 태그를 삭제할까요?');
    if (confirm) {
      setState(() => _tags.removeWhere((t) => t.id == tag.id));
      widget.onTagsChanged(_tags);
    }
  }

  Future<bool> _showConfirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(message, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('취소', style: TextStyle(color: Colors.white.withOpacity(0.5)))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Color(0xFFFF453A)))),
        ],
      ),
    );
    return result ?? false;
  }
}

class _TagDialog extends StatefulWidget {
  final Tag? tag;
  const _TagDialog({this.tag});

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  late final TextEditingController _ctrl;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.tag?.name ?? '');
    _color = widget.tag?.color ?? Tag.defaultColors[0];
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tag != null;
    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? '태그 편집' : '태그 추가', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: '태그 이름',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),
            Text('색상', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: Tag.defaultColors.map((c) {
                final sel = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 2),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('취소', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                )),
                Expanded(child: TextButton(
                  onPressed: () {
                    final name = _ctrl.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(context, Tag(
                      id: widget.tag?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      color: _color,
                      isPinned: widget.tag?.isPinned ?? false,
                    ));
                  },
                  child: Text(isEdit ? '저장' : '추가', style: const TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.w600)),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
