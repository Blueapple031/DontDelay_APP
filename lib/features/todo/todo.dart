import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_model.dart';
import 'todo_provider.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    onPressed: () => _showAddTodoDialog(context, ref),
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
                    ),
                    const SizedBox(width: 24),
                    _buildKanbanColumn(
                      context: context,
                      ref: ref,
                      title: '진행 중',
                      status: TodoStatus.inProgress,
                      items: inProgressItems,
                    ),
                    const SizedBox(width: 24),
                    _buildKanbanColumn(
                      context: context,
                      ref: ref,
                      title: '완료',
                      status: TodoStatus.done,
                      items: doneItems,
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
                  ? const Color(0xFFF3E8FF).withOpacity(0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isHovering
                  ? Border.all(
                      color: const Color(0xFF6D28D9).withOpacity(0.3),
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
                        (item) => _buildDraggableTaskCard(context, ref, item),
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
  ) {
    final priorityColor = _getPriorityColor(item.priority);

    return Draggable<TodoItem>(
      data: item,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 280,
          child: _buildTaskCardContent(item, priorityColor),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCardContent(item, priorityColor),
      ),
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          _showContextMenu(context, ref, item, details.globalPosition);
        },
        child: _buildTaskCardContent(item, priorityColor),
      ),
    );
  }

  Widget _buildTaskCardContent(TodoItem item, Color priorityColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
          const SizedBox(height: 12),
          Text(
            item.date,
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBadge(
                item.priorityLabel,
                priorityColor.withOpacity(0.1),
                priorityColor,
              ),
              const SizedBox(width: 8),
              _buildBadge(
                item.tag,
                const Color(0xFFEEF2FF),
                const Color(0xFF6366F1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    WidgetRef ref,
    TodoItem item,
    Offset position,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        if (item.status != TodoStatus.todo)
          const PopupMenuItem(value: 'todo', child: Text('→ 해야 할 일로 이동')),
        if (item.status != TodoStatus.inProgress)
          const PopupMenuItem(value: 'inProgress', child: Text('→ 진행 중으로 이동')),
        if (item.status != TodoStatus.done)
          const PopupMenuItem(value: 'done', child: Text('→ 완료로 이동')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text('삭제', style: TextStyle(color: Colors.red)),
        ),
      ],
    ).then((value) async {
      if (value == null || !context.mounted) return;
      try {
        if (value == 'delete') {
          await ref.read(todoListProvider.notifier).deleteTodo(item.id);
        } else {
          final newStatus = TodoStatus.values.byName(value);
          await ref
              .read(todoListProvider.notifier)
              .changeStatus(item.id, newStatus);
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장에 실패했습니다: $e')),
        );
      }
    });
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
        onTap: () => _showAddTodoDialog(context, ref, initialStatus: status),
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

  void _showAddTodoDialog(
    BuildContext context,
    WidgetRef ref, {
    TodoStatus initialStatus = TodoStatus.todo,
  }) {
    final titleController = TextEditingController();
    final tagController = TextEditingController();
    TodoPriority selectedPriority = TodoPriority.medium;
    TodoStatus selectedStatus = initialStatus;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                '새 할 일 추가',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: '할 일 제목',
                        hintText: '예: 운영체제 3단원 복습',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF6D28D9)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    TextField(
                      controller: tagController,
                      decoration: InputDecoration(
                        labelText: '태그',
                        hintText: '예: 학습, 과제, 프로젝트',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF6D28D9)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 날짜 선택
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 우선순위 선택
                    const Text(
                      '우선순위',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: TodoPriority.values.map((p) {
                        final isSelected = selectedPriority == p;
                        final color = _getPriorityColor(p);
                        final label = switch (p) {
                          TodoPriority.high => '높음',
                          TodoPriority.medium => '보통',
                          TodoPriority.low => '낮음',
                        };
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (_) {
                              setDialogState(() => selectedPriority = p);
                            },
                            selectedColor: color.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? color : Colors.grey.shade600,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: isSelected ? color : Colors.grey.shade300,
                              ),
                            ),
                            showCheckmark: false,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    // 상태 선택
                    const Text(
                      '상태',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(
                          '해야 할 일',
                          TodoStatus.todo,
                          selectedStatus,
                          (s) => setDialogState(() => selectedStatus = s),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          '진행 중',
                          TodoStatus.inProgress,
                          selectedStatus,
                          (s) => setDialogState(() => selectedStatus = s),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusChip(
                          '완료',
                          TodoStatus.done,
                          selectedStatus,
                          (s) => setDialogState(() => selectedStatus = s),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '취소',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) return;

                    final dateStr =
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

                    final newTodo = TodoItem(
                      title: title,
                      date: dateStr,
                      priority: selectedPriority,
                      tag: tagController.text.trim().isEmpty
                          ? '일반'
                          : tagController.text.trim(),
                      status: selectedStatus,
                    );

                    try {
                      await ref
                          .read(todoListProvider.notifier)
                          .addTodo(newTodo);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('저장에 실패했습니다: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  child: const Text(
                    '추가',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(
    String label,
    TodoStatus status,
    TodoStatus selectedStatus,
    void Function(TodoStatus) onSelected,
  ) {
    final isSelected = status == selectedStatus;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(status),
      selectedColor: const Color(0xFF6D28D9).withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF6D28D9) : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? const Color(0xFF6D28D9) : Colors.grey.shade300,
        ),
      ),
      showCheckmark: false,
    );
  }

  Color _getPriorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.high:
        return Colors.red;
      case TodoPriority.medium:
        return Colors.orange;
      case TodoPriority.low:
        return Colors.green;
    }
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
