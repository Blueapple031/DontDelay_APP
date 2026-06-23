import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'retrospective.dart';
import 'retrospective_provider.dart';
import 'todo/tag_model.dart';
import 'todo/tag_provider.dart';
import 'todo/todo_model.dart';
import 'todo/todo_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const _weekdays = [
    '월요일',
    '화요일',
    '수요일',
    '목요일',
    '금요일',
    '토요일',
    '일요일',
  ];

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _todayKey() => _dateKey(DateTime.now());

  static String _formatHeaderDate() {
    final now = DateTime.now();
    return '${now.year}년 ${now.month}월 ${now.day}일 ${_weekdays[now.weekday - 1]}';
  }

  static bool _isOverdue(TodoItem todo) {
    final parsed = DateTime.tryParse(todo.date);
    if (parsed == null) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(parsed.year, parsed.month, parsed.day);
    return dueOnly.isBefore(todayOnly) && todo.status != TodoStatus.done;
  }

  static String _dueLabel(TodoItem todo) {
    if (_isOverdue(todo)) return '기한 지남';
    if (todo.date == _todayKey()) return '오늘';
    final parsed = DateTime.tryParse(todo.date);
    if (parsed == null) return todo.date;
    return '${parsed.month}/${parsed.day}';
  }

  static Color _priorityColor(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:
        return const Color(0xFFEF4444);
      case TodoPriority.medium:
        return const Color(0xFFF97316);
      case TodoPriority.low:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final todosAsync = ref.watch(todoListProvider);
    final retrosAsync = ref.watch(retrospectiveListProvider);
    final tagMap = {
      for (final t in (ref.watch(tagListProvider).value ?? [TagItem.defaultTag]))
        t.id: t,
    };

    return todosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('데이터를 불러오지 못했습니다: $e')),
      data: (todos) {
        final todayKey = _todayKey();
        final todayTodos = todos.where((t) => t.date == todayKey).toList();
        final pendingToday = todayTodos
            .where((t) => t.status != TodoStatus.done)
            .toList();
        final overdue = todos.where(_isOverdue).toList();
        final focusTodos = [
          ...overdue,
          ...pendingToday.where((t) => !overdue.contains(t)),
        ];
        final doneToday =
            todayTodos.where((t) => t.status == TodoStatus.done).length;
        final weekDone = todos
            .where((t) => t.status == TodoStatus.done)
            .length;

        return retrosAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('회고록을 불러오지 못했습니다: $e')),
          data: (retros) {
            final recentRetros = [...retros]
              ..sort((a, b) => b.date.compareTo(a.date));

            return SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '안녕하세요! 👋',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge!
                        .copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatHeaderDate(),
                    style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  _SummaryStrip(
                    pendingCount: focusTodos.length,
                    doneToday: doneToday,
                    scheduleCount: todayTodos.length,
                    retroCount: retros.length,
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 900;
                      final left = Column(
                        children: [
                          _DashboardCard(
                            title: '오늘의 할 일',
                            icon: Icons.check_circle_outline,
                            trailing: _LinkChip(
                              label: '할 일 관리',
                              onTap: () => context.go('/todo'),
                            ),
                            child: focusTodos.isEmpty
                                ? _EmptyHint(
                                    message: '오늘 할 일이 없어요.\n새 할 일을 추가해 보세요.',
                                    actionLabel: '할 일 추가',
                                    onAction: () => context.go('/todo'),
                                  )
                                : Column(
                                    children: [
                                      for (var i = 0; i < focusTodos.length && i < 5; i++) ...[
                                        if (i > 0) const _CardDivider(),
                                        _TodoRow(
                                          todo: focusTodos[i],
                                          tagMap: tagMap,
                                          dueLabel: _dueLabel(focusTodos[i]),
                                          priorityColor:
                                              _priorityColor(focusTodos[i].priority),
                                          onToggle: (done) {
                                            ref
                                                .read(todoListProvider.notifier)
                                                .changeStatus(
                                                  focusTodos[i].id,
                                                  done
                                                      ? TodoStatus.done
                                                      : TodoStatus.todo,
                                                );
                                          },
                                        ),
                                      ],
                                      if (focusTodos.length > 5) ...[
                                        const _CardDivider(),
                                        Text(
                                          '+ ${focusTodos.length - 5}개 더 있음',
                                          style: TextStyle(
                                            color: cs.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 24),
                          _DashboardCard(
                            title: '오늘 일정',
                            icon: Icons.calendar_today_outlined,
                            trailing: _LinkChip(
                              label: '캘린더',
                              onTap: () => context.go('/calendar'),
                            ),
                            child: todayTodos.isEmpty
                                ? _EmptyHint(
                                    message: '오늘 등록된 일정이 없어요.\n캘린더에서 날짜를 지정해 보세요.',
                                    actionLabel: '캘린더 열기',
                                    onAction: () => context.go('/calendar'),
                                  )
                                : Column(
                                    children: [
                                      for (var i = 0; i < todayTodos.length && i < 6; i++) ...[
                                        if (i > 0) const _CardDivider(),
                                        _ScheduleRow(
                                          todo: todayTodos[i],
                                          tagMap: tagMap,
                                          accent: cs.primary,
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ],
                      );
                      final right = Column(
                        children: [
                          _DashboardCard(
                            title: '최근 회고록',
                            icon: Icons.book_outlined,
                            trailing: _LinkChip(
                              label: '회고록',
                              onTap: () => context.go('/retrospective'),
                            ),
                            child: recentRetros.isEmpty
                                ? _EmptyHint(
                                    message: '아직 작성한 회고가 없어요.\n오늘 하루를 기록해 보세요.',
                                    actionLabel: '회고 작성',
                                    onAction: () => context.go('/retrospective'),
                                  )
                                : Column(
                                    children: [
                                      for (var i = 0;
                                          i < recentRetros.length && i < 3;
                                          i++) ...[
                                        if (i > 0) const _CardDivider(),
                                        _RetroRow(retro: recentRetros[i]),
                                      ],
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 24),
                          _DashboardCard(
                            title: '이번 주 한눈에',
                            icon: Icons.insights_outlined,
                            child: Column(
                              children: [
                                _InsightRow(
                                  label: '전체 할 일',
                                  value: '${todos.length}개',
                                  icon: Icons.list_alt,
                                  color: cs.primary,
                                ),
                                const SizedBox(height: 12),
                                _InsightRow(
                                  label: '완료한 할 일',
                                  value: '$weekDone개',
                                  icon: Icons.task_alt,
                                  color: const Color(0xFF10B981),
                                ),
                                const SizedBox(height: 12),
                                _InsightRow(
                                  label: '오늘 완료',
                                  value: '$doneToday개',
                                  icon: Icons.today,
                                  color: const Color(0xFF8B5CF6),
                                ),
                                const SizedBox(height: 12),
                                _InsightRow(
                                  label: '회고록',
                                  value: '${retros.length}개',
                                  icon: Icons.edit_note,
                                  color: const Color(0xFFF97316),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: left),
                            const SizedBox(width: 28),
                            Expanded(flex: 2, child: right),
                          ],
                        );
                      }
                      return Column(
                        children: [
                          left,
                          const SizedBox(height: 24),
                          right,
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.pendingCount,
    required this.doneToday,
    required this.scheduleCount,
    required this.retroCount,
  });

  final int pendingCount;
  final int doneToday;
  final int scheduleCount;
  final int retroCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatChip(
          icon: Icons.pending_actions,
          label: '처리할 일',
          value: '$pendingCount',
          color: cs.primary,
        ),
        _StatChip(
          icon: Icons.check,
          label: '오늘 완료',
          value: '$doneToday',
          color: const Color(0xFF10B981),
        ),
        _StatChip(
          icon: Icons.event,
          label: '오늘 일정',
          value: '$scheduleCount',
          color: const Color(0xFF8B5CF6),
        ),
        _StatChip(
          icon: Icons.auto_stories,
          label: '회고록',
          value: '$retroCount',
          color: const Color(0xFFF97316),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        '$label →',
        style: TextStyle(fontSize: 13, color: cs.primary),
      ),
    );
  }
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.todo,
    required this.tagMap,
    required this.dueLabel,
    required this.priorityColor,
    required this.onToggle,
  });

  final TodoItem todo;
  final Map<String, TagItem> tagMap;
  final String dueLabel;
  final Color priorityColor;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final done = todo.status == TodoStatus.done;
    final tag = tagMap[todo.tag];
    final tagColor =
        tag != null ? hexToColor(tag.colorHex) : Colors.grey;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: done,
            onChanged: (v) => onToggle(v ?? false),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                todo.title,
                style: TextStyle(
                  fontSize: 14,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? Colors.grey : null,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    dueLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: dueLabel == '기한 지남'
                          ? const Color(0xFFEF4444)
                          : Colors.grey.shade500,
                    ),
                  ),
                  if (tag != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag.name,
                        style: TextStyle(fontSize: 11, color: tagColor),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            todo.priorityLabel,
            style: TextStyle(fontSize: 12, color: priorityColor),
          ),
        ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.todo,
    required this.tagMap,
    required this.accent,
  });

  final TodoItem todo;
  final Map<String, TagItem> tagMap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final tag = tagMap[todo.tag];
    final done = todo.status == TodoStatus.done;
    final statusLabel = switch (todo.status) {
      TodoStatus.todo => '예정',
      TodoStatus.inProgress => '진행 중',
      TodoStatus.done => '완료',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                todo.title,
                style: TextStyle(
                  fontSize: 14,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? Colors.grey : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [statusLabel, if (tag != null) tag.name].join(' · '),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RetroRow extends StatelessWidget {
  const _RetroRow({required this.retro});

  final RetrospectiveItem retro;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(retro.emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                retro.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                retro.content,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                retro.date,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: cs.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 14),
      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
    );
  }
}
