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

  List<EventItem> _eventsForDate(List<EventItem> events, DateTime date) =>
      events.where((e) => e.isActiveOnDate(date)).toList();

  // ── 헤더 탐색 ───────────────────────────────────────────────────

  // ignore: invalid_use_of_protected_member
  void _prev() => setState(() {
        _focusedDate = _viewMode == _CalViewMode.month
            ? DateTime(_focusedDate.year, _focusedDate.month - 1, 1)
            : _focusedDate.subtract(const Duration(days: 7));
      });

  // ignore: invalid_use_of_protected_member
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
    if (_focusedDate.year == end.year) {
      return '${_focusedDate.year}년 ${months[_focusedDate.month - 1]} ${_focusedDate.day}일'
          ' – ${months[end.month - 1]} ${end.day}일';
    }
    return '${_focusedDate.year}년 ${months[_focusedDate.month - 1]} ${_focusedDate.day}일'
        ' – ${end.year}년 ${months[end.month - 1]} ${end.day}일';
  }

  // ── 드래그 피드백 ──────────────────────────────────────────────

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

  void _showAddChoiceMenu(BuildContext ctx, DateTime date) {
    showUnifiedAddDialog(context, ref, initialDate: date);
  }
}
