enum AiCoachRole { user, assistant }

enum AiCoachTagLevel { urgent, scheduled, review, normal }

enum AiCoachRecommendationAction { completeTodo, createTodo, none }

class AiCoachRecommendation {
  const AiCoachRecommendation({
    required this.title,
    required this.timeRange,
    required this.tag,
    required this.tagLevel,
    this.action = AiCoachRecommendationAction.none,
    this.reason,
    this.relatedTodoId,
    this.todoDraft,
  });

  final String title;
  final String timeRange;
  final String tag;
  final AiCoachTagLevel tagLevel;
  final AiCoachRecommendationAction action;
  final String? reason;
  final String? relatedTodoId;
  final AiCoachTodoDraft? todoDraft;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'timeRange': timeRange,
      'tag': tag,
      'tagLevel': tagLevel.name,
      'action': action.name,
      if (reason != null) 'reason': reason,
      if (relatedTodoId != null) 'relatedTodoId': relatedTodoId,
      if (todoDraft != null) 'todoDraft': todoDraft!.toJson(),
    };
  }

  factory AiCoachRecommendation.fromJson(Map<String, dynamic> json) {
    final todoDraftRaw = json['todoDraft'];
    return AiCoachRecommendation(
      title: (json['title'] ?? '').toString(),
      timeRange: (json['timeRange'] ?? json['time'] ?? '').toString(),
      tag: (json['tag'] ?? '추천').toString(),
      tagLevel: _parseTagLevel(json['tagLevel']),
      action: _parseAction(json['action']),
      reason: json['reason']?.toString(),
      relatedTodoId: json['relatedTodoId']?.toString(),
      todoDraft: todoDraftRaw is Map
          ? AiCoachTodoDraft.fromJson(Map<String, dynamic>.from(todoDraftRaw))
          : null,
    );
  }

  static AiCoachTagLevel _parseTagLevel(dynamic raw) {
    final value = raw?.toString();
    return AiCoachTagLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => AiCoachTagLevel.normal,
    );
  }

  static AiCoachRecommendationAction _parseAction(dynamic raw) {
    final value = raw?.toString();
    return AiCoachRecommendationAction.values.firstWhere(
      (action) => action.name == value,
      orElse: () => AiCoachRecommendationAction.none,
    );
  }
}

class AiCoachTodoDraft {
  const AiCoachTodoDraft({
    required this.title,
    required this.date,
    this.priority = 'medium',
    this.urgency = 5,
    this.importance = 5,
    this.tag = 'default',
    this.time,
    this.memo,
  });

  final String title;
  final String date;
  final String priority;
  final int urgency;
  final int importance;
  final String tag;
  final String? time;
  final String? memo;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'priority': priority,
      'urgency': urgency,
      'importance': importance,
      'tag': tag,
      if (time != null) 'time': time,
      if (memo != null) 'memo': memo,
    };
  }

  factory AiCoachTodoDraft.fromJson(Map<String, dynamic> json) {
    return AiCoachTodoDraft(
      title: (json['title'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      priority: (json['priority'] ?? 'medium').toString(),
      urgency: _readScore(json['urgency'], 5),
      importance: _readScore(json['importance'], 5),
      tag: (json['tag'] ?? 'default').toString(),
      time: json['time']?.toString(),
      memo: json['memo']?.toString(),
    );
  }

  static int _readScore(dynamic raw, int fallback) {
    if (raw is int) return raw.clamp(1, 8).toInt();
    if (raw is num) return raw.round().clamp(1, 8).toInt();
    return fallback;
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
