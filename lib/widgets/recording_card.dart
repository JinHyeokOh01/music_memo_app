import 'package:flutter/material.dart';
import '../models/recording.dart';
import '../models/tag.dart';

/// 녹음 카드 위젯
/// 각 녹음 항목을 표시하는 카드
class RecordingCard extends StatelessWidget {
  final Recording recording;
  final List<Tag> tags;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlayTap;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final String displayMemo;
  final void Function(int lineIndex, bool isDone)? onChecklistToggle;

  const RecordingCard({
    super.key,
    required this.recording,
    required this.tags,
    required this.isPlaying,
    required this.onTap,
    required this.onPlayTap,
    required this.onDelete,
    required this.onPin,
    required this.displayMemo,
    this.onChecklistToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isMemoOnly = recording.isMemoOnly;
    final memoPreview = _buildMemoPreview(displayMemo, recording);
    return Dismissible(
      key: Key(recording.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // 삭제 확인
          return true;
        } else if (direction == DismissDirection.startToEnd) {
          // 고정/해제 - 삭제하지 않음
          onPin();
          return false;
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: recording.isPinned ? const Color(0xFF5D4037) : Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              recording.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              recording.isPinned ? '고정 해제' : '고정',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // 재생 버튼
              if (isMemoOnly)
                _MemoIcon()
              else
                _PlayButton(
                  isPlaying: isPlaying,
                  onTap: onPlayTap,
                ),
              const SizedBox(width: 12),

              // 녹음 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 & 시간
                    Row(
                      children: [
                        Text(
                          recording.displayTitle,
                          style: const TextStyle(
                            color: Color(0xFF4E342E),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isMemoOnly)
                          Text(
                            '메모',
                            style: TextStyle(
                              color: const Color(0xFF795548).withOpacity(0.6),
                              fontSize: 13,
                            ),
                          )
                        else
                          Text(
                            recording.durationString,
                            style: TextStyle(
                              color: const Color(0xFF795548).withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),

                    // 메모
                    if (memoPreview.text.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      ...memoPreview.lines.map((line) => _buildMemoLine(line, context)),
                    ],

                    // 태그들
                    if (recording.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: recording.tags.map((tagId) {
                          final tag = tags.firstWhere(
                            (t) => t.id == tagId,
                            orElse: () => Tag(
                              id: tagId,
                              name: tagId,
                              color: Colors.grey,
                            ),
                          );
                          return _TagChip(tag: tag);
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // 삭제 버튼
              GestureDetector(
                onTap: () {
                  onDelete();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.delete_outline,
                    color: const Color(0xFF795548).withOpacity(0.5),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoLine(_MemoLine line, BuildContext context) {
    if (line.isChecklist) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: line.isDone,
            activeColor: Theme.of(context).primaryColor,
            checkColor: Colors.white,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: onChecklistToggle == null
                ? null
                : (value) => onChecklistToggle?.call(line.toggleIndex, value ?? false),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 6),
              child: Text(
                line.text,
                style: TextStyle(
                  color: line.isDone ? const Color(0xFF4E342E).withOpacity(0.4) : const Color(0xFF4E342E),
                  fontSize: 14,
                  decoration: line.isDone ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        line.text,
        style: TextStyle(color: const Color(0xFF795548).withOpacity(0.8), fontSize: 14),
      ),
    );
  }
}

class _MemoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.note_rounded,
        color: const Color(0xFF795548).withOpacity(0.8),
        size: 22,
      ),
    );
  }
}

/// 재생 버튼
class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;

  const _PlayButton({
    required this.isPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPlaying
              ? Theme.of(context).primaryColor
              : Theme.of(context).inputDecorationTheme.fillColor,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.stop : Icons.play_arrow,
          color: isPlaying ? Colors.white : const Color(0xFF795548),
          size: 24,
        ),
      ),
    );
  }
}

/// 태그 칩
class _TagChip extends StatelessWidget {
  final Tag tag;

  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: tag.color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        tag.name,
        style: TextStyle(
          color: tag.color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MemoPreview {
  final String text;
  final List<_MemoLine> lines;

  const _MemoPreview({required this.text, required this.lines});
}

class _MemoLine {
  final int toggleIndex;
  final String text;
  final bool isChecklist;
  final bool isDone;

  const _MemoLine({
    required this.toggleIndex,
    required this.text,
    required this.isChecklist,
    required this.isDone,
  });
}

_MemoPreview _buildMemoPreview(String memoText, Recording recording) {
  final memo = memoText.trimRight();
  final lines = <String>[];
  final previewLines = <_MemoLine>[];
  var hasChecklist = false;

  if (memo.isNotEmpty) {
    final memoLines = memo.split('\n');
    for (var i = 0; i < memoLines.length; i++) {
      final line = memoLines[i];
      final match = Recording.checklistLinePattern.firstMatch(line);
      if (match != null) {
        final text = (match.group(2) ?? '').trim();
        if (text.isEmpty) continue;
        final mark = (match.group(1) ?? ' ').toLowerCase() == 'x' ? 'x' : ' ';
        lines.add('- [$mark] $text');
        previewLines.add(_MemoLine(
          toggleIndex: i,
          text: text,
          isChecklist: true,
          isDone: mark == 'x',
        ));
        hasChecklist = true;
      } else {
        final text = line.trim();
        if (text.isEmpty) continue;
        lines.add(text);
        previewLines.add(_MemoLine(
          toggleIndex: i,
          text: text,
          isChecklist: false,
          isDone: false,
        ));
      }
    }
  }

  if (!hasChecklist && recording.checklist.isNotEmpty) {
    for (var i = 0; i < recording.checklist.length; i++) {
      final item = recording.checklist[i];
      final text = item.text.trim();
      if (text.isEmpty) continue;
      lines.add(Recording.buildChecklistLine(item));
      previewLines.add(_MemoLine(
        toggleIndex: -1 - i,
        text: text,
        isChecklist: true,
        isDone: item.isDone,
      ));
    }
    hasChecklist = recording.checklist.isNotEmpty;
  }

  return _MemoPreview(text: lines.join('\n'), lines: previewLines);
}
