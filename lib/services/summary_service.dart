import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/summary.dart';
import '../models/recording.dart';
import '../models/tag.dart';
import 'storage_service.dart';
import 'openai_service.dart';

class SummaryService {
  static const String _boxName = 'summaries';
  final StorageService _storageService;
  final OpenAIService _openAIService;

  SummaryService({
    required StorageService storageService,
    required OpenAIService openAIService,
  })  : _storageService = storageService,
        _openAIService = openAIService;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Summary>(_boxName);
    }
  }

  Box<Summary> get _box => Hive.box<Summary>(_boxName);

  /// 일간 요약 조회 (없으면 생성)
  Future<Summary> getDailySummary(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    
    // 1. 캐시 확인
    final cached = _findSummary(SummaryType.daily, normalizedDate);
    if (cached != null) return cached;

    // 2. 해당 날짜의 녹음 데이터 조회
    final recordings = await _getRecordingsForDate(normalizedDate);
    if (recordings.isEmpty) {
      throw Exception('해당 날짜에 연습 기록이 없습니다.');
    }

    // 3. 프롬프트 생성
    final prompt = _buildDailyPrompt(normalizedDate, recordings);

    // 4. OpenAI 호출
    final content = await _openAIService.generateSummary(prompt);

    // 5. 저장 및 반환
    final summary = Summary(
      id: const Uuid().v4(),
      type: SummaryType.daily,
      date: normalizedDate,
      content: content,
      createdAt: DateTime.now(),
    );

    await _box.add(summary);
    return summary;
  }

  /// 주간 요약 조회 (없으면 생성)
  Future<Summary> getWeeklySummary(DateTime date) async {
    final startOfWeek = _getStartOfWeek(date);
    
    // 1. 캐시 확인
    final cached = _findSummary(SummaryType.weekly, startOfWeek);
    if (cached != null) return cached;

    // 2. 해당 주간의 일간 요약들 조회 (또는 녹음들 직접 조회)
    // 여기서는 녹음들을 직접 조회하여 컨텍스트로 제공
    final recordings = await _getRecordingsForRange(
      startOfWeek, 
      startOfWeek.add(const Duration(days: 6))
    );
    
    if (recordings.isEmpty) {
      throw Exception('해당 주간에 연습 기록이 없습니다.');
    }

    // 3. 프롬프트 생성
    final prompt = _buildWeeklyPrompt(startOfWeek, recordings);

    // 4. OpenAI 호출
    final content = await _openAIService.generateSummary(prompt);

    // 5. 저장 및 반환
    final summary = Summary(
      id: const Uuid().v4(),
      type: SummaryType.weekly,
      date: startOfWeek,
      content: content,
      createdAt: DateTime.now(),
    );

    await _box.add(summary);
    return summary;
  }

  /// 월간 요약 조회 (없으면 생성)
  Future<Summary> getMonthlySummary(DateTime date) async {
    final startOfMonth = DateTime(date.year, date.month, 1);
    
    // 1. 캐시 확인
    final cached = _findSummary(SummaryType.monthly, startOfMonth);
    if (cached != null) return cached;

    // 2. 해당 월의 녹음 데이터 조회
    final nextMonth = DateTime(date.year, date.month + 1, 1);
    final lastDayOfMonth = nextMonth.subtract(const Duration(days: 1));
    
    final recordings = await _getRecordingsForRange(startOfMonth, lastDayOfMonth);
    
    if (recordings.isEmpty) {
      throw Exception('해당 월에 연습 기록이 없습니다.');
    }

    // 3. 프롬프트 생성
    final prompt = _buildMonthlyPrompt(startOfMonth, recordings);

    // 4. OpenAI 호출
    final content = await _openAIService.generateSummary(prompt);

    // 5. 저장 및 반환
    final summary = Summary(
      id: const Uuid().v4(),
      type: SummaryType.monthly,
      date: startOfMonth,
      content: content,
      createdAt: DateTime.now(),
    );

    await _box.add(summary);
    return summary;
  }

  // --- Helper Methods ---

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _getStartOfWeek(DateTime date) {
    // 월요일을 시작으로 간주
    final diff = date.weekday - 1;
    final start = date.subtract(Duration(days: diff));
    return DateTime(start.year, start.month, start.day);
  }

  Summary? _findSummary(SummaryType type, DateTime date) {
    try {
      return _box.values.firstWhere(
        (s) => s.type == type && s.date.isAtSameMomentAs(date)
      );
    } catch (e) {
      return null;
    }
  }

  Future<List<Recording>> _getRecordingsForDate(DateTime date) async {
    final allRecordings = await _storageService.loadRecordings();
    final targetDate = _normalizeDate(date);
    
    return allRecordings.where((r) {
      final rDate = _normalizeDate(r.createdAt);
      return rDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  Future<List<Recording>> _getRecordingsForRange(DateTime start, DateTime end) async {
    final allRecordings = await _storageService.loadRecordings();
    final startDate = _normalizeDate(start);
    final endDate = _normalizeDate(end).add(const Duration(days: 1)).subtract(const Duration(seconds: 1));
    
    return allRecordings.where((r) {
      return r.createdAt.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
             r.createdAt.isBefore(endDate);
    }).toList();
  }

  // --- Prompt Builders ---

  String _buildDailyPrompt(DateTime date, List<Recording> recordings) {
    final dateStr = DateFormat('yyyy년 M월 d일', 'ko').format(date);
    final sb = StringBuffer();
    sb.writeln('$dateStr 연습 요약 요청');
    sb.writeln('총 ${recordings.length}개의 연습 세션이 있었습니다.');
    sb.writeln('---');
    
    for (var i = 0; i < recordings.length; i++) {
      final r = recordings[i];
      sb.writeln('세션 ${i + 1}:');
      sb.writeln('- 제목: ${r.title.isEmpty ? '(제목 없음)' : r.title}');
      sb.writeln('- 시간: ${DateFormat('HH:mm').format(r.createdAt)}');
      sb.writeln('- 길이: ${r.durationString}');
      if (r.tags.isNotEmpty) sb.writeln('- 태그: ${r.tags.join(", ")}');
      if (r.memo.isNotEmpty) sb.writeln('- 메모: ${r.memo}');
      if (r.checklist.isNotEmpty) {
        sb.writeln('- 체크리스트:');
        for (final item in r.checklist) {
          sb.writeln('  - [${item.isDone ? "완료" : "미완료"}] ${item.text}');
        }
      }
      sb.writeln('');
    }
    sb.writeln('---');
    sb.writeln('위 연습 기록들을 바탕으로 오늘 연습의 주요 내용, 잘한 점, 개선할 점을 포함한 일간 요약을 작성해줘. 마크다운 형식을 사용해줘.');
    
    return sb.toString();
  }

  String _buildWeeklyPrompt(DateTime startOfWeek, List<Recording> recordings) {
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    final dateRange = '${DateFormat('M월 d일').format(startOfWeek)} ~ ${DateFormat('M월 d일').format(endOfWeek)}';
    
    final sb = StringBuffer();
    sb.writeln('$dateRange 주간 연습 요약 요청');
    sb.writeln('총 ${recordings.length}개의 연습 세션이 있었습니다.');
    
    // 태그 통계
    final tagCounts = <String, int>{};
    for (final r in recordings) {
      for (final t in r.tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    if (tagCounts.isNotEmpty) {
      sb.writeln('- 주요 연습 태그: ${tagCounts.entries.map((e) => "${e.key}(${e.value}회)").join(", ")}');
    }

    sb.writeln('---');
    sb.writeln('모든 세션의 세부 내용을 나열하기보다, 전체적인 연습 경향과 성과를 분석해줘.');
    sb.writeln('다음은 각 세션의 간략한 정보야:');
    
    for (final r in recordings) {
      sb.write('- ${DateFormat('M/d HH:mm').format(r.createdAt)}: ');
      if (r.title.isNotEmpty) sb.write('[${r.title}] ');
      if (r.tags.isNotEmpty) sb.write('(${r.tags.join(", ")}) ');
      if (r.memo.isNotEmpty) sb.write('메모: "${r.memo.replaceAll('\n', ' ').substring(0, r.memo.length > 30 ? 30 : r.memo.length)}..."');
      sb.writeln();
    }
    sb.writeln('---');
    sb.writeln('위 정보를 바탕으로 이번 주 연습의 성과를 분석하고, 다음 주를 위한 조언을 포함한 주간 요약을 작성해줘.');

    return sb.toString();
  }

  String _buildMonthlyPrompt(DateTime startOfMonth, List<Recording> recordings) {
    final monthStr = DateFormat('yyyy년 M월').format(startOfMonth);
    
    final sb = StringBuffer();
    sb.writeln('$monthStr 월간 연습 요약 요청');
    sb.writeln('총 ${recordings.length}개의 연습 세션이 있었습니다.');
    
    // 태그 통계
    final tagCounts = <String, int>{};
    for (final r in recordings) {
      for (final t in r.tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    if (tagCounts.isNotEmpty) {
      sb.writeln('- 이달의 주요 연습 태그: ${tagCounts.entries.map((e) => "${e.key}(${e.value}회)").join(", ")}');
    }

    sb.writeln('---');
    sb.writeln('이 달의 연습 패턴과 성장을 분석해줘.');
    sb.writeln('다음은 날짜별 연습 횟수와 주요 태그야:');
    
    // 날짜별 그룹화
    final byDate = <String, List<Recording>>{};
    for (final r in recordings) {
      final key = DateFormat('M/d').format(r.createdAt);
      byDate.putIfAbsent(key, () => []).add(r);
    }
    
    for (final entry in byDate.entries) {
      final tags = entry.value.expand((r) => r.tags).toSet().join(", ");
      sb.writeln('- ${entry.key}: ${entry.value.length}회 연습 ${tags.isNotEmpty ? "($tags)" : ""}');
    }
    
    sb.writeln('---');
    sb.writeln('위 정보를 바탕으로 이 달의 연습 성취를 칭찬하고, 전반적인 성장 추세를 분석한 월간 요약을 작성해줘.');

    return sb.toString();
  }
}
