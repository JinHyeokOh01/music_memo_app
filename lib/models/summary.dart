import 'package:hive/hive.dart';

part 'summary.g.dart';

@HiveType(typeId: 0)
enum SummaryType {
  @HiveField(0)
  daily,
  @HiveField(1)
  weekly,
  @HiveField(2)
  monthly,
}

@HiveType(typeId: 1)
class Summary extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final SummaryType type;

  /// 요약의 기준이 되는 날짜 (일간: 해당 날짜, 주간: 그 주의 월요일, 월간: 해당 월의 1일)
  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final DateTime createdAt;

  Summary({
    required this.id,
    required this.type,
    required this.date,
    required this.content,
    required this.createdAt,
  });
}
