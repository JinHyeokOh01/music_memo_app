import 'package:flutter/material.dart';
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
    final dateFormat = DateFormat('M월 d일 (E)', 'ko');
    switch (_tabController.index) {
      case 0:
        return dateFormat.format(_selectedDate);
      case 1:
        // Weekly range logic (Monday to Sunday)
        final diff = _selectedDate.weekday - 1;
        final start = _selectedDate.subtract(Duration(days: diff));
        final end = start.add(const Duration(days: 6));
        return '${DateFormat('M.d').format(start)} ~ ${DateFormat('M.d').format(end)}';
      case 2:
        return DateFormat('yyyy년 M월').format(_selectedDate);
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
        backgroundColor: const Color(0xFF2D241F),
        title: const Text('OpenAI API Key 설정', style: TextStyle(color: Color(0xFFF5E6D3))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '요약 기능을 사용하려면 OpenAI API Key가 필요합니다. 키는 로컬에 안전하게 저장됩니다.',
              style: TextStyle(color: Color(0xFFC9B8A3), fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'sk-...',
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF3E3129),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await widget.openAIService.setApiKey(controller.text.trim());
              if (mounted) {
                Navigator.pop(context);
                _loadSummary(); // Retry loading with new key
              }
            },
            child: const Text('저장', style: TextStyle(color: Color(0xFFD4A574))),
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
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _isLoading ? null : () => _changeDate(-1),
                color: const Color(0xFF795548),
              ),
              Expanded(
                child: Text(
                  _getDateRangeString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4E342E),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _isLoading ? null : () => _changeDate(1),
                color: const Color(0xFF795548),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showApiKeyDialog,
                color: const Color(0xFF795548),
              ),
            ],
          ),
        ),

        // 탭 바
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFEFEBE0),
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Theme.of(context).primaryColor,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF795548),
            dividerColor: Colors.transparent,
            overlayColor: MaterialStateProperty.all(Colors.transparent),
            tabs: const [
              Tab(text: '일간'),
              Tab(text: '주간'),
              Tab(text: '월간'),
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
                          style: TextStyle(color: const Color(0xFF795548).withOpacity(0.8)),
                        ),
                        const SizedBox(height: 24),
                        if (_errorMessage!.contains('API Key') || _errorMessage!.contains('429')) // 429 에러도 키 설정 버튼 나오게 수정
                          ElevatedButton(
                            onPressed: _showApiKeyDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('API Key 설정하기'),
                          )
                        else
                          ElevatedButton(
                            onPressed: _loadSummary,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4A574),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('다시 시도'),
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
