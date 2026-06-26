part of 'calender.dart';

// ── 드래그 데이터 래퍼 — 인스턴스 날짜 포함 ──────────────────────────────────
class _TodoDragData {
  final TodoItem todo;
  final String instanceDate; // "yyyy-MM-dd"
  const _TodoDragData(this.todo, this.instanceDate);
}

class _EventDragData {
  final EventItem event;
  final String instanceDate; // "yyyy-MM-dd"
  const _EventDragData(this.event, this.instanceDate);
}

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
  bool _shouldAnimate = false;
  final _clipKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
  }

  @override
  void didUpdateWidget(_TitleTimeRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title || oldWidget.time != widget.time) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkOverflow());
    }
  }

  // 제목 텍스트가 시간 영역에 가려지는지 측정 — 가려질 때만 애니메이션 허용
  void _checkOverflow() {
    if (!mounted || widget.time == null) return;
    final box = _clipKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final painter = TextPainter(
      text: TextSpan(text: widget.title, style: widget.titleStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: double.infinity);
    if (mounted) setState(() => _shouldAnimate = painter.width > box.size.width);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      onEnter: (_) { if (_shouldAnimate) _ctrl.forward(from: 0); },
      onExit: (_) { if (_shouldAnimate) _ctrl.reverse(); },
      child: Row(
        children: [
          Expanded(
            child: ClipRect(
              key: _clipKey,
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

    // 이벤트+할일 통합 리스트 — 시간 있는 항목 우선(시간순), 나머지는 추가순 유지
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
    final shownItems = allItems.take(4).toList();
    final hiddenCount = allItems.length - shownItems.length;

    // EventItem 드롭 처리 — 반복 일정은 해당 인스턴스만 이동
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
          await ref.read(eventListProvider.notifier).addEvent(EventItem(
                title: event.title,
                date: newDate,
                time: event.time,
                memo: event.memo,
                tag: event.tag,
                repeat: RepeatType.none,
                alarmTime: event.alarmTime,
              ));
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
      }
    }

    return DragTarget<_EventDragData>(
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
                await ref.read(todoListProvider.notifier).addTodo(TodoItem(
                      title: task.title,
                      date: newDate,
                      priority: task.priority,
                      tag: task.tag,
                      status: TodoStatus.todo,
                      time: task.time,
                      memo: task.memo,
                      repeat: RepeatType.none,
                      alarmTime: task.alarmTime,
                    ));
              }
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('저장에 실패했습니다: $e')));
            }
          },
          builder: (cellCtx, todoCandidates, _) {
            final isHovering =
                todoCandidates.isNotEmpty || eventCandidates.isNotEmpty;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Builder(
                builder: (builderCtx) => GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _showAddChoiceMenu(builderCtx, date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    decoration: BoxDecoration(
                      color: isHovering
                          ? cs.primaryContainer.withValues(alpha: 0.35)
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
                        // 이벤트+할일 통합 표시 (최대 4개, 시간순 우선)
                        ...shownItems.map((entry) {
                          if (entry.isEvent) {
                            return _buildEventBlock(
                                entry.data as EventItem, cs, eventTagMap, date);
                          }
                          final t = entry.data as TodoItem;
                          return _buildMonthBlock(t, tagMap, date,
                              isDone: t.isDoneOnDate(dateKey));
                        }),
                        // +more: 실제로 숨겨진 항목 수 기준
                        if (hiddenCount > 0)
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
                                  '+$hiddenCount more',
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
              onTap: () => showTodoEditDialog(context, ref, todo, instanceDate: date),
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

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<_TodoDragData>(
        data: _TodoDragData(todo, _fmtKey(date)),
        onDragStarted: _showTrashOverlay,
        onDragEnd: (_) => _hideTrashOverlay(),
        feedback: _buildDragFeedback(todo.title, color),
        childWhenDragging: Opacity(opacity: 0.4, child: blockContent),
        child: blockContent,
      ),
    );
  }

  /// 이벤트 블록 — 드래그 가능, 핀(9px·태그색), 시간 우측 고정.
  Widget _buildEventBlock(
    EventItem event,
    ColorScheme cs,
    Map<String, TagItem> eventTagMap,
    DateTime instanceDate,
  ) {
    final tag = eventTagMap[event.tag] ?? TagItem.defaultTag;
    final color = hexToColor(tag.colorHex);

    final innerContent = Container(
      margin: const EdgeInsets.fromLTRB(3, 1, 3, 1),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // 이벤트 구분 네모 — 할일 동그라미(11px)와 너비 맞춤
          SizedBox(
            width: 11,
            height: 11,
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _TitleTimeRow(
              title: event.title,
              time: event.time,
              titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
        ],
      ),
    );

    final blockContent = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showEventDialog(context, existing: event),
      child: innerContent,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Draggable<_EventDragData>(
        data: _EventDragData(event, _fmtKey(instanceDate)),
        onDragStarted: _showTrashOverlay,
        onDragEnd: (_) => _hideTrashOverlay(),
        feedback: _buildDragFeedback(event.title, color),
        childWhenDragging: Opacity(opacity: 0.4, child: blockContent),
        child: blockContent,
      ),
    );
  }
}
