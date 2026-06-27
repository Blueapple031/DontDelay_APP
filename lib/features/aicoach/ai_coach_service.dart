import 'package:dio/dio.dart';

import '../../core/api_error.dart';
import '../todo/todo_model.dart';
import 'ai_coach_model.dart';

class AiCoachService {
  AiCoachService(this._dio);

  final Dio _dio;

  Future<AiCoachSendResult> sendMessage({
    required String message,
    required List<TodoItem> todos,
    String? sessionId,
  }) async {
    final context = _buildContextSnapshot(todos);
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/ai/chat',
        data: {
          'message': message,
          if (sessionId != null) 'sessionId': sessionId,
          'locale': 'ko-KR',
          'context': context.toJson(),
        },
      );
      return _parseResponse(response.data);
    } on DioException catch (e) {
      if (!_shouldUseMockFallback(e)) {
        throw AiCoachServiceException(_messageForDioException(e));
      }

      final fallback = await _buildMockResult(
        message,
        todos,
        context,
        sessionId,
      );
      return fallback;
    }
  }

  AiCoachSendResult _parseResponse(Map<String, dynamic>? data) {
    if (data == null) {
      throw const AiCoachServiceException('AI 코치 응답이 비어 있습니다.');
    }

    final replyRaw = data['reply'];
    if (replyRaw is! Map) {
      throw const AiCoachServiceException('AI 코치 응답 형식이 올바르지 않습니다.');
    }

    return AiCoachSendResult(
      message: AiCoachMessage.fromJson(Map<String, dynamic>.from(replyRaw)),
      sessionId: data['sessionId']?.toString(),
    );
  }

  Future<AiCoachSendResult> _buildMockResult(
    String message,
    List<TodoItem> todos,
    AiCoachContextSnapshot context,
    String? sessionId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return AiCoachSendResult(
      message: _buildMockReply(message, todos, context),
      sessionId: sessionId,
      usedFallback: true,
    );
  }

  AiCoachMessage _buildMockReply(
    String message,
    List<TodoItem> todos,
    AiCoachContextSnapshot context,
  ) {
    final now = DateTime.now();
    final todayKey = context.today;
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

  AiCoachContextSnapshot _buildContextSnapshot(List<TodoItem> todos) {
    final now = DateTime.now();
    final todayKey = TodoItem.fmtDate(now);
    final contextTodos = todos
        .where((todo) => todo.status != TodoStatus.done)
        .where((todo) => !todo.deletedOverrides.contains(todayKey))
        .map(
          (todo) => AiCoachTodoContext(
            id: todo.id,
            title: todo.title,
            date: todo.date,
            status: todo.status.name,
            priority: todo.priority.name,
            urgency: todo.urgency,
            importance: todo.importance,
            tag: todo.tag,
            time: todo.time,
            memo: todo.memo,
            repeat: todo.repeat == RepeatType.none ? null : todo.repeat.name,
          ),
        )
        .toList();

    return AiCoachContextSnapshot(today: todayKey, todos: contextTodos);
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

  bool _shouldUseMockFallback(DioException e) {
    if (e.response == null) return true;

    final statusCode = e.response?.statusCode;
    final errorCode = errorCodeFromResponse(e.response?.data);
    if (statusCode == 401 || statusCode == 400 || statusCode == 429) {
      return false;
    }
    if (errorCode == 'AI_DISABLED') return false;
    return statusCode == 404 || statusCode == 501 || statusCode == 502;
  }

  String _messageForDioException(DioException e) {
    if (e.response?.statusCode == 401) {
      return 'AI 코치를 사용하려면 로그인이 필요합니다.';
    }

    final connectionError = parseConnectionError(e);
    if (connectionError != null) return connectionError;

    final message = messageFromResponse(e.response?.data);
    if (message != null && message.isNotEmpty) return message;

    return 'AI 코치 응답을 가져오지 못했습니다. 잠시 후 다시 시도해주세요.';
  }
}

class AiCoachSendResult {
  const AiCoachSendResult({
    required this.message,
    this.sessionId,
    this.usedFallback = false,
  });

  final AiCoachMessage message;
  final String? sessionId;
  final bool usedFallback;
}

class AiCoachServiceException implements Exception {
  const AiCoachServiceException(this.message);

  final String message;
}
