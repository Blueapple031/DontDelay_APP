import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TodoStatus { todo, inProgress, done }
enum TodoPriority { high, medium, low }

enum RepeatType { none, daily, weekly, monthly, yearly, weekdays }

extension RepeatTypeLabel on RepeatType {
  String get label => switch (this) {
        RepeatType.none => '반복 안함',
        RepeatType.daily => '매일',
        RepeatType.weekly => '매주',
        RepeatType.monthly => '매월',
        RepeatType.yearly => '매년',
        RepeatType.weekdays => '요일',
      };
}

class TodoItem {
  final String id;
  final String title;
  final String date; // "yyyy-MM-dd"
  final TodoPriority priority;
  final String tag; // TagItem.id 참조
  final TodoStatus status;
  final int urgency;
  final int importance;
  final DateTime createdAt;
  final TodoStatus? previousStatus;

  // ── 추가 필드 ──────────────────────────────────────────────────────
  final String? time; // "HH:mm", null이면 미지정
  final String? memo;
  final RepeatType repeat;
  final List<int> repeatWeekdays; // RepeatType.weekdays 일 때 [1=월~7=일]
  final String? repeatGroupId; // 반복 그룹 UUID
  /// ISO datetime "yyyy-MM-ddTHH:mm" 형식. null이면 알람 없음.
  final String? alarmTime;

  // ── 동적 반복 렌더링용 override 필드 ──────────────────────────────
  final Set<String> doneOverrides; // done 처리된 날짜 {"yyyy-MM-dd"}
  final Set<String> deletedOverrides; // 삭제된 날짜 {"yyyy-MM-dd"}
  final String? repeatEndDate; // 이 날짜 이후로 반복 표시 안 함 "yyyy-MM-dd"

  TodoItem({
    String? id,
    required this.title,
    required this.date,
    required this.priority,
    required this.tag,
    required this.status,
    DateTime? createdAt,
    int? urgency,
    int? importance,
    this.previousStatus,
    this.time,
    this.memo,
    this.repeat = RepeatType.none,
    List<int>? repeatWeekdays,
    this.repeatGroupId,
    this.alarmTime,
    Set<String>? doneOverrides,
    Set<String>? deletedOverrides,
    this.repeatEndDate,
  })  : id = id ?? _uuid.v4(),
        urgency = urgency != null
            ? urgency.clamp(1, 8).toInt()
            : TodoItem.defaultsForPriority(priority).$1,
        importance = importance != null
            ? importance.clamp(1, 8).toInt()
            : TodoItem.defaultsForPriority(priority).$2,
        createdAt = createdAt ?? DateTime.now(),
        repeatWeekdays = repeatWeekdays ?? const [],
        doneOverrides = doneOverrides ?? const {},
        deletedOverrides = deletedOverrides ?? const {};

