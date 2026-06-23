import 'dart:async';
import 'dart:math' show min;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../event/event_model.dart';
import '../event/event_provider.dart';
import '../event/event_tag_provider.dart';
import '../todo/tag_model.dart';
import '../todo/tag_provider.dart';
import '../todo/todo_add_dialog.dart';
import '../todo/todo_model.dart';
import '../todo/todo_provider.dart';

part 'calender_helpers.dart';
part 'calender_overflow.dart';
part 'calender_trash.dart';
part 'calender_month_view.dart';
part 'calender_week_view.dart';

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

  // 멀티셀렉
  final Set<String> _selectedTaskIds = {};
  // ctrl+클릭 이동 모드
  bool _isMoveMode = false;
  // 드래그 상태
  bool _isDragging = false;

  // +more 오버플로 팝업
  OverlayEntry? _overflowEntry;
  Timer? _hoverTimer;

  // 드래그 중 쓰레기통
  OverlayEntry? _trashEntry;

  // ctrl+클릭 이동 오버레이 (커서 추종)
  Offset _cursorPos = Offset.zero;
  OverlayEntry? _moveOverlay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _focusedDate = _today;
  }

  @override
  void dispose() {
    _overflowEntry?.remove();
    _trashEntry?.remove();
    _moveOverlay?.remove();
    _hoverTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncTodos = ref.watch(todoListProvider);
    final asyncEvents = ref.watch(eventListProvider);
    final tagMap = {
      for (final t in (ref.watch(tagListProvider).value ?? [TagItem.defaultTag]))
        t.id: t
    };
    final eventTagMap = {
      for (final t in (ref.watch(eventTagListProvider).value ?? [TagItem.defaultTag]))
        t.id: t
    };

    return asyncTodos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('오류가 발생했습니다: $e')),
      data: (allTodos) {
        final events = asyncEvents.value ?? [];
        return MouseRegion(
          onHover: (event) {
            // Overlay 기준 좌표계로 변환
            final calBox = context.findRenderObject() as RenderBox?;
            final overlayBox = Overlay.of(context).context.findRenderObject()
                as RenderBox?;
            if (calBox != null) {
              _cursorPos = calBox.localToGlobal(event.localPosition,
                  ancestor: overlayBox);
            }
            if (_isMoveMode && _selectedTaskIds.isNotEmpty) {
              _moveOverlay?.markNeedsBuild();
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                Expanded(
                  child: _viewMode == _CalViewMode.month
                      ? _buildMonthView(allTodos, events, tagMap, eventTagMap)
                      : _buildSevenDaysView(allTodos, events, tagMap, eventTagMap),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        OutlinedButton(
          onPressed: () => setState(() => _focusedDate = _today),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            side: BorderSide(color: cs.outline),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            foregroundColor: cs.onSurface,
          ),
          child: const Text('TODAY',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ),
        const SizedBox(width: 4),
        IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _prev,
            splashRadius: 18),
        IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _next,
            splashRadius: 18),
        const SizedBox(width: 6),
        Text(_headerLabel(),
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cs.onSurface)),
        const Spacer(),
        SegmentedButton<_CalViewMode>(
          segments: const [
            ButtonSegment(
              value: _CalViewMode.month,
              label: Text('MONTH'),
              icon: Icon(Icons.calendar_view_month_outlined, size: 15),
            ),
            ButtonSegment(
              value: _CalViewMode.sevenDays,
              label: Text('WEEK'),
              icon: Icon(Icons.view_week_outlined, size: 15),
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
      ],
    );
  }
}
