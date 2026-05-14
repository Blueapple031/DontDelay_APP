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
  final DateTime createdAt;

  TodoItem({
    String? id,
    required this.title,
    required this.date,
    required this.priority,
    required this.tag,
    required this.status,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  TodoItem copyWith({
    String? title,
    String? date,
    TodoPriority? priority,
    String? tag,
    TodoStatus? status,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      tag: tag ?? this.tag,
      status: status ?? this.status,
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
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    final rawCreated = json['createdAt'];
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      date: json['date'] as String,
      priority: TodoPriority.values.byName(json['priority'] as String),
      tag: json['tag'] as String,
      status: TodoStatus.values.byName(json['status'] as String),
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
