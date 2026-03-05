import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/summary.dart';
import '../services/summary_service.dart';
import '../services/openai_service.dart';
import '../widgets/summary_view.dart';

class SummaryScreen extends StatefulWidget {
  final SummaryService summaryService;
  final OpenAIService openAIService;

  const SummaryScreen({
    super.key,
    required this.summaryService,
    required this.openAIService,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  
  bool _isLoading = false;
  String _summaryContent = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadSummary();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _summaryContent = '';
    });

    try {
      Summary summary;
      switch (_tabController.index) {
        case 0:
          summary = await widget.summaryService.getDailySummary(_selectedDate);
          break;
        case 1:
          summary = await widget.summaryService.getWeeklySummary(_selectedDate);
          break;
        case 2:
          summary = await widget.summaryService.getMonthlySummary(_selectedDate);
          break;
        default:
          throw Exception('잘못된 탭 인덱스');
      }
      
      setState(() {
        _summaryContent = summary.content;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _changeDate(int offset) {
    setState(() {
      switch (_tabController.index) {
        case 0: // Daily
          _selectedDate = _selectedDate.add(Duration(days: offset));
          break;
        case 1: // Weekly
          _selectedDate = _selectedDate.add(Duration(days: offset * 7));
          break;
        case 2: // Monthly
          _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + offset, 1);
          break;
      }
    });
    _loadSummary();
  }

  String _getDateRangeString() {
    switch (_tabController.index) {
      case 0:
        return DateFormat('MMM d, yyyy').format(_selectedDate);
      case 1:
        // Weekly range logic (Monday to Sunday)
        final diff = _selectedDate.weekday - 1;
        final start = _selectedDate.subtract(Duration(days: diff));
        final end = start.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}';
      case 2:
        return DateFormat('MMMM yyyy').format(_selectedDate);
      default:
        return '';
    }
  }

  Future<void> _showApiKeyDialog() async {
    final TextEditingController controller = TextEditingController();
    final currentKey = await widget.openAIService.getApiKey();
    controller.text = currentKey ?? '';

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        title: Text('OpenAI API Key', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'An API key is required to generate summaries. Your key is securely stored locally.',
              style: GoogleFonts.inter(color: const Color(0xFF888888), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'sk-...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF666666)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () async {
              await widget.openAIService.setApiKey(controller.text.trim());
              if (!context.mounted) return;
              Navigator.pop(context);
              _loadSummary(); // Retry loading with new key
            },
            child: Text('Save', style: GoogleFonts.inter(color: const Color(0xFFC5A059), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단 바 (날짜 이동 & 설정)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _isLoading ? null : () => _changeDate(-1),
                color: const Color(0xFF888888),
              ),
              Expanded(
                child: Text(
                  _getDateRangeString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _isLoading ? null : () => _changeDate(1),
                color: const Color(0xFF888888),
              ),
            ],
          ),
        ),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TabBar(
            controller: _tabController,
            labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
            indicatorColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF888888),
            dividerColor: Colors.transparent,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            tabs: const [
              Tab(text: 'Daily'),
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
            ],
          ),
        ),
        
        const SizedBox(height: 10),

        // 요약 내용
        Expanded(
          child: _errorMessage != null
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: const Color(0xFFD32F2F).withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF888888)),
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage!.contains('API Key') || _errorMessage!.contains('429'))
                          ElevatedButton(
                            onPressed: _showApiKeyDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF800020),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text('Set API Key', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          )
                        else
                          ElevatedButton(
                            onPressed: _loadSummary,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text('Retry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                )
              : SummaryView(
                  content: _summaryContent,
                  isLoading: _isLoading,
                ),
        ),
      ],
    );
  }
}
