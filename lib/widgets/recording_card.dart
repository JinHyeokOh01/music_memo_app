import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
          color: recording.isPinned ? const Color(0xFFC5A059) : const Color(0xFF444444),
          borderRadius: BorderRadius.circular(16),
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
          color: const Color(0xFFE53935), // 더 강렬한 레드
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              // 아이콘 (재생/정지 또는 메모)
              GestureDetector(
                onTap: isMemoOnly ? null : onPlayTap,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isMemoOnly 
                        ? const Color(0xFFC5A059).withOpacity(0.15) 
                        : const Color(0xFF800020).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isMemoOnly
                        ? Icons.edit_rounded
                        : (isPlaying ? Icons.pause_rounded : Icons.graphic_eq_rounded),
                    color: isMemoOnly ? const Color(0xFFC5A059) : const Color(0xFFE53935), // 버건디/레드 혹은 골드
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // 콘텐츠 (제목 + 첫번째 태그 일부)
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        recording.displayTitle,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // 시간 (또는 녹음 길이) 및 삭제 버튼
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMemoOnly) ...[
                    Text(
                      recording.durationString,
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFF666666),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
