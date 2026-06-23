import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tag_model.dart';
import 'tag_provider.dart';
import 'todo_add_dialog.dart';
import 'todo_eisenhower_board.dart';
import 'todo_model.dart';
import 'todo_provider.dart';
import 'todo_view_mode.dart';

class TodoScreen extends ConsumerStatefulWidget {
  const TodoScreen({super.key});

  @override
  ConsumerState<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends ConsumerState<TodoScreen> {
  TodoViewMode _viewMode = TodoViewMode.kanban;

  static String _fmtDateDisplay(String dateStr) {
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.month}월 ${dt.day}일';
  }

  static bool _isPastDone(TodoItem t) {
    if (t.status != TodoStatus.done) return false;
    final dt = DateTime.tryParse(t.date);
    if (dt == null) return false;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return dt.isBefore(todayStart);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final asyncTodos = ref.watch(todoListProvider);

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '할 일 관리',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '할 일을 추가하고 상태를 변경하세요',
                    style: TextStyle(
                        fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              Row(
                children: [
                  SegmentedButton<TodoViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: TodoViewMode.kanban,
                        label: Text('칸반'),
                        icon: Icon(Icons.view_column_outlined, size: 18),
                      ),
                      ButtonSegment(
                        value: TodoViewMode.eisenhower,
                        label: Text('아이젼하워'),
                        icon: Icon(Icons.grid_4x4_outlined, size: 18),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (s) =>
                        setState(() => _viewMode = s.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (st) => st.contains(WidgetState.selected)
                            ? const Color(0xFF1F2937)
                            : null,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (st) => st.contains(WidgetState.selected)
                            ? Colors.white
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => showTodoAddDialog(context, ref),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text(
                      '새 할 일 추가',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: asyncTodos.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('오류가 발생했습니다: $e')),
              data: (todos) {
                if (_viewMode == TodoViewMode.eisenhower) {
                  return TodoEisenhowerBoard(todos: todos);
                }
                final tags = ref.watch(tagListProvider).value ??
                    [TagItem.defaultTag];
                final tagMap = {for (final t in tags) t.id: t};

                final today = DateTime.now();
                final todayStart =
                    DateTime(today.year, today.month, today.day);

                final todoItems = todos
                    .where((t) => t.status == TodoStatus.todo)
                    .toList();
                final inProgressItems = todos
                    .where((t) => t.status == TodoStatus.inProgress)
                    .toList();
                // 완료: 과거(어제 이전) done task 숨김
                final doneItems = todos.where((t) {
                  if (t.status != TodoStatus.done) return false;
                  final dt = DateTime.tryParse(t.date);
                  if (dt == null) return true;
                  return !dt.isBefore(todayStart);
                }).toList();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildKanbanColumn(
                      context: context,
                      ref: ref,
                      title: '해야 할 일',
                      status: TodoStatus.todo,
                      items: todoItems,
                      tagMap: tagMap,
                    ),
                    const SizedBox(width: 24),
                    _buildKanbanColumn(
                      context: context,
                      ref: ref,
                      title: '진행 중',
                      status: TodoStatus.inProgress,
                      items: inProgressItems,
                      tagMap: tagMap,
                    ),
                    const SizedBox(width: 24),
                    _buildKanbanColumn(
                      context: context,
                      ref: ref,
                      title: '완료',
                      status: TodoStatus.done,
                      items: doneItems,
                      tagMap: tagMap,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required TodoStatus status,
    required List<TodoItem> items,
    required Map<String, TagItem> tagMap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: DragTarget<TodoItem>(
        onAcceptWithDetails: (details) async {
          try {
            await ref
                .read(todoListProvider.notifier)
                .changeStatus(details.data.id, status);
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Container(
            decoration: BoxDecoration(
              color: isHovering
                  ? cs.primaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isHovering
                  ? Border.all(
                      color: cs.primary.withValues(alpha: 0.4), width: 2)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cs.onSurface)),
                      Text(items.length.toString(),
                          style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      ...items.map((item) =>
                          _buildDraggableTaskCard(context, ref, item, tagMap)),
                      if (status != TodoStatus.done)
                        _buildAddCardButton(context, ref, status),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDraggableTaskCard(
    BuildContext context,
    WidgetRef ref,
    TodoItem item,
    Map<String, TagItem> tagMap,
  ) {
    return Draggable<TodoItem>(
      data: item,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 280,
          child: _buildTaskCardContent(context, item, tagMap),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCardContent(context, item, tagMap),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => showTodoEditDialog(context, ref, item),
          borderRadius: BorderRadius.circular(12),
          child: _buildTaskCardContent(context, item, tagMap),
        ),
      ),
    );
  }

  Widget _buildTaskCardContent(
    BuildContext context,
    TodoItem item,
    Map<String, TagItem> tagMap,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tag = tagMap[item.tag] ?? TagItem.defaultTag;
    final tagColor = hexToColor(tag.colorHex);

    final dateLabel = _fmtDateDisplay(item.date);
    final timeLabel =
        item.time != null ? ' ${item.time}' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag.name,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$dateLabel$timeLabel',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddCardButton(
    BuildContext context,
    WidgetRef ref,
    TodoStatus status,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () =>
            showTodoAddDialog(context, ref, initialStatus: status),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: CustomPaintDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
            dashPattern: const [6, 4],
          ),
          child: Center(
            child: Text(
              '+ 카드 추가',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

// ── 점선 border decoration ──────────────────────────────────────────────────

class CustomPaintDecoration extends Decoration {
  final Border border;
  final BorderRadius borderRadius;
  final List<double> dashPattern;

  const CustomPaintDecoration({
    required this.border,
    required this.borderRadius,
    required this.dashPattern,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomPaintDecorationPainter(border, borderRadius, dashPattern);
  }
}

class _CustomPaintDecorationPainter extends BoxPainter {
  final Border border;
  final BorderRadius borderRadius;
  final List<double> dashPattern;

  _CustomPaintDecorationPainter(
      this.border, this.borderRadius, this.dashPattern);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final paint = Paint()
      ..color = border.top.color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(rect, borderRadius.topLeft);
    final path = Path()..addRRect(rrect);
    final dashPath = Path();
    double distance = 0.0;
    for (final metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashPattern[0]),
          Offset.zero,
        );
        distance += dashPattern[0] + dashPattern[1];
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }
}
