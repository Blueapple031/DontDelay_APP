import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/todo/todo_add_dialog.dart';
import '../features/todo/todo_model.dart';
import '../features/todo/todo_provider.dart';

// ─── 알람 알림 모델 ────────────────────────────────────────────────────────────

class _AlarmNote {
  final TodoItem task;
  final String description;
  final bool isOverdue;

  _AlarmNote({
    required this.task,
    required this.description,
    required this.isOverdue,
  });
}

// ─── MainLayout ───────────────────────────────────────────────────────────────

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentPath;

  const MainLayout({super.key, required this.child, required this.currentPath});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  static const _menuItems = [
    {'title': '대시보드', 'icon': Icons.dashboard_outlined, 'path': '/dashboard'},
    {'title': '할 일', 'icon': Icons.check_box_outlined, 'path': '/todo'},
    {
      'title': '캘린더',
      'icon': Icons.calendar_today_outlined,
      'path': '/calendar',
    },
    {'title': 'URL 보관함', 'icon': Icons.bookmark_border, 'path': '/keepurl'},
    {'title': '회고록', 'icon': Icons.book_outlined, 'path': '/retrospective'},
    {'title': '시험기간 모드', 'icon': Icons.school_outlined, 'path': '/exam_mode'},
    {'title': 'AI 코치', 'icon': Icons.smart_toy_outlined, 'path': '/ai_coach'},
    {'title': '마이페이지', 'icon': Icons.person_outline, 'path': '/mypage'},
  ];


  // ── 알람 상태 ──────────────────────────────────────────────────────
  Timer? _alarmTimer;
  final Set<String> _shownAlarmsToday = {};
  DateTime? _lastCheckDate;
  bool _showNotificationPanel = false;
  int _unreadCount = 0;
  TodoItem? _popupTask;


  @override
  void initState() {
    super.initState();
    _alarmTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkAlarms(),
    );
    // 약간 지연 후 초기 체크 (providers 로드 기다림)
    Future.delayed(const Duration(seconds: 2), _checkAlarms);
  }

  @override
  void dispose() {
    _alarmTimer?.cancel();
    super.dispose();
  }

  // ── 알람 체크 ──────────────────────────────────────────────────────

  void _checkAlarms() {
    if (!mounted) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 날짜가 바뀌면 표시 이력 초기화 (연·월·일 모두 비교)
    if (_lastCheckDate != null) {
      final lastDay = DateTime(
          _lastCheckDate!.year, _lastCheckDate!.month, _lastCheckDate!.day);
      if (lastDay != today) _shownAlarmsToday.clear();
    }
    _lastCheckDate = now;

    final todos = ref.read(todoListProvider).maybeWhen(
          data: (list) => list,
          orElse: () => <TodoItem>[],
        );

    debugPrint('[Alarm] check at $now — ${todos.length} todos');

    // 타이머 드리프트로 정확한 분을 놓칠 수 있으므로
    // "오늘 알람 시각이 지금으로부터 2분 이내에 있으면" 발동
    final twoMinsAgo = now.subtract(const Duration(minutes: 2));

    for (final task in todos) {
      if (task.alarmTime == null) continue;
      debugPrint('[Alarm] task "${task.title}" alarmTime=${task.alarmTime}');
      if (_shownAlarmsToday.contains(task.id)) {
        debugPrint('[Alarm]   → already shown today, skip');
        continue;
      }

      try {
        final alarmDt = DateTime.parse(task.alarmTime!);
        debugPrint('[Alarm]   → parsed=$alarmDt  now=$now  twoMinsAgo=$twoMinsAgo');
        if (alarmDt.year == today.year &&
            alarmDt.month == today.month &&
            alarmDt.day == today.day &&
            !alarmDt.isAfter(now) &&
            alarmDt.isAfter(twoMinsAgo)) {
          debugPrint('[Alarm]   → FIRING popup!');
          _shownAlarmsToday.add(task.id);
          _triggerAlarmPopup(task);
        }
      } catch (e) {
        debugPrint('[Alarm]   → parse error: $e');
      }
    }
  }

  void _triggerAlarmPopup(TodoItem task) {
    if (!mounted) return;
    setState(() {
      _unreadCount++;
      _popupTask = task;
    });
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) setState(() => _popupTask = null);
    });
  }

  // ── 알림 패널 데이터 ───────────────────────────────────────────────

  List<_AlarmNote> _buildAlarmNotes(List<TodoItem> todos) {
    final now = DateTime.now();
    final notes = <_AlarmNote>[];

    for (final task in todos) {
      if (task.status == TodoStatus.done) continue;
      final dt = DateTime.tryParse(task.date);
      if (dt == null) continue;
      final taskDay = DateTime(dt.year, dt.month, dt.day);
      final today = DateTime(now.year, now.month, now.day);
      final diff = taskDay.difference(today).inDays;

      if (diff < 0) {
        notes.add(_AlarmNote(
          task: task,
          description: '기한 초과 — ${task.title}',
          isOverdue: true,
        ));
      } else if (diff == 0) {
        notes.add(_AlarmNote(
          task: task,
          description: '오늘 마감 — ${task.title}',
          isOverdue: false,
        ));
      } else if (diff <= 3) {
        notes.add(_AlarmNote(
          task: task,
          description: '$diff일 후 마감 — ${task.title}',
          isOverdue: false,
        ));
      }
    }

    notes.sort((a, b) {
      if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
      return 0;
    });

    return notes;
  }

  // ── build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final todos = ref.watch(todoListProvider).maybeWhen(
          data: (list) => list,
          orElse: () => <TodoItem>[],
        );
    final alarmNotes = _buildAlarmNotes(todos);

    return Stack(
      children: [
        Scaffold(
      body: Row(
        children: [
          // ── 사이드바 ──────────────────────────────────────────────
          Container(
            width: 220,
            color: cs.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'DontDelay',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface),
                  ),
                ),

                // 메뉴
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected = widget.currentPath
                          .startsWith(item['path'] as String);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 3.0),
                        child: ListTile(
                          leading: Icon(item['icon'] as IconData,
                              color: isSelected
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                              size: 20),
                          title: Text(item['title'] as String,
                              style: TextStyle(
                                color: isSelected
                                    ? cs.primary
                                    : cs.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 14,
                              )),
                          selected: isSelected,
                          selectedTileColor: cs.primaryContainer,
                          onTap: () =>
                              context.go(item['path'] as String),
                        ),
                      );
                    },
                  ),
                ),

                // ── 알림 벨 ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          _showNotificationPanel
                              ? Icons.notifications
                              : Icons.notifications_none,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                        title: Text('알림',
                            style: TextStyle(
                                fontSize: 14,
                                color: cs.onSurface)),
                        onTap: () => setState(() {
                          _showNotificationPanel =
                              !_showNotificationPanel;
                          if (_showNotificationPanel) _unreadCount = 0;
                        }),
                      ),
                      if (_unreadCount > 0)
                        Positioned(
                          top: 8,
                          left: 24,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text('$_unreadCount',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── 알림 패널 ──────────────────────────────────────
                if (_showNotificationPanel)
                  _buildNotificationPanel(alarmNotes, cs),

              ],
            ),
          ),

          // 구분선
          VerticalDivider(thickness: 1, width: 1, color: cs.outlineVariant),

          // ── 메인 컨텐츠 ──────────────────────────────────────────
          Expanded(
            child: ColoredBox(color: cs.surface, child: widget.child),
          ),
        ],
      ),
        ),
        if (_popupTask != null)
          Positioned(
            bottom: 24,
            right: 24,
            child: _buildAlarmPopup(_popupTask!),
          ),
      ],
    );
  }

  Widget _buildAlarmPopup(TodoItem task) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.alarm, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('마감 알림',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(task.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _popupTask = null),
              child: const Icon(Icons.close, color: Colors.white70, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ── 알림 패널 ────────────────────────────────────────────────────

  Widget _buildNotificationPanel(
      List<_AlarmNote> notes, ColorScheme cs) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('알림',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: cs.onSurface)),
          const SizedBox(height: 6),
          if (notes.isEmpty)
            Text('마감 임박 할 일이 없습니다.',
                style: TextStyle(
                    fontSize: 11, color: cs.onSurfaceVariant))
          else
            ...notes.take(5).map((n) => _buildNoteRow(n, cs)),
        ],
      ),
    );
  }

  Widget _buildNoteRow(_AlarmNote note, ColorScheme cs) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => showTodoEditDialog(context, ref, note.task),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.circle,
                size: 6,
                color: note.isOverdue ? Colors.red : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  note.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: note.isOverdue ? Colors.red : cs.onSurface,
                    fontWeight: note.isOverdue
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
