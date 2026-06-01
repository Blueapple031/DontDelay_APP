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

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    '할 일 관리',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '할 일을 추가하고 상태를 변경하세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF6D28D9),
                      size: 18,
                    ),
                    label: const Text(
                      'AI 자동 분류',
                      style: TextStyle(color: Color(0xFF6D28D9)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6D28D9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
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
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          Expanded(
            child: asyncTodos.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류가 발생했습니다: $e')),
              data: (todos) {
                if (_viewMode == TodoViewMode.eisenhower) {
                  return TodoEisenhowerBoard(todos: todos);
                }
                final tags = ref.watch(tagListProvider).value ??
                    [TagItem.defaultTag];
                final tagMap = {
                  for (final t in tags) t.id: t
                };
                final todoItems =
                    todos.where((t) => t.status == TodoStatus.todo).toList();
                final inProgressItems = todos
                    .where((t) => t.status == TodoStatus.inProgress)
                    .toList();
                final doneItems =
                    todos.where((t) => t.status == TodoStatus.done).toList();

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
    return Expanded(
      child: DragTarget<TodoItem>(
        onAcceptWithDetails: (details) async {
          try {
            await ref
                .read(todoListProvider.notifier)
                .changeStatus(details.data.id, status);
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('저장에 실패했습니다: $e')),
            );
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return Container(
            decoration: BoxDecoration(
              color: isHovering
                  ? const Color(0xFFF3E8FF).withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isHovering
                  ? Border.all(
                      color: const Color(0xFF6D28D9)
                          .withValues(alpha: 0.3),
                      width: 2,
                    )
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        items.length.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      ...items.map(
                        (item) => _buildDraggableTaskCard(
                            context, ref, item, tagMap),
                      ),
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
          child: _buildTaskCardContent(item, tagMap),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCardContent(item, tagMap),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () => showTodoEditDialog(context, ref, item),
          borderRadius: BorderRadius.circular(12),
          child: _buildTaskCardContent(item, tagMap),
        ),
      ),
    );
  }

  Widget _buildTaskCardContent(
      TodoItem item, Map<String, TagItem> tagMap) {
    final tag = tagMap[item.tag] ?? TagItem.defaultTag;
    final tagColor = hexToColor(tag.colorHex);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.date,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 12),
          _buildBadge(
            tag.name,
            tagColor.withValues(alpha: 0.15),
            tagColor,
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
        onTap: () => showTodoAddDialog(context, ref, initialStatus: status),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: CustomPaintDecoration(
            border: Border.all(
              color: Colors.grey.shade400,
              style: BorderStyle.none,
            ),
            borderRadius: BorderRadius.circular(12),
            dashPattern: const [6, 4],
          ),
          child: const Center(
            child: Text(
              '+ 카드 추가',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

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
    this.border,
    this.borderRadius,
    this.dashPattern,
  );

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final paint = Paint()
      ..color = border.top.color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(rect, borderRadius.topLeft);

    Path path = Path()..addRRect(rrect);
    Path dashPath = Path();
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        double dashLength = dashPattern[0];
        double spaceLength = dashPattern[1];
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + spaceLength;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, paint);
  }
}
