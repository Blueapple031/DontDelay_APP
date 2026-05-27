import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum TodoStatus { todo, inProgress, done }

enum TodoPriority { high, medium, low }

class TodoItem {
  final String id;
  final String title;
  final String date;
  final TodoPriority priority;
  final String tag;
  final TodoStatus status;
  /// 긴급도 1(낮음) ~ 8(높음), 가로축.
  final int urgency;
  /// 중요도 1(낮음) ~ 8(높음), 세로축.
  final int importance;
  final DateTime createdAt;

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
  })  : id = id ?? _uuid.v4(),
        urgency = urgency != null
            ? urgency.clamp(1, 8).toInt()
            : TodoItem.defaultsForPriority(priority).$1,
        importance = importance != null
            ? importance.clamp(1, 8).toInt()
            : TodoItem.defaultsForPriority(priority).$2,
        createdAt = createdAt ?? DateTime.now();

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

  TodoItem copyWith({
    String? title,
    String? date,
    TodoPriority? priority,
    String? tag,
    TodoStatus? status,
    int? urgency,
    int? importance,
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
    );
  }

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
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      priority: p,
      tag: json['tag'] as String,
      status: TodoStatus.values.byName(json['status'] as String),
      urgency: u,
      importance: im,
      createdAt: rawCreated != null && rawCreated is String
          ? DateTime.parse(rawCreated)
          : DateTime.now(),
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
