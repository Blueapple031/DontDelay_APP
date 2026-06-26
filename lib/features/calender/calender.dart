import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/view_mode_providers.dart';
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

  // +more 오버플로 팝업
  OverlayEntry? _overflowEntry;
  Timer? _hoverTimer;

  // 드래그 중 쓰레기통
  OverlayEntry? _trashEntry;

  // week 가로 스크롤
  final _weekHScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _today = DateTime(now.year, now.month, now.day);
    _focusedDate = _today;
    _viewMode = ref.read(calendarViewModeProvider) == 1
        ? _CalViewMode.sevenDays
        : _CalViewMode.month;
  }

  @override
  void dispose() {
    _overflowEntry?.remove();
    _trashEntry?.remove();
    _hoverTimer?.cancel();
    _weekHScrollCtrl.dispose();
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
        return LayoutBuilder(
          builder: (_, constraints) {
            // 헤더 최솟값 먼저 확보 → 나머지를 그리드에 할당 (행 최대 140px cap)
            const headerMinH = 72.0;
            const weekdayRowH = 32.0;
            const rowCount = 5;
            const maxRowH = 140.0;
            const maxGridH = weekdayRowH + rowCount * maxRowH; // 732

            final availH = constraints.maxHeight - 16;
            // 여유분(availH - maxGridH)이 헤더 추가 공간, 최소 headerMinH 보장
            final headerAreaH =
                (availH - maxGridH).clamp(headerMinH, double.infinity);
            // gridH = 나머지 — headerAreaH + gridH = availH 항상 성립
            final gridH = availH - headerAreaH;

            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: _viewMode == _CalViewMode.month
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 헤더: 확보된 공간 안에서 수직 중앙 정렬
                        SizedBox(
                          height: headerAreaH,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [_buildHeader()],
                          ),
                        ),
                        // 그리드: 딱 맞는 높이
                        SizedBox(
                          height: gridH,
                          child: _buildMonthView(
                              allTodos, events, tagMap, eventTagMap),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: headerAreaH,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [_buildHeader()],
                          ),
                        ),
                        Expanded(
                          child: _buildSevenDaysView(
                              allTodos, events, tagMap, eventTagMap),
                        ),
                      ],
                    ),
            );
          },
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
          onSelectionChanged: (s) {
            setState(() => _viewMode = s.first);
            ref.read(calendarViewModeProvider.notifier)
                .set(_viewMode == _CalViewMode.sevenDays ? 1 : 0);
          },
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
