import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import '../models/recording.dart';
import '../models/tag.dart';
import '../services/audio_service.dart';
import '../widgets/tag_selector_sheet.dart';

/// Apple Notes 스타일 메모 편집 화면
class RecordingDetailScreen extends StatefulWidget {
  final Recording recording;
  final List<Tag> tags;
  final AudioService audioService;
  final Function(Tag)? onTagCreated;

  const RecordingDetailScreen({
    super.key,
    required this.recording,
    required this.tags,
    required this.audioService,
    this.onTagCreated,
  });

  @override
  State<RecordingDetailScreen> createState() => _RecordingDetailScreenState();
}

class _RecordingDetailScreenState extends State<RecordingDetailScreen> {
  late TextEditingController _titleController;
  late List<_ContentItem> _items;
  late List<String> _selectedTags;
  late List<Tag> _tags;

  bool _isPlaying = false;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.recording.title);
    _items = _parseItems(widget.recording.memo);
    _selectedTags = List.from(widget.recording.tags);
    _tags = List.from(widget.tags);

    if (!widget.recording.isMemoOnly) {
      widget.audioService.playerStateStream.listen((state) {
        if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
      });
      widget.audioService.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
    }
  }

  List<_ContentItem> _parseItems(String memo) {
    if (memo.isEmpty) {
      return [_ContentItem(text: '', isChecklist: false, isDone: false)];
    }

    final items = <_ContentItem>[];
    final lines = memo.split('\n');

    for (final line in lines) {
      final match = Recording.checklistLinePattern.firstMatch(line);
      if (match != null) {
        final text = (match.group(2) ?? '').trim();
        final mark = match.group(1) ?? ' ';
        items.add(_ContentItem(
          text: text,
          isChecklist: true,
          isDone: mark.toLowerCase() == 'x',
        ));
      } else {
        items.add(_ContentItem(
          text: line,
          isChecklist: false,
          isDone: false,
        ));
      }
    }

    if (items.isEmpty) {
      items.add(_ContentItem(text: '', isChecklist: false, isDone: false));
    }

    return items;
  }

  String _buildMemo() {
    final lines = <String>[];
    for (final item in _items) {
      if (item.isChecklist) {
        final text = item.controller.text.trim();
        if (text.isNotEmpty) {
          final mark = item.isDone ? 'x' : ' ';
          lines.add('- [$mark] $text');
        }
      } else {
        lines.add(item.controller.text);
      }
    }
    return lines.join('\n');
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final item in _items) {
      item.controller.dispose();
      item.focusNode.dispose();
    }
    widget.audioService.stop();
    super.dispose();
  }

  void _save() {
    final memoText = _buildMemo();
    final checklist = Recording.checklistFromMemo(memoText);
    // 제목이 비어있으면 기본값(년 월 일 시간) 사용
    final title = _titleController.text.trim();
    final finalTitle = title.isEmpty ? _getDefaultTitle() : title;
    final updated = widget.recording.copyWith(
      title: finalTitle,
      memo: memoText,
      tags: _selectedTags,
      checklist: checklist,
    );
    Navigator.pop(context, updated);
  }

  void _togglePlay() async {
    if (widget.recording.isMemoOnly) return;
    if (_isPlaying) {
      await widget.audioService.pause();
    } else {
      if (widget.audioService.currentPlayingId != widget.recording.id) {
        await widget.audioService.play(widget.recording);
      } else {
        await widget.audioService.resume();
      }
    }
  }

  void _openTagSelector() {
    TagSelectorSheet.show(
      context: context,
      tags: _tags,
      selectedIds: _selectedTags,
      onChanged: (ids) => setState(() => _selectedTags = ids),
      onTagCreated: (tag) {
        setState(() => _tags.add(tag));
        widget.onTagCreated?.call(tag);
      },
    );
  }

  void _addChecklist() {
    final newItem = _ContentItem(text: '', isChecklist: true, isDone: false);
    setState(() {
      _items.add(newItem);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) newItem.focusNode.requestFocus();
    });
  }

  void _toggleItemDone(int index) {
    setState(() {
      _items[index].isDone = !_items[index].isDone;
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) {
      _items[0].controller.clear();
      _items[0].isChecklist = false;
      _items[0].isDone = false;
      setState(() {});
      return;
    }
    final item = _items.removeAt(index);
    item.controller.dispose();
    item.focusNode.dispose();
    setState(() {});
  }

  void _handleItemSubmit(int index) {
    final item = _items[index];
    if (item.isChecklist) {
      final text = item.controller.text.trim();
      if (text.isEmpty) {
        // 빈 체크리스트 → 일반 텍스트로 변환
        setState(() {
          item.isChecklist = false;
        });
        return;
      }
      // 새 체크리스트 추가
      final newItem = _ContentItem(text: '', isChecklist: true, isDone: false);
      setState(() {
        _items.insert(index + 1, newItem);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) newItem.focusNode.requestFocus();
      });
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _getDefaultTitle() {
    // 년 월 일 시간 형식으로 표시 (한국 시간 기준)
    return DateFormat('yyyy년 M월 d일 H:mm', 'ko').format(widget.recording.createdAt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.recording.isMemoOnly) ...[
                      const SizedBox(height: 16),
                      _buildMiniPlayer(),
                      const SizedBox(height: 24),
                    ] else
                      const SizedBox(height: 20),
                    
                    // 제목
                    _buildTitleField(),
                    const SizedBox(height: 16),
                    
                    // 콘텐츠 영역 (메모 + 체크리스트)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 콘텐츠 아이템들
                          ...List.generate(_items.length, (i) => _buildItem(i)),
                          
                          const SizedBox(height: 12),
                          
                          // 체크리스트 추가 버튼
                          _buildAddChecklistButton(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // 태그
                    _buildTagSection(),
                    
                    const SizedBox(height: 24),
                    
                    // 날짜 정보
                    _buildDateInfo(),
                    
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: _save,
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).primaryColor, size: 22),
          ),
          const Spacer(),
          TextButton(
            onPressed: _save,
            child: Text(
              '완료',
              style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final progress = widget.recording.duration.inMilliseconds > 0
        ? _position.inMilliseconds / widget.recording.duration.inMilliseconds
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
              child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 26),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    valueColor: AlwaysStoppedAnimation(Theme.of(context).primaryColor),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(_position), style: TextStyle(color: const Color(0xFF795548).withOpacity(0.5), fontSize: 12)),
                    Text(_formatDuration(widget.recording.duration), style: TextStyle(color: const Color(0xFF795548).withOpacity(0.5), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: TextField(
        controller: _titleController,
        style: const TextStyle(color: Color(0xFF4E342E), fontSize: 22, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: _getDefaultTitle(),
          hintStyle: TextStyle(color: const Color(0xFF795548).withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
        maxLines: null,
      ),
    );
  }

  Widget _buildItem(int index) {
    final item = _items[index];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.isChecklist)
            GestureDetector(
              onTap: () => _toggleItemDone(index),
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2, right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.isDone ? Theme.of(context).primaryColor : const Color(0xFF795548).withOpacity(0.4),
                    width: 2,
                  ),
                  color: item.isDone ? Theme.of(context).primaryColor : Colors.transparent,
                ),
                child: item.isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
          Expanded(
            child: TextField(
              controller: item.controller,
              focusNode: item.focusNode,
              style: TextStyle(
                color: const Color(0xFF4E342E),
                fontSize: 17,
                height: 1.4,
                decoration: item.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                decorationColor: const Color(0xFF795548).withOpacity(0.6),
              ),
              decoration: InputDecoration(
                hintText: item.isChecklist ? '할 일' : '메모',
                hintStyle: TextStyle(color: const Color(0xFF795548).withOpacity(0.5)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
              ),
              maxLines: item.isChecklist ? 1 : null,
              textInputAction: item.isChecklist ? TextInputAction.next : TextInputAction.newline,
              onSubmitted: item.isChecklist ? (_) => _handleItemSubmit(index) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddChecklistButton() {
    return GestureDetector(
      onTap: _addChecklist,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF795548).withOpacity(0.3), width: 1.5),
            ),
            child: Icon(Icons.add, size: 14, color: const Color(0xFF795548).withOpacity(0.5)),
          ),
          const SizedBox(width: 10),
          Text(
            '체크리스트 추가',
            style: TextStyle(color: const Color(0xFF795548).withOpacity(0.6), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildTagSection() {
    final selectedTagObjects = _selectedTags
        .map((id) => _tags.firstWhere((t) => t.id == id, orElse: () => _tags.first))
        .where((t) => _tags.any((tag) => tag.id == t.id))
        .toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...selectedTagObjects.map((tag) => GestureDetector(
          onTap: () => setState(() => _selectedTags.remove(tag.id)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tag.color.withOpacity(0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(tag.name, style: TextStyle(color: tag.color, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                Icon(Icons.close, color: tag.color.withOpacity(0.7), size: 14),
              ],
            ),
          ),
        )),
        GestureDetector(
          onTap: _openTagSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: const Color(0xFF795548).withOpacity(0.5), size: 16),
                const SizedBox(width: 4),
                Text('태그', style: TextStyle(color: const Color(0xFF795548).withOpacity(0.5), fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo() {
    final date = widget.recording.createdAt;
    final dateStr = '${date.year}.${date.month}.${date.day} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Text(
      '${widget.recording.isMemoOnly ? '작성' : '녹음'} $dateStr${widget.recording.isMemoOnly ? '' : ' · ${widget.recording.durationString}'}',
      style: TextStyle(color: const Color(0xFF795548).withOpacity(0.5), fontSize: 12),
    );
  }
}

class _ContentItem {
  final TextEditingController controller;
  final FocusNode focusNode;
  bool isChecklist;
  bool isDone;

  _ContentItem({
    required String text,
    required this.isChecklist,
    required this.isDone,
  })  : controller = TextEditingController(text: text),
        focusNode = FocusNode();
}
