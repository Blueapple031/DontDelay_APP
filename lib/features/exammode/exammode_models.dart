class ExamItem {
  final String id;
  final String name;
  final DateTime date;

  ExamItem({
    required this.id,
    required this.name,
    required this.date,
  });

  ExamItem copyWith({
    String? id,
    String? name,
    DateTime? date,
  }) {
    return ExamItem(
      id: id ?? this.id,
      name: name ?? this.name,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
    };
  }

  factory ExamItem.fromJson(Map<String, dynamic> json) {
    return ExamItem(
      id: json['id'] as String,
      name: json['name'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}

class StudySubject {
  final String id;
  final String name;
  final int accumulatedSeconds;

  StudySubject({
    required this.id,
    required this.name,
    required this.accumulatedSeconds,
  });

  StudySubject copyWith({
    String? id,
    String? name,
    int? accumulatedSeconds,
  }) {
    return StudySubject(
      id: id ?? this.id,
      name: name ?? this.name,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'accumulatedSeconds': accumulatedSeconds,
    };
  }

  factory StudySubject.fromJson(Map<String, dynamic> json) {
    return StudySubject(
      id: json['id'] as String,
      name: json['name'] as String,
      accumulatedSeconds: json['accumulatedSeconds'] as int,
    );
  }
}

class ExamTask {
  final String id;
  final String title;
  final bool isCompleted;
  final String subject;

  ExamTask({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.subject,
  });

  ExamTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    String? subject,
  }) {
    return ExamTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      subject: subject ?? this.subject,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'subject': subject,
    };
  }

  factory ExamTask.fromJson(Map<String, dynamic> json) {
    return ExamTask(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
      subject: json['subject'] as String,
    );
  }
}
