import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'todo/tag_model.dart';
import 'todo/tag_provider.dart';
import 'todo/todo_add_dialog.dart';
import 'todo/todo_model.dart';
import 'todo/todo_provider.dart';

enum _CalViewMode { month, sevenDays }

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  _CalViewMode _viewMode = _CalViewMode.month;
  late DateTime _focusedDate;
  late final DateTime _today;

  Color get _kPurple => Theme.of(context).colorScheme.primary;
  Color get _kPurpleLight => Theme.of(context).colorScheme.primaryContainer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _focusedDate = _today;
  }

  // ── helpers ─────────────────────────────────────────────────────

  static String _fmtKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Map<String, List<TodoItem>> _byDate(List<TodoItem> todos) {
    final m = <String, List<TodoItem>>{};
    for (final t in todos) {
      m.putIfAbsent(t.date, () => []).add(t);
    }
    return m;
  }

  List<TodoItem> _validTodos(List<TodoItem> todos) => todos.where((t) {
        try {
          DateTime.parse(t.date);
          return true;
        } catch (_) {
          return false;
        }
      }).toList();

  // ── navigation ───────────────────────────────────────────────────

  void _prev() => setState(() {
        if (_viewMode == _CalViewMode.month) {
          _focusedDate =
              DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
        } else {
          _focusedDate = _focusedDate.subtract(const Duration(days: 7));
        }
      });

  void _next() => setState(() {
        if (_viewMode == _CalViewMode.month) {
          _focusedDate =
              DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
        } else {
          _focusedDate = _focusedDate.add(const Duration(days: 7));
        }
      });

  String _headerLabel() {
    const months = [
      '1월', '2월', '3월', '4월', '5월', '6월',
      '7월', '8월', '9월', '10월', '11월', '12월',
    ];
    if (_viewMode == _CalViewMode.month) {
      return '${_focusedDate.year}년 ${months[_focusedDate.month - 1]}';
    }
    final end = _focusedDate.add(const Duration(days: 6));
    if (_focusedDate.month == end.month) {
      return '${_focusedDate.year}년 ${months[_focusedDate.month - 1]} '
          '${_focusedDate.day}일–${end.day}일';
    }
    return '${months[_focusedDate.month - 1]} ${_focusedDate.day}일'
        ' – ${months[end.month - 1]} ${end.day}일';
  }

  // ── build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final asyncTodos = ref.watch(todoListProvider);
    final tagMap = {
      for (final t in (ref.watch(tagListProvider).value ?? [TagItem.defaultTag]))
        t.id: t
    };

    return asyncTodos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류가 발생했습니다: $e')),
      data: (raw) {
        final todos = _validTodos(raw);
        return Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              Expanded(
                child: _viewMode == _CalViewMode.month
                    ? _buildMonthView(todos, tagMap)
                    : _buildSevenDaysView(todos, tagMap),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: OutlinedButton(
            onPressed: () => setState(() => _focusedDate = _today),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              foregroundColor: Colors.black87,
            ),
            child: const Text(
              'TODAY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _prev,
          splashRadius: 18,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _next,
          splashRadius: 18,
        ),
        const SizedBox(width: 6),
        Text(
          _headerLabel(),
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        SegmentedButton<_CalViewMode>(
          segments: const [
            ButtonSegment(
              value: _CalViewMode.month,
              label: Text('월간'),
              icon:
                  Icon(Icons.calendar_view_month_outlined, size: 15),
            ),
            ButtonSegment(
              value: _CalViewMode.sevenDays,
              label: Text('7일'),
              icon: Icon(Icons.view_week_outlined, size: 15),
            ),
          ],
          selected: {_viewMode},
          onSelectionChanged: (s) =>
              setState(() => _viewMode = s.first),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (st) => st.contains(WidgetState.selected)
                  ? _kPurple
                  : null,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (st) => st.contains(WidgetState.selected)
                  ? Colors.white
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  // ─── MONTH VIEW ──────────────────────────────────────────────────

  Widget _buildMonthView(
      List<TodoItem> todos, Map<String, TagItem> tagMap) {
    final byDate = _byDate(todos);
    final first =
        DateTime(_focusedDate.year, _focusedDate.month, 1);
    final offset = first.weekday - 1;
    final gridStart = first.subtract(Duration(days: offset));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'
          ]
              .map(
                (d) => Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: Colors.grey.shade200),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        Expanded(
          child: Column(
            children: List.generate(
              6,
              (row) => Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(7, (col) {
                    final date = gridStart
                        .add(Duration(days: row * 7 + col));
                    return Expanded(
                      child: _buildMonthCell(
                        date: date,
                        inMonth:
                            date.month == _focusedDate.month,
                        isToday: _sameDay(date, _today),
                        todos: byDate[_fmtKey(date)] ?? [],
                        tagMap: tagMap,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCell({
    required DateTime date,
    required bool inMonth,
    required bool isToday,
    required List<TodoItem> todos,
    required Map<String, TagItem> tagMap,
  }) {
    return DragTarget<TodoItem>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) async {
        final newDate = _fmtKey(date);
        if (details.data.date == newDate) return;
        try {
          await ref.read(todoListProvider.notifier).updateTodo(
                details.data.copyWith(date: newDate),
              );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('저장에 실패했습니다: $e')),
          );
        }
      },
      builder: (ctx, candidates, _) {
        final isHovering = candidates.isNotEmpty;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () =>
                showTodoAddDialog(context, ref, initialDate: date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: BoxDecoration(
                color: isHovering
                    ? _kPurpleLight.withValues(alpha: 0.5)
                    : Colors.transparent,
                border: Border(
                  right: BorderSide(color: Colors.grey.shade200),
                  bottom: BorderSide(color: Colors.grey.shade200),
                  left: isHovering
                      ? BorderSide(
                          color: _kPurple, width: 2)
                      : BorderSide.none,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(6, 5, 6, 3),
                    child: isToday
                        ? Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _kPurple,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${date.day}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: inMonth
                                  ? Colors.black87
                                  : Colors.grey.shade400,
                            ),
                          ),
                  ),
                  ...todos
                      .take(2)
                      .map((t) => _buildMonthBlock(t, tagMap)),
                  if (todos.length > 2)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () =>
                            _showDayPopup(date, todos, tagMap),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                              6, 1, 6, 2),
                          child: Text(
                            '+${todos.length - 2} more',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthBlock(
      TodoItem todo, Map<String, TagItem> tagMap) {
    final tag = tagMap[todo.tag] ?? TagItem.defaultTag;
    final color = hexToColor(tag.colorHex);
    final isDone = todo.status == TodoStatus.done;

    final blockContent = Container(
      margin: const EdgeInsets.fromLTRB(3, 1, 3, 1),
      padding:
          const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDone ? 0.06 : 0.13),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
              color: color.withValues(alpha: isDone ? 0.4 : 1),
              width: 2.5),
        ),
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                try {
                  await ref
                      .read(todoListProvider.notifier)
                      .changeStatus(
                        todo.id,
                        isDone
                            ? TodoStatus.todo
                            : TodoStatus.done,
                      );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('저장에 실패했습니다: $e')),
                  );
                }
              },
              child: Icon(
                isDone
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 11,
                color: isDone
                    ? color.withValues(alpha: 0.5)
                    : Colors.black38,
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    showTodoEditDialog(context, ref, todo),
                child: Text(
                  todo.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDone
                        ? Colors.grey.shade400
                        : Colors.black87,
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<TodoItem>(
        data: todo,
        feedback: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 140,
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(6),
              border: Border(
                  left: BorderSide(color: color, width: 2.5)),
            ),
            child: Text(
              todo.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, color: Colors.black87),
            ),
          ),
        ),
        childWhenDragging:
            Opacity(opacity: 0.4, child: blockContent),
        child: blockContent,
      ),
    );
  }

  void _showDayPopup(DateTime date, List<TodoItem> todos,
      Map<String, TagItem> tagMap) {
    final label =
        '${date.year}년 ${date.month}월 ${date.day}일';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: todos
                .map((t) => _DayPopupRow(
                      todo: t,
                      tagMap: tagMap,
                      onToggle: () async {
                        final isDone =
                            t.status == TodoStatus.done;
                        try {
                          await ref
                              .read(todoListProvider.notifier)
                              .changeStatus(
                                t.id,
                                isDone
                                    ? TodoStatus.todo
                                    : TodoStatus.done,
                              );
                        } catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx)
                              .showSnackBar(SnackBar(
                                  content: Text(
                                      '저장에 실패했습니다: $e')));
                        }
                      },
                      onEdit: () {
                        Navigator.pop(ctx);
                        showTodoEditDialog(context, ref, t);
                      },
                    ))
                .toList(),
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              showTodoAddDialog(context, ref, initialDate: date);
            },
            icon: const Icon(Icons.add,
                size: 16, color: Colors.white),
            label: const Text('추가',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('닫기',
                style:
                    TextStyle(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
  }

  // ─── 7 DAYS VIEW ─────────────────────────────────────────────────

  Widget _buildSevenDaysView(
      List<TodoItem> todos, Map<String, TagItem> tagMap) {
    final byDate = _byDate(todos);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(7, (i) {
          final date = _focusedDate.add(Duration(days: i));
          final isToday = _sameDay(date, _today);
          final dayTodos = byDate[_fmtKey(date)] ?? [];
          return _buildDayColumn(
              date: date,
              isToday: isToday,
              todos: dayTodos,
              tagMap: tagMap);
        }),
      ),
    );
  }

  Widget _buildDayColumn({
    required DateTime date,
    required bool isToday,
    required List<TodoItem> todos,
    required Map<String, TagItem> tagMap,
  }) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final diff = date.difference(_today).inDays;
    String label;
    if (diff == 0) {
      label = '오늘';
    } else if (diff == 1) {
      label = '내일';
    } else {
      label = weekdays[date.weekday - 1];
    }

    return SizedBox(
      width: 260,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? _kPurple.withValues(alpha: 0.35)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isToday ? _kPurple : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.shade100),
            Expanded(
              child: DragTarget<TodoItem>(
                onWillAcceptWithDetails: (_) => true,
                onAcceptWithDetails: (details) async {
                  final newDate = _fmtKey(date);
                  if (details.data.date == newDate) return;
                  try {
                    await ref
                        .read(todoListProvider.notifier)
                        .updateTodo(
                          details.data.copyWith(date: newDate),
                        );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('저장에 실패했습니다: $e')),
                    );
                  }
                },
                builder: (ctx, candidates, _) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      color: candidates.isNotEmpty
                          ? _kPurpleLight.withValues(alpha: 0.6)
                          : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(11)),
                    ),
                    child: ListView(
                      padding:
                          const EdgeInsets.fromLTRB(10, 10, 10, 4),
                      children: [
                        ...todos.map((t) =>
                            _buildSevenDayCard(t, tagMap)),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: TextButton.icon(
                            onPressed: () => showTodoAddDialog(
                                context, ref,
                                initialDate: date),
                            icon: Icon(Icons.add,
                                size: 14,
                                color: Colors.grey.shade400),
                            label: Text(
                              'Add Task',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400),
                            ),
                            style: TextButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSevenDayCard(
      TodoItem todo, Map<String, TagItem> tagMap) {
    final tag = tagMap[todo.tag] ?? TagItem.defaultTag;
    final color = hexToColor(tag.colorHex);
    final isDone = todo.status == TodoStatus.done;

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () async {
                try {
                  await ref
                      .read(todoListProvider.notifier)
                      .changeStatus(
                        todo.id,
                        isDone
                            ? TodoStatus.todo
                            : TodoStatus.done,
                      );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('저장에 실패했습니다: $e')),
                  );
                }
              },
              child: Icon(
                isDone
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 18,
                color: isDone ? Colors.green : Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    showTodoEditDialog(context, ref, todo),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tag.name.isNotEmpty)
                      Text(
                        tag.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDone
                            ? Colors.grey.shade400
                            : Colors.black87,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: Colors.grey.shade400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz,
                size: 15, color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.zero,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: const Text('수정'),
                onTap: () =>
                    showTodoEditDialog(context, ref, todo),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('삭제',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (v) async {
              if (v == 'delete') {
                try {
                  await ref
                      .read(todoListProvider.notifier)
                      .deleteTodo(todo.id);
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('저장에 실패했습니다: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<TodoItem>(
        data: todo,
        feedback: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(10),
          child: IgnorePointer(
            child: SizedBox(width: 220, child: cardContent),
          ),
        ),
        childWhenDragging:
            Opacity(opacity: 0.35, child: cardContent),
        child: cardContent,
      ),
    );
  }
}

// ─── Day popup row ────────────────────────────────────────────────

class _DayPopupRow extends StatelessWidget {
  final TodoItem todo;
  final Map<String, TagItem> tagMap;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const _DayPopupRow({
    required this.todo,
    required this.tagMap,
    required this.onToggle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = todo.status == TodoStatus.done;
    final tag = tagMap[todo.tag] ?? TagItem.defaultTag;
    final color = hexToColor(tag.colorHex);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onToggle,
              child: Icon(
                isDone
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 18,
                color: isDone
                    ? color.withValues(alpha: 0.6)
                    : Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onEdit,
                child: Text(
                  todo.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDone
                        ? Colors.grey.shade400
                        : Colors.black87,
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