  static (int, int) defaultsForPriority(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:
        return (8, 8);
      case TodoPriority.medium:
        return (5, 5);
      case TodoPriority.low:
        return (2, 2);
    }
  }

  static int _readIntField(dynamic raw, int fallback) {
    if (raw is int) return raw.clamp(1, 8).toInt();
    if (raw is num) return raw.round().clamp(1, 8).toInt();
    return fallback;
  }

  static String fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── 동적 반복 렌더링 헬퍼 ──────────────────────────────────────────

  /// 이 task 가 [date] 에 표시되어야 하는지 계산.
  bool isActiveOnDate(DateTime date) {
    final dateKey = fmtDate(date);

    if (deletedOverrides.contains(dateKey)) return false;

    if (repeatEndDate != null) {
      final endDt = DateTime.tryParse(repeatEndDate!);
      if (endDt != null) {
        final endDay = DateTime(endDt.year, endDt.month, endDt.day);
        final targetDay = DateTime(date.year, date.month, date.day);
        if (!targetDay.isBefore(endDay)) return false;
      }
    }

    final start = DateTime.tryParse(this.date);
    if (start == null) return false;

    final startDay = DateTime(start.year, start.month, start.day);
    final targetDay = DateTime(date.year, date.month, date.day);
    if (targetDay.isBefore(startDay)) return false;

    if (repeat == RepeatType.none) return this.date == dateKey;

    return switch (repeat) {
      RepeatType.none => this.date == dateKey,
      RepeatType.daily => true,
      RepeatType.weekly => date.weekday == start.weekday,
      RepeatType.monthly => date.day == start.day,
      RepeatType.yearly =>
        date.day == start.day && date.month == start.month,
      RepeatType.weekdays => repeatWeekdays.contains(date.weekday),
    };
  }

  /// 반복 task 에서 [dateKey] 의 done 상태.
  bool isDoneOnDate(String dateKey) {
    if (repeat == RepeatType.none) return status == TodoStatus.done;
    return doneOverrides.contains(dateKey);
  }

  // ── copyWith ──────────────────────────────────────────────────────

  TodoItem copyWith({
    String? title,
    String? date,
    TodoPriority? priority,
    String? tag,
    TodoStatus? status,
    int? urgency,
    int? importance,
    TodoStatus? previousStatus,
    bool clearPreviousStatus = false,
    String? time,
    bool clearTime = false,
    String? memo,
    bool clearMemo = false,
    RepeatType? repeat,
    List<int>? repeatWeekdays,
    String? repeatGroupId,
    bool clearRepeatGroupId = false,
    String? alarmTime,
    bool clearAlarmTime = false,
    Set<String>? doneOverrides,
    Set<String>? deletedOverrides,
    String? repeatEndDate,
    bool clearRepeatEndDate = false,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      tag: tag ?? this.tag,
      status: status ?? this.status,
      urgency: urgency ?? this.urgency,
      importance: importance ?? this.importance,
      createdAt: createdAt,
      previousStatus: clearPreviousStatus
          ? null
          : (previousStatus ?? this.previousStatus),
      time: clearTime ? null : (time ?? this.time),
      memo: clearMemo ? null : (memo ?? this.memo),
      repeat: repeat ?? this.repeat,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      repeatGroupId:
          clearRepeatGroupId ? null : (repeatGroupId ?? this.repeatGroupId),
      alarmTime: clearAlarmTime ? null : (alarmTime ?? this.alarmTime),
      doneOverrides: doneOverrides ?? this.doneOverrides,
      deletedOverrides: deletedOverrides ?? this.deletedOverrides,
      repeatEndDate:
          clearRepeatEndDate ? null : (repeatEndDate ?? this.repeatEndDate),
    );
  }

  // ── JSON ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'priority': priority.name,
      'tag': tag,
      'status': status.name,
      'urgency': urgency,
      'importance': importance,
      'createdAt': createdAt.toIso8601String(),
      if (previousStatus != null) 'previousStatus': previousStatus!.name,
      if (time != null) 'time': time,
      if (memo != null) 'memo': memo,
      if (repeat != RepeatType.none) 'repeat': repeat.name,
      if (repeatWeekdays.isNotEmpty) 'repeatWeekdays': repeatWeekdays,
      if (repeatGroupId != null) 'repeatGroupId': repeatGroupId,
      if (alarmTime != null) 'alarmTime': alarmTime,
      if (doneOverrides.isNotEmpty) 'doneOverrides': doneOverrides.toList(),
      if (deletedOverrides.isNotEmpty)
        'deletedOverrides': deletedOverrides.toList(),
      if (repeatEndDate != null) 'repeatEndDate': repeatEndDate,
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    final rawCreated = json['createdAt'];
    final p = TodoPriority.values.byName(json['priority'] as String);
    final d = defaultsForPriority(p);
    final u = json.containsKey('urgency')
        ? _readIntField(json['urgency'], d.$1)
        : d.$1;
    final im = json.containsKey('importance')
        ? _readIntField(json['importance'], d.$2)
        : d.$2;
    final prevStatusRaw = json['previousStatus'];

    final repeatRaw = json['repeat'];
    final repeat = repeatRaw != null
        ? RepeatType.values.firstWhere(
            (e) => e.name == repeatRaw,
            orElse: () => RepeatType.none,
          )
        : RepeatType.none;

    final weekdaysRaw = json['repeatWeekdays'];
    final repeatWeekdays = weekdaysRaw is List
        ? weekdaysRaw.map((e) => (e as num).toInt()).toList()
        : <int>[];

    final doneRaw = json['doneOverrides'];
    final doneOverrides = doneRaw is List
        ? Set<String>.from(doneRaw.map((e) => e.toString()))
        : <String>{};

    final deletedRaw = json['deletedOverrides'];
    final deletedOverrides = deletedRaw is List
        ? Set<String>.from(deletedRaw.map((e) => e.toString()))
        : <String>{};

    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      priority: p,
      tag: (json['tag'] as String?) ?? 'default',
      status: TodoStatus.values.byName(json['status'] as String),
      urgency: u,
      importance: im,
      createdAt: rawCreated != null && rawCreated is String
          ? DateTime.parse(rawCreated)
          : DateTime.now(),
      previousStatus: prevStatusRaw != null
          ? TodoStatus.values.byName(prevStatusRaw as String)
          : null,
      time: json['time'] as String?,
      memo: json['memo'] as String?,
      repeat: repeat,
      repeatWeekdays: repeatWeekdays,
      repeatGroupId: json['repeatGroupId'] as String?,
      alarmTime: json['alarmTime'] as String?,
      doneOverrides: doneOverrides,
      deletedOverrides: deletedOverrides,
      repeatEndDate: json['repeatEndDate'] as String?,
    );
  }

  String get priorityLabel {
    switch (priority) {
      case TodoPriority.high:
        return '높음';
      case TodoPriority.medium:
        return '보통';
      case TodoPriority.low:
        return '낮음';
    }
  }
}
