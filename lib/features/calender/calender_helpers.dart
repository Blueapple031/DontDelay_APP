part of 'calender.dart';

// 날짜 → "yyyy-MM-dd" 키 변환
String _fmtKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// 같은 날인지 비교
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

extension _CalendarStateHelpers on _CalendarScreenState {
  // ── 날짜별 데이터 필터 ───────────────────────────────────────────

  List<TodoItem> _todosForDate(List<TodoItem> todos, DateTime date) =>
      todos.where((t) {
        try {
          return t.isActiveOnDate(date);
        } catch (_) {
          return false;
        }
      }).toList();

  List<EventItem> _eventsForDate(List<EventItem> events, DateTime date) {
    final key = _fmtKey(date);
    return events.where((e) => e.isActiveOnDate(date) || e.date == key).toList();
  }

  // ── 헤더 탐색 ───────────────────────────────────────────────────

  void _prev() => setState(() {
        _focusedDate = _viewMode == _CalViewMode.month
            ? DateTime(_focusedDate.year, _focusedDate.month - 1, 1)
            : _focusedDate.subtract(const Duration(days: 7));
      });

  void _next() => setState(() {
        _focusedDate = _viewMode == _CalViewMode.month
            ? DateTime(_focusedDate.year, _focusedDate.month + 1, 1)
            : _focusedDate.add(const Duration(days: 7));
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

  // ── 멀티셀렉 ────────────────────────────────────────────────────

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedTaskIds.contains(id)) {
        _selectedTaskIds.remove(id);
        if (_selectedTaskIds.isEmpty) {
          _isMoveMode = false;
          _hideMoveOverlay();
          return;
        }
      } else {
        _selectedTaskIds.add(id);
        _isMoveMode = true;
      }
    });
    _showMoveOverlay();
  }

  void _clearSelect() {
    _hideMoveOverlay();
    setState(() {
      _selectedTaskIds.clear();
      _isMoveMode = false;
    });
  }

  // ── ctrl+클릭 이동 오버레이 ──────────────────────────────────────

  void _showMoveOverlay() {
    _hideMoveOverlay();
    if (_selectedTaskIds.isEmpty) return;
    final allTodos = ref.read(todoListProvider).value ?? [];
    final allEvents = ref.read(eventListProvider).value ?? [];
    
    TodoItem? leadTodo;
    EventItem? leadEvent;
    
    for (final id in _selectedTaskIds) {
      final t = allTodos.where((x) => x.id == id).firstOrNull;
      if (t != null) { leadTodo = t; break; }
      final e = allEvents.where((x) => x.id == id).firstOrNull;
      if (e != null) { leadEvent = e; break; }
    }

    if (leadTodo == null && leadEvent == null) return;

    String leadTitle = '';
    Color leadColor = Colors.grey;

    if (leadTodo != null) {
      leadTitle = leadTodo.title;
      final tags = ref.read(tagListProvider).value ?? [TagItem.defaultTag];
      final tagMap = {for (final t in tags) t.id: t};
      final leadTag = tagMap[leadTodo.tag] ?? TagItem.defaultTag;
      leadColor = hexToColor(leadTag.colorHex);
    } else if (leadEvent != null) {
      leadTitle = leadEvent.title;
      final tags = ref.read(eventTagListProvider).value ?? [TagItem.defaultTag];
      final tagMap = {for (final t in tags) t.id: t};
      final leadTag = tagMap[leadEvent.tag] ?? TagItem.defaultTag;
      leadColor = hexToColor(leadTag.colorHex);
    }

    _moveOverlay = OverlayEntry(builder: (_) {
      return Positioned(
        left: _cursorPos.dx,
        top: _cursorPos.dy,
        child: IgnorePointer(
          child: _selectedTaskIds.length > 1
              ? _buildStackedFeedback(leadTitle, _selectedTaskIds.length, leadColor)
              : _buildDragFeedback(leadTitle, leadColor),
        ),
      );
    });
    Overlay.of(context).insert(_moveOverlay!);
  }

  void _hideMoveOverlay() {
    _moveOverlay?.remove();
    _moveOverlay = null;
  }

  // ── ctrl+클릭 이동 모드: 선택된 task를 날짜로 이동 ────────────────

  Future<void> _moveSelectedTasksTo(DateTime date) async {
    _hideMoveOverlay();
    final newDate = _fmtKey(date);
    final allTodos = ref.read(todoListProvider).value ?? [];
    final toMoveTodos =
        allTodos.where((t) => _selectedTaskIds.contains(t.id)).toList();

    for (final task in toMoveTodos) {
      if (task.date == newDate && task.repeat == RepeatType.none) continue;
      try {
        await ref
            .read(todoListProvider.notifier)
            .updateTodo(task.copyWith(date: newDate));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
      }
    }

    final allEvents = ref.read(eventListProvider).value ?? [];
    final toMoveEvents =
        allEvents.where((e) => _selectedTaskIds.contains(e.id)).toList();

    for (final event in toMoveEvents) {
      if (event.date == newDate && event.repeat == RepeatType.none) continue;
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
    setState(() {
      _selectedTaskIds.clear();
      _isMoveMode = false;
    });
  }

  // ── 드래그 통일 피드백 ─────────────────────────────────

  /// 단일/다중 드래그 피드백 통일 스타일 (배지/스택 없음)
  Widget _buildDragFeedback(String title, Color tagColor) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 150,
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: tagColor, width: 2.5)),
        ),
        child: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
      ),
    );
  }

  /// 다중 드래그 겹쳐진 피드백
  Widget _buildStackedFeedback(String leadTitle, int count, Color tagColor) {
    final layers = min(count - 1, 2);
    return SizedBox(
      width: 150 + layers * 3.0,
      height: 32 + layers * 3.0,
      child: Stack(
        children: [
          for (var i = layers; i >= 1; i--)
            Positioned(
              top: i * 3.0,
              left: i * 3.0,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 150,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(left: BorderSide(color: tagColor, width: 2.5)),
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 150,
                height: 32,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                      left: BorderSide(color: tagColor, width: 2.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(leadTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w500,
                              color: Colors.black87)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('+$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 다이얼로그 호출 ──────────────────────────────────────────────

  /// 이벤트 수정/추가 다이얼로그
  void _showEventDialog(BuildContext ctx,
      {EventItem? existing, DateTime? initialDate}) {
    if (existing != null) {
      showEventEditDialog(context, ref, existing, instanceDate: initialDate);
    } else {
      showUnifiedAddDialog(context, ref,
          initialDate: initialDate, startAsEvent: true);
    }
  }

  /// 캘린더 셀 클릭 → 통합 추가 다이얼로그 (이동 모드일 때는 이동 처리)
  void _showAddChoiceMenu(BuildContext ctx, DateTime date) {
    if (_isMoveMode && _selectedTaskIds.isNotEmpty) {
      _moveSelectedTasksTo(date);
      return;
    }
    showUnifiedAddDialog(context, ref, initialDate: date);
  }
}
