part of 'calender.dart';

extension _CalendarWeekView on _CalendarScreenState {
  Widget _buildSevenDaysView(
    List<TodoItem> todos,
    List<EventItem> events,
    Map<String, TagItem> tagMap,
    Map<String, TagItem> eventTagMap,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(7, (i) {
              final date = _focusedDate.add(Duration(days: i));
              final isToday = _sameDay(date, _today);
              final dayTodos = _todosForDate(todos, date);
              final dayEvents = _eventsForDate(events, date);
              return _buildDayColumn(
                date: date,
                isToday: isToday,
                todos: dayTodos,
                events: dayEvents,
                tagMap: tagMap,
                eventTagMap: eventTagMap,
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDayColumn({
    required DateTime date,
    required bool isToday,
    required List<TodoItem> todos,
    required List<EventItem> events,
    required Map<String, TagItem> tagMap,
    required Map<String, TagItem> eventTagMap,
  }) {
    final cs = Theme.of(context).colorScheme;
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final diff = date.difference(_today).inDays;
    final label = diff == 0
        ? '오늘'
        : diff == 1
            ? '내일'
            : weekdays[date.weekday - 1];
    final dateKey = _fmtKey(date);

    Future<void> handleEventDrop(EventItem event) async {
      final newDate = _fmtKey(date);
      if (event.date == newDate && event.repeat == RepeatType.none) return;
      try {
        await ref
            .read(eventListProvider.notifier)
            .updateEvent(event.copyWith(date: newDate));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
      }
    }

    return SizedBox(
      width: 270,
      child: Container(
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday
                ? const Color(0xFF1F2937).withValues(alpha: 0.35)
                : cs.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? const Color(0xFF1F2937)
                            : cs.onSurface,
                      )),
                  const SizedBox(width: 6),
                  Text('${date.month}/${date.day}',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),
            DragTarget<EventItem>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (d) => handleEventDrop(d.data),
              builder: (_, eventCandidates, __) {
                return DragTarget<TodoItem>(
                  onWillAcceptWithDetails: (_) => true,
                  onAcceptWithDetails: (details) async {
                    _hideTrashOverlay();
                    final newDate = _fmtKey(date);
                    final allTodos =
                        ref.read(todoListProvider).value ?? [];
                    final tasksToDrop = _selectedTaskIds.isNotEmpty &&
                            _selectedTaskIds.contains(details.data.id)
                        ? allTodos
                            .where(
                                (t) => _selectedTaskIds.contains(t.id))
                            .toList()
                        : [details.data];
                    for (final task in tasksToDrop) {
                      if (task.date == newDate &&
                          task.repeat == RepeatType.none) continue;
                      try {
                        await ref
                            .read(todoListProvider.notifier)
                            .updateTodo(task.copyWith(date: newDate));
                      } catch (e) {
                        if (!mounted) { return; }
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('저장에 실패했습니다: $e')));
                      }
                    }
                    setState(() => _selectedTaskIds.clear());
                  },
                  builder: (ctx, todoCandidates, _) {
                    final isHovering = todoCandidates.isNotEmpty ||
                        eventCandidates.isNotEmpty;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        color: isHovering
                            ? cs.primaryContainer
                                .withValues(alpha: 0.5)
                            : Colors.transparent,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(11)),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(10, 10, 10, 4),
                        child: Column(
                          children: [
                            ...events.map((e) =>
                                _buildWeekEventCard(e, cs, eventTagMap)),
                            ...todos.map((t) => _buildSevenDayCard(
                                t, tagMap, date,
                                t.isDoneOnDate(dateKey))),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: TextButton.icon(
                                onPressed: () => showTodoAddDialog(
                                    context, ref,
                                    initialDate: date),
                                icon: Icon(Icons.add,
                                    size: 14,
                                    color: cs.onSurfaceVariant),
                                label: Text('Add Task',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurfaceVariant)),
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
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 주간 뷰 이벤트 카드 — 드래그 가능, 태그색 핀, 시간 우측 고정.
  Widget _buildWeekEventCard(
    EventItem event,
    ColorScheme cs,
    Map<String, TagItem> eventTagMap,
  ) {
    final tag = eventTagMap[event.tag] ?? TagItem.defaultTag;
    final color = hexToColor(tag.colorHex);
    final isSelected = _selectedTaskIds.contains(event.id);

    final innerContent = Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TitleTimeRow(
              title: event.title,
              time: event.time,
              titleStyle: TextStyle(fontSize: 12, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );

    final blockContent = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (HardwareKeyboard.instance.isControlPressed) {
          _toggleSelect(event.id);
        } else {
          _clearSelect();
          _showEventDialog(context, existing: event);
        }
      },
      child: innerContent,
    );

    final isMultiSelected = isSelected && _selectedTaskIds.length > 1;

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<EventItem>(
        data: event,
        onDragStarted: _showTrashOverlay,
        onDragEnd: (_) => _hideTrashOverlay(),
        feedback: isMultiSelected
            ? _buildStackedFeedback(event.title, _selectedTaskIds.length, color)
            : _buildDragFeedback(event.title, color),
        childWhenDragging: Opacity(opacity: 0.35, child: blockContent),
        child: (_isMoveMode || _isDragging) && isSelected ? Opacity(opacity: 0.35, child: blockContent) : blockContent,
      ),
    );
  }

  Widget _buildSevenDayCard(
    TodoItem todo,
    Map<String, TagItem> tagMap,
    DateTime date,
    bool isDone,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tag = tagMap[todo.tag] ?? TagItem.defaultTag;
    final color = hexToColor(tag.colorHex);
    final dateKey = _fmtKey(date);
    final isSelected = _selectedTaskIds.contains(todo.id);
    final isMultiSelected = isSelected && _selectedTaskIds.length > 1;

    final cardContent = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF1F2937).withValues(alpha: 0.07)
            : cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isSelected ? const Color(0xFF1F2937) : cs.outlineVariant,
          width: isSelected ? 1.5 : 1,
        ),
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
          GestureDetector(
            onTap: () async {
              try {
                if (todo.repeat == RepeatType.none) {
                  await ref.read(todoListProvider.notifier).changeStatus(
                        todo.id,
                        isDone ? TodoStatus.todo : TodoStatus.done,
                      );
                } else {
                  await ref
                      .read(todoListProvider.notifier)
                      .toggleDoneOverride(todo.id, dateKey);
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('저장에 실패했습니다: $e')));
              }
            },
            child: Icon(
              isDone
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 18,
              color: isDone
                  ? Colors.grey.shade500
                  : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (HardwareKeyboard.instance.isControlPressed) {
                  _toggleSelect(todo.id);
                } else {
                  _clearSelect();
                  showTodoEditDialog(context, ref, todo,
                      instanceDate: date);
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tag.name.isNotEmpty)
                    Text(tag.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  _TitleTimeRow(
                    title: todo.title,
                    time: todo.time,
                    titleStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          isDone ? Colors.grey.shade400 : cs.onSurface,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: Colors.grey.shade400,
                    ),
                  ),
                ],
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
                  onTap: () => showTodoEditDialog(context, ref, todo,
                      instanceDate: date)),
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('삭제',
                      style: TextStyle(color: Colors.red))),
            ],
            onSelected: (v) async {
              if (v == 'delete') await _handleTrashDrop(todo, date);
            },
          ),
        ],
      ),
    );


    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<TodoItem>(
        data: todo,
        onDragStarted: _showTrashOverlay,
        onDragEnd: (_) => _hideTrashOverlay(),
        feedback: isMultiSelected
            ? _buildStackedFeedback(todo.title, _selectedTaskIds.length, color)
            : _buildDragFeedback(todo.title, color),
        childWhenDragging: Opacity(opacity: 0.35, child: cardContent),
        child: (_isMoveMode || _isDragging) && isSelected ? Opacity(opacity: 0.35, child: cardContent) : cardContent,
      ),
    );
  }
}
