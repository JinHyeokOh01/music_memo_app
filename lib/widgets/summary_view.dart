import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF800020)),
            const SizedBox(height: 16),
            Text('Generating summary...', style: GoogleFonts.inter(color: const Color(0xFF888888))),
            Text('GPT is analyzing your practice sessions.', style: GoogleFonts.inter(color: const Color(0xFF666666), fontSize: 12)),
          ],
        ),
      );
    }

    if (content.isEmpty) {
      return Center(
        child: Text(
          'Nothing to summarize.',
          style: GoogleFonts.inter(color: const Color(0xFF888888)),
        ),
      );
    }

    return MarkdownWidget(
      data: content,
      shrinkWrap: false,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      config: MarkdownConfig(
        configs: [
          PConfig(
            textStyle: GoogleFonts.inter(fontSize: 15, height: 1.6, color: const Color(0xFFE0E0E0)),
          ),
          H1Config(
            style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
          ),
          H2Config(
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.5),
          ),
          H3Config(
            style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.5),
          ),
          const ListConfig(
            marginLeft: 8,
          ),
        ],
      ),
    );
  }
}
