part of 'calender.dart';

// ── 이름(왼쪽) + 시간(오른쪽) 레이아웃 위젯 ─────────────────────────────────
// 시간이 있을 때: 오른쪽 고정, 이름 왼쪽 잘림.
// 호버 시 이름이 왼쪽으로 천천히 스크롤되어 전체 이름 확인 가능.
class _TitleTimeRow extends StatefulWidget {
  final String title;
  final String? time;
  final TextStyle titleStyle;

  const _TitleTimeRow({
    required this.title,
    required this.time,
    required this.titleStyle,
  });

  @override
  State<_TitleTimeRow> createState() => _TitleTimeRowState();
}

class _TitleTimeRowState extends State<_TitleTimeRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    // CurvedAnimation을 한 번만 생성 (매 프레임 생성 방지)
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 시간 없으면 단순 truncated 텍스트
    if (widget.time == null) {
      return Text(
        widget.title,
        style: widget.titleStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final timeStyle = widget.titleStyle.copyWith(
      color: (widget.titleStyle.color ?? Colors.black87)
          .withValues(alpha: 0.55),
      fontWeight: FontWeight.w400,
    );

    return MouseRegion(
      onEnter: (_) => _ctrl.forward(from: 0),
      onExit: (_) => _ctrl.reverse(),
      child: Row(
        children: [
          // 이름: 남은 공간에서 잘림, 호버 시 80px 왼쪽 스크롤.
          // LayoutBuilder 대신 고정 스크롤 사용 — IntrinsicHeight 내부 호환
          Expanded(
            child: ClipRect(
              child: AnimatedBuilder(
                animation: _curve,
                builder: (_, child) => Transform.translate(
                  offset: Offset(-80.0 * _curve.value, 0),
                  child: child,
                ),
                child: Text(
                  widget.title,
                  style: widget.titleStyle,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          // 시간: 우선순위로 오른쪽 고정
          Text(widget.time!, style: timeStyle),
        ],
      ),
    );
  }
}

// ── Month View Extension ──────────────────────────────────────────────────────

extension _CalendarMonthView on _CalendarScreenState {
  Widget _buildMonthView(
    List<TodoItem> todos,
    List<EventItem> events,
    Map<String, TagItem> tagMap,
    Map<String, TagItem> eventTagMap,
  ) {
    final first = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final offset = first.weekday % 7;
    final gridStart = first.subtract(Duration(days: offset));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 요일 헤더 (일 ~ 토)
        Row(
          children: const ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
              .map((d) => Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: Colors.grey.shade200))),
                      alignment: Alignment.center,
                      child: Text(d,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 125, 122, 122),
                            letterSpacing: 0.5,
                          )),
                    ),
                  ))
              .toList(),
        ),
        // 날짜 그리드
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              const rowCount = 5;
              final rowH = constraints.maxHeight / rowCount;
              return Column(
                children: List.generate(rowCount, (row) {
                  return SizedBox(
                    height: rowH,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(7, (col) {
                        final date =
                            gridStart.add(Duration(days: row * 7 + col));
                        final dayTodos = _todosForDate(todos, date);
                        final dayEvents = _eventsForDate(events, date);
                        return Expanded(
                          child: _buildMonthCell(
                            date: date,
                            inMonth: date.month == _focusedDate.month,
                            isToday: _sameDay(date, _today),
                            todos: dayTodos,
                            events: dayEvents,
                            tagMap: tagMap,
                            eventTagMap: eventTagMap,
                          ),
                        );
                      }),
                    ),
                  );
                }),
              );
            },
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
    required List<EventItem> events,
    required Map<String, TagItem> tagMap,
    required Map<String, TagItem> eventTagMap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final dateKey = _fmtKey(date);
    final totalCount = todos.length + events.length;

    // EventItem 드롭 처리
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

    return DragTarget<EventItem>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => handleEventDrop(d.data),
      builder: (_, eventCandidates, __) {
        return DragTarget<TodoItem>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (details) async {
            _hideTrashOverlay();
            final newDate = _fmtKey(date);
            final allTodos = ref.read(todoListProvider).value ?? [];
            final tasksToDrop = _selectedTaskIds.isNotEmpty &&
                    _selectedTaskIds.contains(details.data.id)
                ? allTodos
                    .where((t) => _selectedTaskIds.contains(t.id))
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
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('저장에 실패했습니다: $e')));
              }
            }
            setState(() => _selectedTaskIds.clear());
          },
          builder: (cellCtx, todoCandidates, _) {
            final isHovering =
                todoCandidates.isNotEmpty || eventCandidates.isNotEmpty;
            final cursor = _isMoveMode && _selectedTaskIds.isNotEmpty
                ? SystemMouseCursors.move
                : SystemMouseCursors.click;
            return MouseRegion(
              cursor: cursor,
              child: Builder(
                builder: (builderCtx) => GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _showAddChoiceMenu(builderCtx, date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      color: isHovering
                          ? cs.primaryContainer.withValues(alpha: 0.35)
                          : _isMoveMode && _selectedTaskIds.isNotEmpty
                              ? cs.primaryContainer.withValues(alpha: 0.08)
                              : Colors.transparent,
                      border: Border(
                        right: BorderSide(color: Colors.grey.shade200),
                        bottom: BorderSide(color: Colors.grey.shade200),
                        left: isHovering
                            ? const BorderSide(
                                color: Color(0xFF1F2937), width: 2)
                            : BorderSide.none,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 날짜 숫자
                        Padding(
                          padding: const EdgeInsets.fromLTRB(5, 3, 5, 1),
                          child: isToday
                              ? Container(
                                  width: 18,
                                  height: 18,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1F2937),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${date.day}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10)),
                                )
                              : Text('${date.day}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: inMonth
                                        ? cs.onSurface
                                        : Colors.grey.shade400,
                                  )),
                        ),
                        // 이벤트 (최대 1개)
                        ...events
                            .take(1)
                            .map((e) =>
                                _buildEventBlock(e, cs, eventTagMap)),
                        // task (이벤트 없으면 4개, 있으면 3개)
                        ...todos
                            .take(events.isEmpty ? 4 : 3)
                            .map((t) => _buildMonthBlock(t, tagMap, date,
                                isDone: t.isDoneOnDate(dateKey))),
                        // +more
                        if (totalCount > 4)
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            onEnter: (_) => _scheduleOverflowPopup(
                                builderCtx, date, todos, events, tagMap),
                            onExit: (_) => _cancelHoverTimer(),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _showOverflowPopup(
                                  builderCtx, date, todos, events, tagMap),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(5, 1, 5, 2),
                                child: Text(
                                  '+${totalCount - 4} more',
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthBlock(
    TodoItem todo,
    Map<String, TagItem> tagMap,
    DateTime date, {
    required bool isDone,
  }) {
    final tag = tagMap[todo.tag] ?? TagItem.defaultTag;
    final color = hexToColor(tag.colorHex);
    final dateKey = _fmtKey(date);
    final isSelected = _selectedTaskIds.contains(todo.id);

    final titleStyle = TextStyle(
      fontSize: 11,
      color: isDone ? Colors.grey.shade400 : Colors.black87,
      decoration:
          isDone ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: Colors.grey.shade400,
    );

    final blockContent = Container(
      margin: const EdgeInsets.fromLTRB(3, 1, 3, 1),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDone ? 0.06 : 0.13),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(
              color: color.withValues(alpha: isDone ? 0.4 : 1), width: 2.5),
          top: isSelected
              ? const BorderSide(color: Color(0xFF1F2937), width: 1)
              : BorderSide.none,
          right: isSelected
              ? const BorderSide(color: Color(0xFF1F2937), width: 1)
              : BorderSide.none,
          bottom: isSelected
              ? const BorderSide(color: Color(0xFF1F2937), width: 1)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // 완료 토글
          GestureDetector(
            behavior: HitTestBehavior.opaque,
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
              size: 11,
              color:
                  isDone ? color.withValues(alpha: 0.5) : Colors.black38,
            ),
          ),
          const SizedBox(width: 3),
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
              child: _TitleTimeRow(
                title: todo.title,
                time: todo.time,
                titleStyle: titleStyle,
              ),
            ),
          ),
        ],
      ),
    );

    final isMultiSelected = isSelected && _selectedTaskIds.length > 1;

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<TodoItem>(
        data: todo,
        onDragStarted: _showTrashOverlay,
        onDragEnd: (_) => _hideTrashOverlay(),
        feedback: isMultiSelected
            ? _buildStackedFeedback(todo.title, _selectedTaskIds.length, color)
            : _buildDragFeedback(todo.title, color),
        childWhenDragging: Opacity(opacity: 0.4, child: blockContent),
        child: (_isMoveMode || _isDragging) && isSelected ? Opacity(opacity: 0.4, child: blockContent) : blockContent,
      ),
    );
  }

  /// 이벤트 블록 — 드래그 가능, 핀(9px·태그색), 시간 우측 고정.
  Widget _buildEventBlock(
    EventItem event,
    ColorScheme cs,
    Map<String, TagItem> eventTagMap,
  ) {
    final tag = eventTagMap[event.tag] ?? TagItem.defaultTag;
    final color = hexToColor(tag.colorHex);
    final isSelected = _selectedTaskIds.contains(event.id);

    final innerContent = Padding(
      padding: const EdgeInsets.fromLTRB(5, 1, 5, 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 핀: 9px, task 완료토글(11px)과 동일선상
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TitleTimeRow(
              title: event.title,
              time: event.time,
              titleStyle: TextStyle(fontSize: 11, color: cs.onSurface),
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
        childWhenDragging: Opacity(opacity: 0.4, child: blockContent),
        child: (_isMoveMode || _isDragging) && isSelected ? Opacity(opacity: 0.4, child: blockContent) : blockContent,
      ),
    );
  }
}
