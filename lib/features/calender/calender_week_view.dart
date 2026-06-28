part of 'calender.dart';

extension _CalendarWeekView on _CalendarScreenState {
  Widget _buildSevenDaysView(
    List<TodoItem> todos,
    List<EventItem> events,
    Map<String, TagItem> tagMap,
    Map<String, TagItem> eventTagMap,
  ) {
    final cs = Theme.of(context).colorScheme;
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: const WidgetStatePropertyAll(true),
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(3),
        thumbColor: WidgetStatePropertyAll(
          cs.onSurface.withValues(alpha: 0.22),
        ),
        trackColor: WidgetStatePropertyAll(
          cs.onSurface.withValues(alpha: 0.06),
        ),
        trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      child: Scrollbar(
        controller: _weekHScrollCtrl,
        child: SingleChildScrollView(
          controller: _weekHScrollCtrl,
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
    );
  }

  Widget _buildWeekCardFeedback({
    required bool isEvent,
    required String title,
    required String? tagName,
    required Color tagColor,
    required String? time,
    bool isDone = false,
  }) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      shadowColor: Colors.black26,
      child: Container(
        width: 230,
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: tagColor.withValues(alpha: 0.45),
            width: 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (isEvent)
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: tagColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              )
            else
              Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18,
                color: isDone ? Colors.grey.shade500 : Colors.grey.shade400,
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tagName != null && tagName.isNotEmpty)
                    Text(
                      tagName,
                      style: TextStyle(
                        fontSize: 10,
                        color: tagColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDone
                          ? Colors.grey.shade400
                          : const Color(0xFF1F2937),
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (time != null) ...[
              const SizedBox(width: 6),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: Color(0x73000000)),
              ),
            ],
          ],
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

    final allItems = <({bool isEvent, Object data, String? time})>[
      for (final e in events) (isEvent: true, data: e, time: e.time),
      for (final t in todos) (isEvent: false, data: t, time: t.time),
    ];
    allItems.sort((a, b) {
      if (a.time != null && b.time != null) return a.time!.compareTo(b.time!);
      if (a.time != null) return -1;
      if (b.time != null) return 1;
      return 0;
    });

    Future<void> handleEventDrop(_EventDragData payload) async {
      final event = payload.event;
      final instanceDate = payload.instanceDate;
      final newDate = _fmtKey(date);
      if (instanceDate == newDate) return;
      try {
        if (event.repeat == RepeatType.none) {
          await ref
              .read(eventListProvider.notifier)
              .updateEvent(event.copyWith(date: newDate));
        } else {
          await ref
              .read(eventListProvider.notifier)
              .addDeletedOverride(event.id, instanceDate);
          await ref
              .read(eventListProvider.notifier)
              .addEvent(
                EventItem(
                  title: event.title,
                  date: newDate,
                  time: event.time,
                  memo: event.memo,
                  tag: event.tag,
                  repeat: RepeatType.none,
                  alarmTime: event.alarmTime,
                ),
              );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
      }
    }

    return SizedBox(
      width: 270,
      child: Container(
        margin: const EdgeInsets.only(right: 24),
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
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isToday ? const Color(0xFF1F2937) : cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${date.month}/${date.day}',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),
            DragTarget<_EventDragData>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (d) => handleEventDrop(d.data),
              builder: (_, eventCandidates, __) {
                return DragTarget<_TodoDragData>(
                  onWillAcceptWithDetails: (_) => true,
                  onAcceptWithDetails: (details) async {
                    _hideTrashOverlay();
                    final payload = details.data;
                    final task = payload.todo;
                    final instanceDate = payload.instanceDate;
                    final newDate = _fmtKey(date);
                    if (instanceDate == newDate) return;
                    try {
                      if (task.repeat == RepeatType.none) {
                        await ref
                            .read(todoListProvider.notifier)
                            .updateTodo(task.copyWith(date: newDate));
                      } else {
                        await ref
                            .read(todoListProvider.notifier)
                            .addDeletedOverride(task.id, instanceDate);
                        await ref
                            .read(todoListProvider.notifier)
                            .addTodo(
                              TodoItem(
                                title: task.title,
                                date: newDate,
                                priority: task.priority,
                                tag: task.tag,
                                status: TodoStatus.todo,
                                time: task.time,
                                memo: task.memo,
                                repeat: RepeatType.none,
                                alarmTime: task.alarmTime,
                              ),
                            );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
                    }
                  },
                  builder: (ctx, todoCandidates, _) {
                    final isHovering =
                        todoCandidates.isNotEmpty || eventCandidates.isNotEmpty;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        color: isHovering
                            ? cs.primaryContainer.withValues(alpha: 0.5)
                            : Colors.transparent,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(11),
                        ),
                      ),
                      child: Padding(
                        padding: allItems.isEmpty
                            ? const EdgeInsets.fromLTRB(10, 20, 10, 14)
                            : const EdgeInsets.fromLTRB(10, 10, 10, 4),
                        child: Column(
                          children: [
                            for (final item in allItems)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: item.isEvent
                                    ? _buildWeekEventCard(
                                        item.data as EventItem,
                                        cs,
                                        eventTagMap,
                                        date,
                                      )
                                    : _buildSevenDayCard(
                                        item.data as TodoItem,
                                        tagMap,
                                        date,
                                        (item.data as TodoItem).isDoneOnDate(
                                          dateKey,
                                        ),
                                      ),
                              ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: TextButton(
                                onPressed: () => showUnifiedAddDialog(
                                  context,
                                  ref,
                                  initialDate: date,
                                ),
                                style: TextButton.styleFrom(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 6,
                                  ),
                                ),
                                child: Text(
                                  '+ADD',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
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

  Widget _buildWeekEventCard(
    EventItem event,
    ColorScheme cs,
    Map<String, TagItem> eventTagMap,
    DateTime instanceDate,
  ) {
    final tag = eventTagMap[event.tag] ?? TagItem.defaultTag;
    final color = hexToColor(tag.colorHex);

    final cardContent = Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
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
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showEventDialog(context, existing: event),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                    event.title,
                    style: TextStyle(fontSize: 13, color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (event.time != null) ...[
            const SizedBox(width: 6),
            Text(
              event.time!,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ],
      ),
    );

    final feedback = _buildWeekCardFeedback(
      isEvent: true,
      title: event.title,
      tagName: tag.name,
      tagColor: color,
      time: event.time,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<_EventDragData>(
        data: _EventDragData(event, _fmtKey(instanceDate)),
        onDragStarted: _showTrashOverlay,
        onDragEnd: (_) => _hideTrashOverlay(),
        feedback: feedback,
        childWhenDragging: Opacity(opacity: 0.35, child: cardContent),
        child: cardContent,
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
    final tag =
        tagMap[todo.tag] ?? tagMap[TagItem.defaultId] ?? TagItem.defaultTag;
    final color = hexToColor(tag.colorHex);
    final dateKey = _fmtKey(date);

    final cardContent = Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
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
                  await ref
                      .read(todoListProvider.notifier)
                      .changeStatus(
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
              }
            },
            child: Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 18,
              color: isDone ? Colors.grey.shade500 : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  showTodoEditDialog(context, ref, todo, instanceDate: date),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                      color: isDone ? Colors.grey.shade400 : cs.onSurface,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: Colors.grey.shade400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (todo.time != null) ...[
            const SizedBox(width: 6),
            Text(
              todo.time!,
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: isDone ? 0.3 : 0.45),
              ),
            ),
          ],
        ],
      ),
    );

    final feedback = _buildWeekCardFeedback(
      isEvent: false,
      title: todo.title,
      tagName: tag.name,
      tagColor: color,
      time: todo.time,
      isDone: isDone,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<_TodoDragData>(
        data: _TodoDragData(todo, _fmtKey(date)),
        onDragStarted: _showTrashOverlay,
        onDragEnd: (_) => _hideTrashOverlay(),
        feedback: feedback,
        childWhenDragging: Opacity(opacity: 0.35, child: cardContent),
        child: cardContent,
      ),
    );
  }
}
