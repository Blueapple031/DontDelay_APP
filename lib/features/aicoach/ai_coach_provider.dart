import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../todo/todo_model.dart';
import '../todo/todo_provider.dart';
import 'ai_coach_model.dart';
import 'ai_coach_service.dart';

final aiCoachServiceProvider = Provider<AiCoachService>((ref) {
  return AiCoachService();
});

final aiCoachProvider = NotifierProvider<AiCoachNotifier, AiCoachChatState>(
  AiCoachNotifier.new,
);

class AiCoachNotifier extends Notifier<AiCoachChatState> {
  @override
  AiCoachChatState build() {
    return AiCoachChatState(
      messages: [
        AiCoachMessage(
          role: AiCoachRole.assistant,
          createdAt: DateTime.now(),
          content:
              '오늘 할 일과 마감 상황을 보고 우선순위를 잡아드릴게요. 궁금한 내용을 입력하거나 빠른 질문을 눌러보세요.',
        ),
      ],
    );
  }

  Future<void> sendMessage(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || state.isSending) return;

    final userMessage = AiCoachMessage(
      role: AiCoachRole.user,
      content: message,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isSending: true,
      clearError: true,
    );

    try {
      final todos = ref.read(todoListProvider).value ?? const <TodoItem>[];
      final reply = await ref
          .read(aiCoachServiceProvider)
          .sendMessage(message: message, todos: todos);
      state = state.copyWith(
        messages: [...state.messages, reply],
        isSending: false,
      );
    } catch (_) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'AI 코치 응답을 만들지 못했습니다. 잠시 후 다시 시도해주세요.',
      );
    }
  }
}
