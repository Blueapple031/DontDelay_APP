import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'aicoach/ai_coach_model.dart';
import 'aicoach/ai_coach_provider.dart';
import 'todo/tag_model.dart';
import 'todo/tag_provider.dart';
import 'todo/todo_model.dart';
import 'todo/todo_provider.dart';

class AiCoachScreen extends ConsumerStatefulWidget {
  const AiCoachScreen({super.key});

  @override
  ConsumerState<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachScreenState extends ConsumerState<AiCoachScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final Set<String> _appliedRecommendationKeys = {};

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final message = text ?? _controller.text;
    if (message.trim().isEmpty) return;
    _controller.clear();
    await ref.read(aiCoachProvider.notifier).sendMessage(message);
    _scrollToBottom();
  }

  Future<void> _completeRecommendation(AiCoachRecommendation item) async {
    final todoId = item.relatedTodoId;
    if (todoId == null || todoId.isEmpty) return;

    try {
      await ref
          .read(todoListProvider.notifier)
          .changeStatus(todoId, TodoStatus.done);
      if (!mounted) return;
      setState(() {
        _appliedRecommendationKeys.add(_recommendationKey(item));
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${item.title}"을 완료 처리했습니다.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('할 일을 완료 처리하지 못했습니다.')));
    }
  }

  Future<void> _createTodoFromRecommendation(AiCoachRecommendation item) async {
    final draft = item.todoDraft;
    if (draft == null ||
        draft.title.trim().isEmpty ||
        draft.date.trim().isEmpty) {
      return;
    }

    try {
      final tagId = await _tagIdFromDraft(draft.tag);
      await ref
          .read(todoListProvider.notifier)
          .addTodo(
            TodoItem(
              title: draft.title.trim(),
              date: draft.date,
              priority: _priorityFromDraft(draft.priority),
              tag: tagId,
              status: TodoStatus.todo,
              urgency: draft.urgency,
              importance: draft.importance,
              time: draft.time,
              memo: draft.memo,
            ),
          );
      if (!mounted) return;
      setState(() {
        _appliedRecommendationKeys.add(_recommendationKey(item));
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${draft.title}"을 할 일에 추가했습니다.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('할 일을 추가하지 못했습니다.')));
    }
  }

  TodoPriority _priorityFromDraft(String raw) {
    return TodoPriority.values.firstWhere(
      (priority) => priority.name == raw,
      orElse: () => TodoPriority.medium,
    );
  }

  Future<String> _tagIdFromDraft(String raw) async {
    final tag = raw.trim();
    final tags = await ref.read(tagListProvider.future);
    if (tag.isEmpty ||
        tag == TagItem.defaultId ||
        tag == '기본값' ||
        tag == '기본') {
      return TagItem.defaultId;
    }
    for (final item in tags) {
      if (item.id == tag || item.name == tag) return item.id;
    }
    return tag;
  }

  bool _isRecommendationApplied(AiCoachRecommendation item) {
    return _appliedRecommendationKeys.contains(_recommendationKey(item));
  }

  String _recommendationKey(AiCoachRecommendation item) {
    return switch (item.action) {
      AiCoachRecommendationAction.completeTodo =>
        'complete:${item.relatedTodoId ?? item.title}',
      AiCoachRecommendationAction.createTodo =>
        'create:${item.todoDraft?.title ?? item.title}:${item.todoDraft?.date ?? ''}',
      AiCoachRecommendationAction.none =>
        'none:${item.title}:${item.timeRange}',
    };
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiCoachProvider);
    final scheme = Theme.of(context).colorScheme;

    ref.listen(aiCoachProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: scheme.primary, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI 코치',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '오늘의 할 일과 우선순위를 바탕으로 다음 행동을 추천합니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(24),
                      itemCount:
                          state.messages.length + (state.isSending ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        if (index >= state.messages.length) {
                          return const _TypingMessage();
                        }
                        return _ChatMessageBubble(
                          message: state.messages[index],
                          onCompleteRecommendation: _completeRecommendation,
                          onCreateTodoRecommendation:
                              _createTodoFromRecommendation,
                          isRecommendationApplied: _isRecommendationApplied,
                        );
                      },
                    ),
                  ),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: _ErrorBanner(message: state.errorMessage!),
                    ),
                  Divider(height: 1, color: scheme.outlineVariant),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                minLines: 1,
                                maxLines: 4,
                                textInputAction: TextInputAction.send,
                                onSubmitted: state.isSending
                                    ? null
                                    : (_) => _send(),
                                decoration: InputDecoration(
                                  hintText: 'AI 코치에게 질문하기...',
                                  hintStyle: TextStyle(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 54,
                              width: 54,
                              child: FilledButton(
                                onPressed: state.isSending
                                    ? null
                                    : () => _send(),
                                style: FilledButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Icon(Icons.send, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _QuickSuggestion(
                              text: '오늘 뭐부터 해야 해?',
                              onTap: state.isSending
                                  ? null
                                  : () => _send('오늘 뭐부터 해야 해?'),
                            ),
                            _QuickSuggestion(
                              text: '시험 공부 계획 세워줘',
                              onTap: state.isSending
                                  ? null
                                  : () => _send('시험 공부 계획 세워줘'),
                            ),
                            _QuickSuggestion(
                              text: '30분 있으면 뭐 할까?',
                              onTap: state.isSending
                                  ? null
                                  : () => _send('30분 있으면 뭐 할까?'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    required this.onCompleteRecommendation,
    required this.onCreateTodoRecommendation,
    required this.isRecommendationApplied,
  });

  final AiCoachMessage message;
  final ValueChanged<AiCoachRecommendation> onCompleteRecommendation;
  final ValueChanged<AiCoachRecommendation> onCreateTodoRecommendation;
  final bool Function(AiCoachRecommendation item) isRecommendationApplied;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AiCoachRole.user;
    final scheme = Theme.of(context).colorScheme;
    const userBubbleColor = Color(0xFFF7D3B8);
    const userTextColor = Color(0xFF4E2507);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          textDirection: isUser ? TextDirection.rtl : TextDirection.ltr,
          children: [
            if (!isUser) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: scheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? userBubbleColor : scheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isUser ? 16 : 4),
                        topRight: Radius.circular(isUser ? 4 : 16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.55,
                            color: isUser ? userTextColor : scheme.onSurface,
                          ),
                        ),
                        if (message.recommendations.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ...message.recommendations.map((item) {
                            final isApplied = isRecommendationApplied(item);
                            return _RecommendationCard(
                              item: item,
                              isApplied: isApplied,
                              onAction: isApplied ? null : _actionFor(item),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback? _actionFor(AiCoachRecommendation item) {
    return switch (item.action) {
      AiCoachRecommendationAction.completeTodo =>
        item.relatedTodoId == null
            ? null
            : () => onCompleteRecommendation(item),
      AiCoachRecommendationAction.createTodo =>
        item.todoDraft == null ? null : () => onCreateTodoRecommendation(item),
      AiCoachRecommendationAction.none => null,
    };
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.item,
    required this.isApplied,
    required this.onAction,
  });

  final AiCoachRecommendation item;
  final bool isApplied;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tagColor = switch (item.tagLevel) {
      AiCoachTagLevel.urgent => scheme.error,
      AiCoachTagLevel.scheduled => scheme.primary,
      AiCoachTagLevel.review => scheme.secondary,
      AiCoachTagLevel.normal => scheme.onSurfaceVariant,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.timeRange,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      item.tag,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: tagColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (item.reason != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.reason!,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!_shouldHideAction)
            Tooltip(
              message: _actionTooltip,
              child: IconButton(
                onPressed: onAction,
                icon: Icon(_actionIcon),
                color: isApplied
                    ? scheme.primary
                    : onAction == null
                    ? scheme.outline
                    : scheme.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }

  bool get _shouldHideAction {
    return isApplied && item.action == AiCoachRecommendationAction.completeTodo;
  }

  IconData get _actionIcon {
    if (isApplied && item.action == AiCoachRecommendationAction.createTodo) {
      return Icons.check_circle_outline;
    }

    return switch (item.action) {
      AiCoachRecommendationAction.completeTodo => Icons.check_circle_outline,
      AiCoachRecommendationAction.createTodo => Icons.add_task,
      AiCoachRecommendationAction.none => Icons.info_outline,
    };
  }

  String get _actionTooltip {
    if (isApplied) {
      return switch (item.action) {
        AiCoachRecommendationAction.completeTodo => '완료됨',
        AiCoachRecommendationAction.createTodo => '추가됨',
        AiCoachRecommendationAction.none => '적용됨',
      };
    }

    if (onAction == null) {
      return switch (item.action) {
        AiCoachRecommendationAction.completeTodo => '연결된 할 일이 없습니다',
        AiCoachRecommendationAction.createTodo => '추가할 할 일 정보가 없습니다',
        AiCoachRecommendationAction.none => '실행할 수 있는 동작이 없습니다',
      };
    }
    return switch (item.action) {
      AiCoachRecommendationAction.completeTodo => '완료 처리',
      AiCoachRecommendationAction.createTodo => '할 일 추가',
      AiCoachRecommendationAction.none => '실행',
    };
  }
}

class _QuickSuggestion extends StatelessWidget {
  const _QuickSuggestion({required this.text, required this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      onPressed: onTap,
      label: Text(text),
      backgroundColor: scheme.surfaceContainerLowest,
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

class _TypingMessage extends StatelessWidget {
  const _TypingMessage();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.auto_awesome, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '분석 중...',
              style: TextStyle(color: scheme.onSurface, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
      ),
    );
  }
}
