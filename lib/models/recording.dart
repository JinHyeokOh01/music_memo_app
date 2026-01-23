/// 녹음 데이터 모델
/// 각 녹음의 정보를 담는 클래스
class Recording {
  static final RegExp checklistLinePattern = RegExp(r'^\s*(?:-\s*)?\[( |x|X)\]\s+(.*)$');

  final String id;
  final String filePath;
  final DateTime createdAt;
  final Duration duration;
  String title;
  String memo;
  List<String> tags;
  List<ChecklistItem> checklist;
  bool isPinned;

  Recording({
    required this.id,
    required this.filePath,
    required this.createdAt,
    required this.duration,
    this.title = '',
    this.memo = '',
    List<String>? tags,
    List<ChecklistItem>? checklist,
    this.isPinned = false,
  })  : tags = tags ?? [],
        checklist = checklist ?? [];

  /// JSON으로 변환 (저장용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'filePath': filePath,
      'createdAt': createdAt.toIso8601String(),
      'duration': duration.inMilliseconds,
      'title': title,
      'memo': memo,
      'tags': tags,
      'checklist': checklist.map((item) => item.toJson()).toList(),
      'isPinned': isPinned,
    };
  }

  /// JSON에서 생성 (불러오기용)
  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] as String,
      filePath: json['filePath'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      duration: Duration(milliseconds: json['duration'] as int),
      title: json['title'] as String? ?? '',
      memo: json['memo'] as String? ?? '',
      tags: List<String>.from(json['tags'] as List? ?? []),
      checklist: _parseChecklist(json['checklist']),
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  /// 표시용 제목 (제목이 없으면 시간으로 표시)
  String get displayTitle {
    if (title.isNotEmpty) return title;
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 녹음 길이를 문자열로 표시 (예: "1:23")
  String get durationString {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool get isMemoOnly => filePath.isEmpty;

  static bool memoHasChecklist(String memo) {
    for (final line in memo.split('\n')) {
      if (checklistLinePattern.hasMatch(line)) return true;
    }
    return false;
  }

  static List<ChecklistItem> checklistFromMemo(String memo) {
    final items = <ChecklistItem>[];
    final lines = memo.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final match = checklistLinePattern.firstMatch(lines[i]);
      if (match == null) continue;
      final text = (match.group(2) ?? '').trim();
      if (text.isEmpty) continue;
      final mark = match.group(1) ?? ' ';
      items.add(ChecklistItem(
        id: 'memo-$i',
        text: text,
        isDone: mark.toLowerCase() == 'x',
      ));
    }
    return items;
  }

  static String buildChecklistLine(ChecklistItem item) {
    final mark = item.isDone ? 'x' : ' ';
    return '- [$mark] ${item.text}';
  }

  static String mergeChecklistIntoMemo(String memo, List<ChecklistItem> checklist) {
    if (checklist.isEmpty) return memo;
    final buffer = StringBuffer(memo.trimRight());
    if (buffer.isNotEmpty) buffer.writeln();
    for (final item in checklist) {
      final text = item.text.trim();
      if (text.isEmpty) continue;
      buffer.writeln(buildChecklistLine(item));
    }
    return buffer.toString().trimRight();
  }

  /// 복사본 생성 (수정용)
  Recording copyWith({
    String? id,
    String? filePath,
    DateTime? createdAt,
    Duration? duration,
    String? title,
    String? memo,
    List<String>? tags,
    List<ChecklistItem>? checklist,
    bool? isPinned,
  }) {
    return Recording(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt ?? this.createdAt,
      duration: duration ?? this.duration,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      tags: tags ?? List.from(this.tags),
      checklist: checklist ?? List.from(this.checklist),
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

class ChecklistItem {
  final String id;
  final String text;
  final bool isDone;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  ChecklistItem copyWith({
    String? id,
    String? text,
    bool? isDone,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isDone': isDone,
  };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] as String? ?? '',
      isDone: json['isDone'] as bool? ?? false,
    );
  }
}

List<ChecklistItem> _parseChecklist(dynamic raw) {
  if (raw is! List) return [];
  final items = <ChecklistItem>[];
  for (final entry in raw) {
    if (entry is Map<String, dynamic>) {
      items.add(ChecklistItem.fromJson(entry));
    } else if (entry is Map) {
      items.add(ChecklistItem.fromJson(entry.cast<String, dynamic>()));
    } else if (entry is String) {
      items.add(ChecklistItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: entry,
      ));
    }
  }
  return items.where((item) => item.text.trim().isNotEmpty).toList();
}
