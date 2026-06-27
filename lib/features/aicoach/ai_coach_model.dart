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
}

class AiCoachChatState {
  const AiCoachChatState({
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
  });

  final List<AiCoachMessage> messages;
  final bool isSending;
  final String? errorMessage;

  AiCoachChatState copyWith({
    List<AiCoachMessage>? messages,
    bool? isSending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AiCoachChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
