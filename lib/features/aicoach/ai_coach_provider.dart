import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../todo/todo_model.dart';
import '../todo/todo_provider.dart';
import 'ai_coach_model.dart';

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
      await Future<void>.delayed(const Duration(milliseconds: 450));
      final reply = _buildMockReply(message, todos);
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

  AiCoachMessage _buildMockReply(String message, List<TodoItem> todos) {
    final now = DateTime.now();
    final todayKey = TodoItem.fmtDate(now);
    final activeTodos = todos
        .where((todo) => todo.status != TodoStatus.done)
        .where((todo) => !todo.deletedOverrides.contains(todayKey))
        .toList();

    activeTodos.sort((a, b) {
      final overdueCompare = _rankOverdue(
        b,
        todayKey,
      ).compareTo(_rankOverdue(a, todayKey));
      if (overdueCompare != 0) return overdueCompare;
      final todayCompare = _rankToday(b, now).compareTo(_rankToday(a, now));
      if (todayCompare != 0) return todayCompare;
      final scoreCompare = _score(b).compareTo(_score(a));
      if (scoreCompare != 0) return scoreCompare;
      return a.date.compareTo(b.date);
    });

    final recommendations = activeTodos
        .take(3)
        .map((todo) => _recommendationFor(todo, todayKey))
        .toList();

    final content = _contentFor(
      message,
      activeTodos,
      recommendations,
      todayKey,
    );
    return AiCoachMessage(
      role: AiCoachRole.assistant,
      content: content,
      createdAt: DateTime.now(),
      recommendations: recommendations,
    );
  }

  String _contentFor(
    String message,
    List<TodoItem> activeTodos,
    List<AiCoachRecommendation> recommendations,
    String todayKey,
  ) {
    if (activeTodos.isEmpty) {
      return '현재 남아있는 할 일이 없습니다. 오늘은 회고를 짧게 남기거나 내일 할 일을 1~2개만 미리 정리해두면 좋겠습니다.';
    }

    final overdueCount = activeTodos
        .where((todo) => _isOverdue(todo, todayKey))
        .length;
    final todayCount = activeTodos
        .where((todo) => todo.date == todayKey)
        .length;
    final top = recommendations.first;
    final buffer = StringBuffer()
      ..writeln('지금은 "${top.title}"부터 처리하는 걸 추천합니다.')
      ..writeln()
      ..writeln(
        '현재 남은 할 일은 ${activeTodos.length}개이고, 오늘 할 일은 $todayCount개입니다.',
      );

    if (overdueCount > 0) {
      buffer.writeln('지난 마감도 $overdueCount개 있어서 먼저 정리하는 편이 좋습니다.');
    }

    if (message.contains('30분')) {
      buffer
        ..writeln()
        ..write(
          '30분만 있다면 범위를 줄여서 시작하세요. 완료가 어렵다면 초안, 문제 1개, 자료 정리처럼 다음 행동 하나만 끝내는 기준이 좋습니다.',
        );
    } else if (message.contains('시험') || message.contains('공부')) {
      buffer
        ..writeln()
        ..write('공부 계획은 새 내용을 늘리기보다 밀린 항목과 중요도가 높은 항목을 먼저 배치하는 쪽으로 잡겠습니다.');
    } else {
      buffer
        ..writeln()
        ..write('아래 순서대로 처리하면 마감 리스크와 중요도를 같이 줄일 수 있습니다.');
    }

    return buffer.toString();
  }

  AiCoachRecommendation _recommendationFor(TodoItem todo, String todayKey) {
    if (_isOverdue(todo, todayKey)) {
      return AiCoachRecommendation(
        title: todo.title,
        timeRange: '지금 바로',
        tag: '지난 마감',
        tagLevel: AiCoachTagLevel.urgent,
        reason: '마감일이 지나 우선 정리가 필요합니다.',
        relatedTodoId: todo.id,
      );
    }

    if (todo.date == todayKey || todo.isActiveOnDate(DateTime.now())) {
      return AiCoachRecommendation(
        title: todo.title,
        timeRange: todo.time ?? '오늘 안에',
        tag: '오늘 할 일',
        tagLevel: AiCoachTagLevel.scheduled,
        reason: '오늘 처리 대상입니다.',
        relatedTodoId: todo.id,
      );
    }

    if (todo.importance >= 6) {
      return AiCoachRecommendation(
        title: todo.title,
        timeRange: '집중 40분',
        tag: '중요',
        tagLevel: AiCoachTagLevel.review,
        reason: '중요도가 높아 미리 진도를 내는 편이 좋습니다.',
        relatedTodoId: todo.id,
      );
    }

    return AiCoachRecommendation(
      title: todo.title,
      timeRange: '여유 시간',
      tag: '대기',
      tagLevel: AiCoachTagLevel.normal,
      reason: '긴급한 항목 뒤에 처리하면 됩니다.',
      relatedTodoId: todo.id,
    );
  }

  bool _isOverdue(TodoItem todo, String todayKey) {
    return todo.repeat == RepeatType.none && todo.date.compareTo(todayKey) < 0;
  }

  int _rankOverdue(TodoItem todo, String todayKey) {
    return _isOverdue(todo, todayKey) ? 1 : 0;
  }

  int _rankToday(TodoItem todo, DateTime now) {
    return todo.isActiveOnDate(now) ? 1 : 0;
  }

  int _score(TodoItem todo) {
    final priorityBonus = switch (todo.priority) {
      TodoPriority.high => 16,
      TodoPriority.medium => 8,
      TodoPriority.low => 0,
    };
    return (todo.urgency * 2) + (todo.importance * 2) + priorityBonus;
  }
}
