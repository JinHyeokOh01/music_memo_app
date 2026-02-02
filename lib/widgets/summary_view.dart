import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

class SummaryView extends StatelessWidget {
  final String content;
  final bool isLoading;

  const SummaryView({
    super.key,
    required this.content,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFD4A574)),
            SizedBox(height: 16),
            Text('요약을 생성하고 있어요...', style: TextStyle(color: Color(0xFF795548))),
            Text('GPT-4o-mini가 연습 기록을 분석 중입니다.', style: TextStyle(color: Color(0xFFA1887F), fontSize: 12)),
          ],
        ),
      );
    }

    if (content.isEmpty) {
      return Center(
        child: Text(
          '요약할 내용이 없어요.',
          style: TextStyle(color: const Color(0xFF795548).withOpacity(0.5)),
        ),
      );
    }

    return MarkdownWidget(
      data: content,
      shrinkWrap: false,
      padding: const EdgeInsets.all(20),
      config: MarkdownConfig(
        configs: [
          const PConfig(
            textStyle: TextStyle(fontSize: 16, height: 1.6, color: Color(0xFF4E342E)),
          ),
          const H1Config(
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4E342E)),
          ),
          const H2Config(
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5D4037)),
          ),
          const H3Config(
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF6D4C41)),
          ),
          const ListConfig(
            marginLeft: 8,
          ),
        ],
      ),
    );
  }
}
