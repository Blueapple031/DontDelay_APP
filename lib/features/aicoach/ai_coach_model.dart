enum AiCoachRole { user, assistant }

enum AiCoachTagLevel { urgent, scheduled, review, normal }

class AiCoachRecommendation {
  const AiCoachRecommendation({
    required this.title,
    required this.timeRange,
    required this.tag,
    required this.tagLevel,
    this.reason,
    this.relatedTodoId,
  });

  final String title;
  final String timeRange;
  final String tag;
  final AiCoachTagLevel tagLevel;
  final String? reason;
  final String? relatedTodoId;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'timeRange': timeRange,
      'tag': tag,
      'tagLevel': tagLevel.name,
      if (reason != null) 'reason': reason,
      if (relatedTodoId != null) 'relatedTodoId': relatedTodoId,
    };
  }

  factory AiCoachRecommendation.fromJson(Map<String, dynamic> json) {
    return AiCoachRecommendation(
      title: (json['title'] ?? '').toString(),
      timeRange: (json['timeRange'] ?? json['time'] ?? '').toString(),
      tag: (json['tag'] ?? '추천').toString(),
      tagLevel: _parseTagLevel(json['tagLevel']),
      reason: json['reason']?.toString(),
      relatedTodoId: json['relatedTodoId']?.toString(),
    );
  }

  static AiCoachTagLevel _parseTagLevel(dynamic raw) {
    final value = raw?.toString();
    return AiCoachTagLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => AiCoachTagLevel.normal,
    );
  }
}

class AiCoachMessage {
  const AiCoachMessage({
    required this.role,
    required this.content,
    required this.createdAt,
    this.recommendations = const [],
  });

  final AiCoachRole role;
  final String content;
  final DateTime createdAt;
  final List<AiCoachRecommendation> recommendations;

  factory AiCoachMessage.fromJson(Map<String, dynamic> json) {
    final recommendationsRaw = json['recommendations'];
    final recommendations = recommendationsRaw is List
        ? recommendationsRaw
              .whereType<Map>()
              .map(
                (item) => AiCoachRecommendation.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : const <AiCoachRecommendation>[];
    final createdAtRaw = json['createdAt']?.toString();

    return AiCoachMessage(
      role: AiCoachRole.assistant,
      content: (json['content'] ?? '').toString(),
      createdAt: createdAtRaw != null
          ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
          : DateTime.now(),
      recommendations: recommendations,
    );
  }
}

class AiCoachChatState {
  const AiCoachChatState({
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
    this.sessionId,
  });

  final List<AiCoachMessage> messages;
  final bool isSending;
  final String? errorMessage;
  final String? sessionId;

  AiCoachChatState copyWith({
    List<AiCoachMessage>? messages,
    bool? isSending,
    String? errorMessage,
    String? sessionId,
    bool clearError = false,
  }) {
    return AiCoachChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class AiCoachContextSnapshot {
  const AiCoachContextSnapshot({
    required this.today,
    this.todos = const [],
    this.upcomingEvents = const [],
  });

  final String today;
  final List<AiCoachTodoContext> todos;
  final List<Map<String, dynamic>> upcomingEvents;

  Map<String, dynamic> toJson() {
    return {
      'today': today,
      'todos': todos.map((todo) => todo.toJson()).toList(),
      'upcomingEvents': upcomingEvents,
    };
  }
}

class AiCoachTodoContext {
  const AiCoachTodoContext({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.priority,
    required this.urgency,
    required this.importance,
    required this.tag,
    this.time,
    this.memo,
    this.repeat,
  });

  final String id;
  final String title;
  final String date;
  final String status;
  final String priority;
  final int urgency;
  final int importance;
  final String tag;
  final String? time;
  final String? memo;
  final String? repeat;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'status': status,
      'priority': priority,
      'urgency': urgency,
      'importance': importance,
      'tag': tag,
      if (time != null) 'time': time,
      if (memo != null) 'memo': memo,
      if (repeat != null) 'repeat': repeat,
    };
  }
}
