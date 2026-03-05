import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFF1A1A1A),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/bg_texture.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A1A1A).withOpacity(0.7),
                    const Color(0xFF1A1A1A),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildAddButton(),
                Expanded(child: _buildTagList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF888888), size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Text(
            'Manage Tags',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: _createTag,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04), // frosted glass
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: Color(0xFF888888), size: 20),
              const SizedBox(width: 8),
              Text(
                'Add New Tag',
                style: GoogleFonts.inter(
                  color: const Color(0xFF888888),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagList() {
    if (_tags.isEmpty) {
      return Center(
        child: Text('No tags yet.', style: GoogleFonts.inter(color: const Color(0xFF888888))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: tag.color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                tag.name,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935), size: 20),
              onPressed: () => _deleteTag(tag),
              tooltip: 'Delete',
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
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(color: const Color(0xFF555555), borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: Colors.white),
              title: Text('Edit', style: GoogleFonts.inter(color: Colors.white)),
              onTap: () { Navigator.pop(context); _editTag(tag); },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935)),
              title: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFE53935))),
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
    final confirm = await _showConfirm('Delete Tag', 'Are you sure you want to delete "${tag.name}"?');
    if (confirm) {
      setState(() => _tags.removeWhere((t) => t.id == tag.id));
      widget.onTagsChanged(_tags);
    }
  }

  Future<bool> _showConfirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        title: Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(message, style: GoogleFonts.inter(color: const Color(0xFFCCCCCC), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF888888)))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: GoogleFonts.inter(color: const Color(0xFFE53935)))),
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
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEdit ? 'Edit Tag' : 'New Tag', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Tag Name',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            Text('Color', style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: Tag.defaultColors.map((c) {
                final sel = _color == c;
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 2),
                      boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.4), blurRadius: 8)] : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF888888))),
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
                  child: Text(isEdit ? 'Save' : 'Add', style: GoogleFonts.inter(color: const Color(0xFFC5A059), fontWeight: FontWeight.w600)),
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
