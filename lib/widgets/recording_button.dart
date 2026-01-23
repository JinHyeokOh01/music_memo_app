import 'package:flutter/material.dart';

/// 녹음 버튼 위젯
/// 화면 하단의 큰 녹음 버튼
class RecordingButton extends StatelessWidget {
  final bool isRecording;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;

  const RecordingButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Center(
        child: GestureDetector(
          onTap: onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isRecording ? 72 : 64,
            height: isRecording ? 72 : 64,
            decoration: BoxDecoration(
              color: isRecording
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFF30D158),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isRecording
                      ? const Color(0xFFFF3B30)
                      : const Color(0xFF30D158))
                      .withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isRecording
                    ? const Icon(
                        Icons.stop_rounded,
                        key: ValueKey('stop'),
                        color: Colors.white,
                        size: 32,
                      )
                    : const Icon(
                        Icons.mic,
                        key: ValueKey('mic'),
                        color: Colors.white,
                        size: 28,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
