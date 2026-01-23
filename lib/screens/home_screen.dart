import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/recording.dart';
import '../models/tag.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';
import '../widgets/recording_card.dart';
import '../widgets/recording_button.dart';
import 'recording_detail_screen.dart';
import 'tag_manage_screen.dart';

/// 한국 시간대(UTC+9)로 현재 시간 반환
DateTime getKoreaTime() {
  // UTC 시간을 가져와서 한국 시간대(UTC+9)로 변환
  final utcNow = DateTime.now().toUtc();
  return utcNow.add(const Duration(hours: 9));
}

/// 홈 화면 - 녹음 목록 표시
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  final AudioService _audioService = AudioService();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<Recording> _recordings = [];
  List<Tag> _tags = [];
  final List<String> _selectedTagIds = [];
  String _searchQuery = '';
  bool _isRecording = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    await _storageService.init();
    await _loadData();
    setState(() => _isLoading = false);
  }

  Future<void> _loadData() async {
    final recordings = await _storageService.loadRecordings();
    final tags = await _storageService.loadTags();

    recordings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() {
      _recordings = recordings;
      _tags = tags;
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final recording = await _audioService.stopRecording();
      if (recording != null) {
        setState(() {
          _recordings.insert(0, recording);
          _isRecording = false;
        });
        await _storageService.saveRecordings(_recordings);
        if (mounted) _openRecordingDetail(recording);
      } else {
        setState(() => _isRecording = false);
        _showError('녹음 저장에 실패했어요');
      }
    } else {
      final success = await _audioService.startRecording();
      if (success) {
        setState(() => _isRecording = true);
      } else {
        _showError('마이크 권한이 필요해요');
      }
    }
  }

  Future<void> _openRecordingDetail(Recording recording) async {
    final result = await Navigator.push<Recording?>(
      context,
      MaterialPageRoute(
        builder: (context) => RecordingDetailScreen(
          recording: recording,
          tags: _tags,
          audioService: _audioService,
          onTagCreated: (newTag) async {
            setState(() => _tags.add(newTag));
            await _storageService.saveTags(_tags);
          },
        ),
      ),
    );

    if (result != null) {
      final index = _recordings.indexWhere((r) => r.id == result.id);
      final hasContent = result.filePath.isNotEmpty ||
          result.title.trim().isNotEmpty ||
          result.memo.trim().isNotEmpty ||
          result.tags.isNotEmpty ||
          result.checklist.isNotEmpty;
      if (index != -1) {
        setState(() => _recordings[index] = result);
        await _storageService.saveRecordings(_recordings);
      } else if (hasContent) {
        setState(() => _recordings.insert(0, result));
        await _storageService.saveRecordings(_recordings);
      }
    }
  }

  String _getDisplayMemo(Recording recording) {
    if (!Recording.memoHasChecklist(recording.memo) && recording.checklist.isNotEmpty) {
      return Recording.mergeChecklistIntoMemo(recording.memo, recording.checklist);
    }
    return recording.memo;
  }

  Future<void> _toggleChecklistInMemo(Recording recording, String memoText, int lineIndex, bool isDone) async {
    if (lineIndex < 0) {
      final checklistIndex = -1 - lineIndex;
      if (checklistIndex < 0 || checklistIndex >= recording.checklist.length) return;
      final updatedChecklist = List<ChecklistItem>.from(recording.checklist);
      updatedChecklist[checklistIndex] = updatedChecklist[checklistIndex].copyWith(isDone: isDone);
      final updatedMemo = Recording.memoHasChecklist(recording.memo)
          ? recording.memo
          : Recording.mergeChecklistIntoMemo(recording.memo, updatedChecklist);
      final updated = recording.copyWith(checklist: updatedChecklist);
      final index = _recordings.indexWhere((r) => r.id == recording.id);
      if (index == -1) return;
      setState(() => _recordings[index] = updated.copyWith(memo: updatedMemo));
      await _storageService.saveRecordings(_recordings);
      return;
    }
    final lines = memoText.split('\n');
    if (lineIndex < 0 || lineIndex >= lines.length) return;
    final match = Recording.checklistLinePattern.firstMatch(lines[lineIndex]);
    if (match == null) return;
    final text = (match.group(2) ?? '').trim();
    if (text.isEmpty) return;
    final mark = isDone ? 'x' : ' ';
    lines[lineIndex] = '- [$mark] $text';
    final updatedMemo = lines.join('\n');
    final updatedChecklist = Recording.checklistFromMemo(updatedMemo);
    final updated = recording.copyWith(
      memo: updatedMemo,
      checklist: updatedChecklist,
    );
    final index = _recordings.indexWhere((r) => r.id == recording.id);
    if (index == -1) return;
    setState(() => _recordings[index] = updated);
    await _storageService.saveRecordings(_recordings);
  }

  Future<void> _createMemoEntry() async {
    if (_isRecording) return;
    final now = getKoreaTime();
    final memo = Recording(
      id: now.millisecondsSinceEpoch.toString(),
      filePath: '',
      createdAt: now,
      duration: Duration.zero,
    );
    await _openRecordingDetail(memo);
  }

  Future<void> _deleteRecording(Recording recording) async {
    final isMemo = recording.isMemoOnly;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(isMemo ? '메모 삭제' : '녹음 삭제', style: const TextStyle(color: Color(0xFF4E342E))),
        content: Text(isMemo ? '이 메모를 삭제할까요?' : '이 녹음을 삭제할까요?', style: const TextStyle(color: Color(0xFF795548))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('삭제', style: TextStyle(color: Color(0xFFD32F2F)))),
        ],
      ),
    );

    if (confirm == true) {
      if (recording.filePath.isNotEmpty) {
        await _audioService.deleteRecordingFile(recording.filePath);
      }
      setState(() => _recordings.removeWhere((r) => r.id == recording.id));
      await _storageService.saveRecordings(_recordings);
    }
  }

  Future<void> _togglePin(Recording recording) async {
    final index = _recordings.indexWhere((r) => r.id == recording.id);
    if (index == -1) return;
    final updated = recording.copyWith(isPinned: !recording.isPinned);
    setState(() => _recordings[index] = updated);
    await _storageService.saveRecordings(_recordings);
  }

  Future<void> _togglePlay(Recording recording) async {
    if (recording.isMemoOnly) return;
    if (_audioService.currentPlayingId == recording.id) {
      await _audioService.stop();
      setState(() {});
    } else {
      await _audioService.play(recording);
      setState(() {});
      _audioService.playerStateStream.listen((state) {
        if (state == PlayerState.completed || state == PlayerState.stopped) {
          if (mounted) setState(() {});
        }
      });
    }
  }

  List<Recording> get _filteredRecordings {
    if (_selectedTagIds.isEmpty) return _recordings;
    return _recordings
        .where((r) => _selectedTagIds.every((tagId) => r.tags.contains(tagId)))
        .toList();
  }

  // 태그 선택에 추가
  void _addTagFilter(String tagId) {
    if (!_selectedTagIds.contains(tagId)) {
      setState(() => _selectedTagIds.add(tagId));
    }
  }

  // 태그 필터에서 제거
  void _removeTagFilter(String tagId) {
    setState(() => _selectedTagIds.remove(tagId));
  }

  Tag? _findExactTag(String name) {
    final query = name.trim().toLowerCase();
    for (final tag in _tags) {
      if (tag.name.trim().toLowerCase() == query) return tag;
    }
    return null;
  }

  Future<void> _createTagFromSearch(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final existing = _findExactTag(trimmed);
    if (existing != null) {
      setState(() {
        if (!_selectedTagIds.contains(existing.id)) {
          _selectedTagIds.add(existing.id);
        }
        _searchCtrl.clear();
        _searchQuery = '';
      });
      return;
    }
    final tag = Tag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: trimmed,
      color: Tag.defaultColors[0],
    );
    setState(() {
      _tags.add(tag);
      _selectedTagIds.add(tag.id);
      _searchCtrl.clear();
      _searchQuery = '';
    });
    await _storageService.saveTags(_tags);
  }

  Future<bool> _confirmAddTag(String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D241F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('태그 추가', style: TextStyle(color: Color(0xFFF5E6D3), fontSize: 16)),
        content: Text(
          '"$name" 태그가 없어요. 추가하시겠습니까?',
          style: const TextStyle(color: Color(0xFFC9B8A3), fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('취소', style: TextStyle(color: const Color(0xFFC9B8A3).withOpacity(0.5)))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('추가', style: TextStyle(color: Color(0xFFD4A574)))),
        ],
      ),
    );
    return result ?? false;
  }

  // 검색 결과 태그
  List<Tag> get _searchResults {
    if (_searchQuery.isEmpty) return _tags;
    return _tags.where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: const Color(0xFFD32F2F)),
    );
  }

  void _openTagManageScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TagManageScreen(
          tags: _tags,
          onTagsChanged: (newTags) async {
            setState(() => _tags = newTags);
            await _storageService.saveTags(newTags);

            final tagIds = newTags.map((t) => t.id).toSet();
            bool recordingsChanged = false;
            for (var i = 0; i < _recordings.length; i++) {
              final recording = _recordings[i];
              final originalLength = recording.tags.length;
              final updatedTags = recording.tags.where((tagId) => tagIds.contains(tagId)).toList();
              if (updatedTags.length != originalLength) {
                _recordings[i] = recording.copyWith(tags: updatedTags);
                recordingsChanged = true;
              }
            }
            if (recordingsChanged) await _storageService.saveRecordings(_recordings);

            // 선택된 태그 중 삭제된 것 제거
            _selectedTagIds.removeWhere((id) => !tagIds.contains(id));
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4A574)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  _buildTagSelector(),
                  Expanded(
                    child: _filteredRecordings.isEmpty
                        ? _buildEmptyState()
                        : _buildRecordingList(),
                  ),
                  _buildBottomActions(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('나의 체크리스트', style: TextStyle(color: Color(0xFF4E342E), fontSize: 25, fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: _openTagManageScreen,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.settings, color: Color(0xFF795548), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final isDisabled = _isRecording;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: isDisabled ? null : _createMemoEntry,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDisabled ? const Color(0xFFE0DBD0) : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF795548).withOpacity(isDisabled ? 0.08 : 0.15),
                ),
              ),
              child: Icon(
                Icons.note_alt_rounded,
                color: isDisabled ? const Color(0xFF795548).withOpacity(0.3) : const Color(0xFF795548),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 20),
          RecordingButton(
            isRecording: _isRecording,
            onPressed: _toggleRecording,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildTagSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선택된 태그들 + 검색창
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface, // 카드 배경
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 선택된 태그들
                if (_selectedTagIds.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTagIds.map((id) {
                      final tag = _tags.firstWhere((t) => t.id == id, orElse: () => _tags.first);
                      if (!_tags.any((t) => t.id == id)) return const SizedBox.shrink();
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: tag.color,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tag.name, style: const TextStyle(color: Color(0xFF4E342E), fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _removeTagFilter(id),
                              child: const Icon(Icons.close, color: Color(0xFF795548), size: 14),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // 검색 입력
                Row(
                  children: [
                    Icon(Icons.search, color: const Color(0xFF795548).withOpacity(0.5), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        focusNode: _searchFocus,
                        style: const TextStyle(color: Color(0xFF4E342E), fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '태그 검색 후 엔터로 추가...',
                          hintStyle: TextStyle(color: const Color(0xFF795548).withOpacity(0.5)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v),
                        onSubmitted: (v) async {
                          final query = v.trim();
                          if (query.isEmpty) return;

                          final exact = _findExactTag(query);
                          if (exact != null) {
                            if (!_selectedTagIds.contains(exact.id)) {
                              _addTagFilter(exact.id);
                            }
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                            return;
                          }

                          final confirm = await _confirmAddTag(query);
                          if (confirm && mounted) {
                            await _createTagFromSearch(query);
                          }
                        },
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(Icons.close, color: const Color(0xFF795548).withOpacity(0.6), size: 16),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // 검색 결과 드롭다운
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _searchResults.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('검색 결과 없음', style: TextStyle(color: const Color(0xFF795548).withOpacity(0.4), fontSize: 13)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _searchResults.length,
                      itemBuilder: (_, i) {
                        final tag = _searchResults[i];
                        final isSelected = _selectedTagIds.contains(tag.id);
                        return GestureDetector(
                          onTap: () {
                            if (!isSelected) {
                              _addTagFilter(tag.id);
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            color: isSelected ? tag.color.withOpacity(0.1) : Colors.transparent,
                            child: Row(
                              children: [
                                Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(color: tag.color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    tag.name,
                                    style: TextStyle(
                                      color: isSelected ? tag.color : const Color(0xFF4E342E),
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check, color: tag.color, size: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_outlined, size: 64, color: const Color(0xFF795548).withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            _selectedTagIds.isNotEmpty ? '조건에 맞는 녹음이 없어요' : '첫 녹음을 시작해보세요',
            style: TextStyle(color: const Color(0xFF795548).withOpacity(0.4), fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingList() {
    final pinned = _filteredRecordings.where((r) => r.isPinned).toList();
    final unpinned = _filteredRecordings.where((r) => !r.isPinned).toList();
    final grouped = _groupByDate(unpinned);
    final dateKeys = grouped.keys.toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // 고정된 메모 섹션
        if (pinned.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
            child: Row(
              children: [
                Icon(Icons.push_pin, color: const Color(0xFFD4A574), size: 16),
                const SizedBox(width: 6),
                Text(
                  '고정됨',
                  style: TextStyle(color: const Color(0xFFD4A574), fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          ...pinned.map((recording) => _buildRecordingCard(recording)),
          const SizedBox(height: 8),
        ],

        // 일반 메모 (날짜별)
        ...dateKeys.map((dateKey) {
          final recordings = grouped[dateKey]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
                child: Text(
                  dateKey,
                  style: TextStyle(color: const Color(0xFF795548).withOpacity(0.6), fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              ...recordings.map((recording) => _buildRecordingCard(recording)),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildRecordingCard(Recording recording) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RecordingCard(
        recording: recording,
        tags: _tags,
        isPlaying: _audioService.currentPlayingId == recording.id,
        onTap: () => _openRecordingDetail(recording),
        onPlayTap: () => _togglePlay(recording),
        onDelete: () => _deleteRecording(recording),
        onPin: () => _togglePin(recording),
        displayMemo: _getDisplayMemo(recording),
        onChecklistToggle: (lineIndex, isDone) => _toggleChecklistInMemo(
          recording,
          _getDisplayMemo(recording),
          lineIndex,
          isDone,
        ),
      ),
    );
  }

  Map<String, List<Recording>> _groupByDate(List<Recording> recordings) {
    final grouped = <String, List<Recording>>{};
    final dateFormat = DateFormat('M월 d일 (E)', 'ko');
    for (final recording in recordings) {
      final dateKey = dateFormat.format(recording.createdAt);
      grouped.putIfAbsent(dateKey, () => []).add(recording);
    }
    return grouped;
  }
}
