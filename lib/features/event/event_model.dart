import 'package:uuid/uuid.dart';
import '../todo/todo_model.dart' show RepeatType;

const _eventUuid = Uuid();

class EventItem {
  final String id;
  final String title;
  final String date; // "yyyy-MM-dd"
  final String? time; // "HH:mm"
  final String? memo;
  final String tag; // TagItem.id
  final RepeatType repeat;
  final List<int> repeatWeekdays;
  final String? repeatGroupId;
  final String? alarmTime; // ISO "yyyy-MM-ddTHH:mm"
  final Set<String> deletedOverrides; // 삭제된 날짜
  final String? repeatEndDate; // 이 날짜 이후 반복 없음
  final DateTime createdAt;

  EventItem({
    String? id,
    required this.title,
    required this.date,
    this.time,
    this.memo,
    this.tag = 'default',
    this.repeat = RepeatType.none,
    List<int>? repeatWeekdays,
    this.repeatGroupId,
    this.alarmTime,
    Set<String>? deletedOverrides,
    this.repeatEndDate,
    DateTime? createdAt,
  })  : id = id ?? _eventUuid.v4(),
        repeatWeekdays = repeatWeekdays ?? const [],
        deletedOverrides = deletedOverrides ?? const {},
        createdAt = createdAt ?? DateTime.now();

  static String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isActiveOnDate(DateTime date) {
    final dateKey = _fmtDate(date);
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

  EventItem copyWith({
    String? title,
    String? date,
    String? time,
    bool clearTime = false,
    String? memo,
    bool clearMemo = false,
    String? tag,
    RepeatType? repeat,
    List<int>? repeatWeekdays,
    String? repeatGroupId,
    bool clearRepeatGroupId = false,
    String? alarmTime,
    bool clearAlarmTime = false,
    Set<String>? deletedOverrides,
    String? repeatEndDate,
    bool clearRepeatEndDate = false,
  }) {
    return EventItem(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: clearTime ? null : (time ?? this.time),
      memo: clearMemo ? null : (memo ?? this.memo),
      tag: tag ?? this.tag,
      repeat: repeat ?? this.repeat,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      repeatGroupId:
          clearRepeatGroupId ? null : (repeatGroupId ?? this.repeatGroupId),
      alarmTime: clearAlarmTime ? null : (alarmTime ?? this.alarmTime),
      deletedOverrides: deletedOverrides ?? this.deletedOverrides,
      repeatEndDate:
          clearRepeatEndDate ? null : (repeatEndDate ?? this.repeatEndDate),
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        if (time != null) 'time': time,
        if (memo != null) 'memo': memo,
        if (tag != 'default') 'tag': tag,
        if (repeat != RepeatType.none) 'repeat': repeat.name,
        if (repeatWeekdays.isNotEmpty) 'repeatWeekdays': repeatWeekdays,
        if (repeatGroupId != null) 'repeatGroupId': repeatGroupId,
        if (alarmTime != null) 'alarmTime': alarmTime,
        if (deletedOverrides.isNotEmpty)
          'deletedOverrides': deletedOverrides.toList(),
        if (repeatEndDate != null) 'repeatEndDate': repeatEndDate,
        'createdAt': createdAt.toIso8601String(),
      };

  factory EventItem.fromJson(Map<String, dynamic> json) {
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

    final deletedRaw = json['deletedOverrides'];
    final deletedOverrides = deletedRaw is List
        ? Set<String>.from(deletedRaw.map((e) => e.toString()))
        : <String>{};

    return EventItem(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      time: json['time'] as String?,
      memo: json['memo'] as String?,
      tag: (json['tag'] as String?) ?? 'default',
      repeat: repeat,
      repeatWeekdays: repeatWeekdays,
      repeatGroupId: json['repeatGroupId'] as String?,
      alarmTime: json['alarmTime'] as String?,
      deletedOverrides: deletedOverrides,
      repeatEndDate: json['repeatEndDate'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
