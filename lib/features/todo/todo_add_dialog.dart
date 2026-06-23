import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_provider.dart';
import '../event/event_model.dart';
import '../event/event_provider.dart';
import '../event/event_tag_provider.dart';
import 'tag_model.dart';
import 'tag_provider.dart';
import 'todo_model.dart';
import 'todo_provider.dart';

// ─── Public API ──────────────────────────────────────────────────────────────

/// 캘린더 셀 클릭 등 — Task/Event 토글이 있는 통합 다이얼로그.
void showUnifiedAddDialog(
  BuildContext context,
  WidgetRef ref, {
  DateTime? initialDate,
  bool startAsEvent = false,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => _UnifiedDialog(
      initialDate: initialDate,
      startAsEvent: startAsEvent,
    ),
  );
}

/// Task 추가 (칸반 "새 할 일 추가" 등)
void showTodoAddDialog(
  BuildContext context,
  WidgetRef ref, {
  TodoStatus initialStatus = TodoStatus.todo,
  DateTime? initialDate,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => _UnifiedDialog(
      initialStatus: initialStatus,
      initialDate: initialDate,
    ),
  );
}

/// Task 수정
void showTodoEditDialog(
  BuildContext context,
  WidgetRef ref,
  TodoItem item, {
  DateTime? instanceDate,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => _UnifiedDialog(editItem: item, editDate: instanceDate),
  );
}

/// Event 수정
void showEventEditDialog(
  BuildContext context,
  WidgetRef ref,
  EventItem event, {
  DateTime? instanceDate,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => _UnifiedDialog(
        editEvent: event, editDate: instanceDate, startAsEvent: true),
  );
}

// ─── 시간 슬롯 목록 (30분 단위) ───────────────────────────────────────────────

final _timeSlots = [
  for (int h = 0; h < 24; h++)
    for (int m = 0; m < 60; m += 30)
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}'
];

// ─── 알람 계산 ────────────────────────────────────────────────────────────────

String _buildAlarmAt(DateTime taskDate, int daysOffset, int hour, int min) {
  final alarm = taskDate.subtract(Duration(days: daysOffset));
  return '${alarm.year}-${alarm.month.toString().padLeft(2, '0')}-'
      '${alarm.day.toString().padLeft(2, '0')}T'
      '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
}

String _alarmLabel(String? alarmTime, DateTime taskDate) {
  if (alarmTime == null) return '알람 없음';
  try {
    final dt = DateTime.parse(alarmTime);
    final diff = DateTime(taskDate.year, taskDate.month, taskDate.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return '당일 $timeStr';
    if (diff == 1) return '1일 전 $timeStr';
    if (diff == 7) return '1주일 전';
    return '$diff일 전 $timeStr';
  } catch (_) {
    return alarmTime;
  }
}

String _repeatLabel(RepeatType repeat, List<int> weekdays) {
  if (repeat == RepeatType.none) return '반복 안함';
  if (repeat == RepeatType.weekdays && weekdays.isNotEmpty) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    final days = weekdays.map((w) => labels[w - 1]).join(', ');
    return '매주 $days';
  }
  return repeat.label;
}

// ─── 통합 다이얼로그 ──────────────────────────────────────────────────────────

class _UnifiedDialog extends ConsumerStatefulWidget {
  final TodoItem? editItem;
  final EventItem? editEvent;
  final DateTime? editDate;
  final TodoStatus initialStatus;
  final DateTime? initialDate;
  final bool startAsEvent;

  const _UnifiedDialog({
    this.editItem,
    this.editEvent,
    this.editDate,
    this.initialStatus = TodoStatus.todo,
    this.initialDate,
    this.startAsEvent = false,
  });

  @override
  ConsumerState<_UnifiedDialog> createState() => _UnifiedDialogState();
}

class _UnifiedDialogState extends ConsumerState<_UnifiedDialog> {
  late bool _isEventMode;

  late final TextEditingController _titleCtl;
  late final TextEditingController _memoCtl;
  late DateTime _date;
  String? _time;
  late String _selectedTagId;
  RepeatType _repeat = RepeatType.none;
  List<int> _repeatWeekdays = [];
  String? _alarmTime;

  bool _showTimePicker = false;
  final ScrollController _timeScrollCtl = ScrollController();
  static const double _timeItemH = 44.0;

  bool get _isTaskEdit => widget.editItem != null;
  bool get _isEventEdit => widget.editEvent != null;
  bool get _isRepeatInstance =>
      _isTaskEdit &&
      widget.editItem!.repeat != RepeatType.none &&
      widget.editDate != null;

  @override
  void initState() {
    super.initState();
    _isEventMode = widget.startAsEvent || _isEventEdit;

    final item = widget.editItem;
    final event = widget.editEvent;

    _titleCtl = TextEditingController(
        text: item?.title ?? event?.title ?? '');
    _memoCtl = TextEditingController(text: item?.memo ?? '');

    _date = widget.editDate ??
        (item != null
            ? (DateTime.tryParse(item.date) ??
                widget.initialDate ??
                DateTime.now())
            : event != null
                ? (DateTime.tryParse(event.date) ??
                    widget.initialDate ??
                    DateTime.now())
                : (widget.initialDate ?? DateTime.now()));

    _time = item?.time ?? event?.time;
    _selectedTagId = item?.tag ?? event?.tag ?? TagItem.defaultId;
    _repeat = item?.repeat ?? event?.repeat ?? RepeatType.none;
    _repeatWeekdays =
        List.from(item?.repeatWeekdays ?? event?.repeatWeekdays ?? []);
    _alarmTime = item?.alarmTime ?? event?.alarmTime;
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _memoCtl.dispose();
    _timeScrollCtl.dispose();
    super.dispose();
  }

  // ── 시간 피커 열기 (현재 시각 위치로 스크롤) ─────────────────────────────────

  void _openTimePicker() {
    setState(() => _showTimePicker = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_timeScrollCtl.hasClients) return;
      final now = DateTime.now();
      final idx = now.hour * 2 + (now.minute >= 30 ? 1 : 0);
      final target = (idx * _timeItemH)
          .clamp(0.0, _timeScrollCtl.position.maxScrollExtent);
      _timeScrollCtl.jumpTo(target);
    });
  }

  // ── 저장 ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final title = _titleCtl.text.trim();
    if (title.isEmpty) return;
    final dateStr = TodoItem.fmtDate(_date);

    try {
      if (_isEventMode) {
        await _saveEvent(title, dateStr);
      } else {
        await _saveTask(title, dateStr);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
    }
  }

  Future<void> _saveTask(String title, String dateStr) async {
    final memo =
        _memoCtl.text.trim().isEmpty ? null : _memoCtl.text.trim();
    if (_isTaskEdit) {
      await ref.read(todoListProvider.notifier).updateTodo(
            widget.editItem!.copyWith(
              title: title,
              date: _isRepeatInstance ? null : dateStr,
              tag: _selectedTagId,
              time: _time, clearTime: _time == null,
              memo: memo, clearMemo: memo == null,
              repeat: _repeat, repeatWeekdays: _repeatWeekdays,
              alarmTime: _alarmTime, clearAlarmTime: _alarmTime == null,
            ),
          );
    } else {
      await ref.read(todoListProvider.notifier).addTodo(
            TodoItem(
              title: title, date: dateStr,
              priority: TodoPriority.medium,
              tag: _selectedTagId,
              status: widget.initialStatus,
              time: _time, memo: memo,
              repeat: _repeat, repeatWeekdays: _repeatWeekdays,
              alarmTime: _alarmTime,
            ),
          );
    }
  }

  Future<void> _saveEvent(String title, String dateStr) async {
    final memo = _memoCtl.text.trim().isEmpty ? null : _memoCtl.text.trim();
    if (_isEventEdit) {
      await ref.read(eventListProvider.notifier).updateEvent(
            widget.editEvent!.copyWith(
              title: title, date: dateStr,
              time: _time, clearTime: _time == null,
              memo: memo, clearMemo: memo == null,
              tag: _selectedTagId,
              repeat: _repeat, repeatWeekdays: _repeatWeekdays,
              alarmTime: _alarmTime, clearAlarmTime: _alarmTime == null,
            ),
          );
    } else {
      await ref.read(eventListProvider.notifier).addEvent(
            EventItem(
              title: title, date: dateStr,
              time: _time, memo: memo,
              tag: _selectedTagId, repeat: _repeat,
              repeatWeekdays: _repeatWeekdays, alarmTime: _alarmTime,
            ),
          );
    }
  }

  // ── 삭제 ────────────────────────────────────────────────────────────────────

  Future<void> _delete() async {
    if (_isEventMode && _isEventEdit) {
      await _deleteEvent();
    } else if (!_isEventMode && _isTaskEdit) {
      await _deleteTask();
    }
  }

  Future<void> _deleteTask() async {
    final item = widget.editItem!;
    if (item.repeat == RepeatType.none) {
      await ref.read(todoListProvider.notifier).deleteTodo(item.id);
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }
    final instanceKey = widget.editDate != null
        ? TodoItem.fmtDate(widget.editDate!)
        : item.date;
    final choice = await _showRepeatDeleteDialog();
    if (choice == null || !mounted) return;
    if (choice == 'single') {
      await ref
          .read(todoListProvider.notifier)
          .addDeletedOverride(item.id, instanceKey);
    } else {
      await ref
          .read(todoListProvider.notifier)
          .setRepeatEndDate(item.id, instanceKey);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _deleteEvent() async {
    final event = widget.editEvent!;
    if (event.repeat == RepeatType.none) {
      await ref.read(eventListProvider.notifier).deleteEvent(event.id);
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }
    final instanceKey = widget.editDate != null
        ? TodoItem.fmtDate(widget.editDate!)
        : event.date;
    final choice = await _showRepeatDeleteDialog();
    if (choice == null || !mounted) return;
    if (choice == 'single') {
      await ref
          .read(eventListProvider.notifier)
          .addDeletedOverride(event.id, instanceKey);
    } else {
      await ref
          .read(eventListProvider.notifier)
          .setRepeatEndDate(event.id, instanceKey);
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<String?> _showRepeatDeleteDialog() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        title: const Text('반복 일정 삭제'),
        actions: [
          Row(children: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'single'),
              child: const Text('이 일정만'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'future'),
              child: const Text('이후 모두',
                  style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
          ]),
        ],
      ),
    );
  }

  // ── 날짜 / 반복 / 알람 피커 ───────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (p != null && mounted) setState(() => _date = p);
  }

  Future<void> _showRepeatMenu() async {
    final result = await showDialog<RepeatType>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('반복 설정',
            style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        children: RepeatType.values
            .map((r) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, r),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(r.label,
                        style: TextStyle(
                          fontWeight: r == _repeat
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                  ),
                ))
            .toList(),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _repeat = result;
        if (result != RepeatType.weekdays) _repeatWeekdays = [];
      });
    }
  }

  Future<void> _showAlarmMenu() async {
    final options = [
      ('알람 없음', null as String?),
      ('당일 오전 9시', _buildAlarmAt(_date, 0, 9, 0)),
      ('1일 전 오전 9시', _buildAlarmAt(_date, 1, 9, 0)),
      ('1주일 전', _buildAlarmAt(_date, 7, 9, 0)),
    ];
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('알람 설정',
            style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        children: options
            .map((o) => SimpleDialogOption(
                  onPressed: () =>
                      Navigator.pop(ctx, o.$2 ?? '__none__'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(o.$1,
                        style: TextStyle(
                          fontWeight: (_alarmTime == o.$2)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        )),
                  ),
                ))
            .toList(),
      ),
    );
    if (result != null && mounted) {
      setState(() =>
          _alarmTime = result == '__none__' ? null : result);
    }
  }

  void _openTagEditDialog() {
    showDialog<void>(
        context: context,
        builder: (_) => _TagEditDialog(isEventMode: _isEventMode));
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tags = ref
            .watch(_isEventMode ? eventTagListProvider : tagListProvider)
            .value ??
        [TagItem.defaultTag];
    if (!tags.any((t) => t.id == _selectedTagId)) {
      _selectedTagId = TagItem.defaultId;
    }
    final dateLabel = TodoItem.fmtDate(_date);
    final canDelete =
        (_isEventMode && _isEventEdit) || (!_isEventMode && _isTaskEdit);

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 상단 Task / Event 토글 ──────────────────────────
              Center(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('할 일'),
                      icon: Icon(Icons.check_box_outline_blank, size: 14),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('이벤트'),
                      icon: Icon(Icons.event_outlined, size: 14),
                    ),
                  ],
                  selected: {_isEventMode},
                  onSelectionChanged: (s) =>
                      setState(() => _isEventMode = s.first),
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
              ),
              const SizedBox(height: 12),

              // ── 제목 ──────────────────────────────────────────
              TextField(
                controller: _titleCtl,
                autofocus: true,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: _isEventMode ? '이벤트 제목' : '할 일 제목',
                  hintStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: 4),

              // ── 날짜 ──────────────────────────────────────────
              _buildRow(
                  icon: Icons.calendar_today_outlined,
                  label: dateLabel,
                  onTap: _pickDate),
              Divider(height: 1, color: cs.outlineVariant),

              // ── 시간 ──────────────────────────────────────────
              _buildRow(
                icon: Icons.schedule_outlined,
                label: _time ?? '시간 추가',
                labelColor:
                    _time == null ? cs.onSurfaceVariant : cs.onSurface,
                trailing: _time != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () => setState(() {
                          _time = null;
                          _showTimePicker = false;
                        }),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    : null,
                onTap: () {
                  if (_showTimePicker) {
                    setState(() => _showTimePicker = false);
                  } else {
                    _openTimePicker();
                  }
                },
              ),
              if (_showTimePicker) _buildTimeScrollList(cs),
              Divider(height: 1, color: cs.outlineVariant),
              const SizedBox(height: 12),

              // ── 태그 ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('태그',
                      style: TextStyle(
                          fontSize: 13, color: cs.onSurfaceVariant)),
                  TextButton.icon(
                    onPressed: _openTagEditDialog,
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('태그 편집',
                        style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: cs.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((t) {
                  final isSelected = _selectedTagId == t.id;
                  final color = hexToColor(t.colorHex);
                  return ChoiceChip(
                    label: Text(t.name),
                    selected: isSelected,
                    onSelected: (_) =>
                        setState(() => _selectedTagId = t.id),
                    selectedColor: color.withValues(alpha: 0.25),
                    backgroundColor: cs.surfaceContainerLowest,
                    labelStyle: TextStyle(
                      color:
                          isSelected ? color : cs.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? color : cs.outlineVariant,
                      ),
                    ),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: cs.outlineVariant),

              // ── 반복 ──────────────────────────────────────────
              _buildRow(
                icon: Icons.repeat_outlined,
                label: _repeatLabel(_repeat, _repeatWeekdays),
                labelColor: _repeat == RepeatType.none
                    ? cs.onSurfaceVariant
                    : cs.onSurface,
                onTap: _showRepeatMenu,
              ),
              if (_repeat == RepeatType.weekdays)
                _buildWeekdayPicker(cs),
              Divider(height: 1, color: cs.outlineVariant),

              // ── 알람 ──────────────────────────────────────────
              _buildRow(
                icon: Icons.notifications_none_outlined,
                label: _alarmLabel(_alarmTime, _date),
                labelColor: _alarmTime == null
                    ? cs.onSurfaceVariant
                    : cs.onSurface,
                onTap: _showAlarmMenu,
              ),
              Divider(height: 1, color: cs.outlineVariant),
              const SizedBox(height: 12),

              // ── 메모 ──────────────────────────────────────────
              Text('메모',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              TextField(
                controller: _memoCtl,
                maxLines: 4,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: '여기에 메모 입력',
                  hintStyle: TextStyle(
                      color: cs.onSurfaceVariant
                          .withValues(alpha: 0.5)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            if (canDelete)
              TextButton(
                onPressed: _delete,
                child: const Text('삭제',
                    style: TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('취소',
                  style: TextStyle(color: cs.onSurfaceVariant)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
              ),
              child: Text(
                canDelete ? '저장' : '추가',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── 공통 row ────────────────────────────────────────────────────────────────

  Widget _buildRow({
    required IconData icon,
    required String label,
    Color? labelColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      color: labelColor ?? cs.onSurface)),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // ── 시간 스크롤 리스트 ───────────────────────────────────────────────────────

  Widget _buildTimeScrollList(ColorScheme cs) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        controller: _timeScrollCtl,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _timeSlots.length,
        itemExtent: _timeItemH,
        itemBuilder: (context, i) {
          final t = _timeSlots[i];
          final isSelected = _time == t;
          return InkWell(
            onTap: () => setState(() {
              _time = t;
              _showTimePicker = false;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              color: isSelected
                  ? cs.primaryContainer
                  : Colors.transparent,
              child: Row(
                children: [
                  Text(t,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? cs.primary : cs.onSurface,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      )),
                  if (isSelected) ...[
                    const Spacer(),
                    Icon(Icons.check, size: 16, color: cs.primary),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── 요일 선택 ────────────────────────────────────────────────────────────────

  Widget _buildWeekdayPicker(ColorScheme cs) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (i) {
          final weekday = i + 1;
          final isSelected = _repeatWeekdays.contains(weekday);
          return GestureDetector(
            onTap: () => setState(() {
              if (isSelected) {
                _repeatWeekdays.remove(weekday);
              } else {
                _repeatWeekdays.add(weekday);
                _repeatWeekdays.sort();
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1F2937)
                    : cs.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF1F2937)
                      : cs.outlineVariant,
                ),
              ),
              alignment: Alignment.center,
              child: Text(labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : cs.onSurface,
                  )),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Tag edit dialog ──────────────────────────────────────────────────────────

class _TagEditDialog extends ConsumerStatefulWidget {
  final bool isEventMode;
  const _TagEditDialog({required this.isEventMode});

  @override
  ConsumerState<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends ConsumerState<_TagEditDialog> {
  String? _editingId;
  final Map<String, TextEditingController> _nameCtls = {};
  final Map<String, String> _editingColors = {};
  bool _addingNew = false;
  final _newNameCtl = TextEditingController();
  String _newColor = TagItem.defaultColorFor(AppThemeType.classicGray);

  @override
  void dispose() {
    for (final c in _nameCtls.values) {
      c.dispose();
    }
    _newNameCtl.dispose();
    super.dispose();
  }

  void _startEdit(TagItem tag) {
    _nameCtls.putIfAbsent(tag.id, () => TextEditingController());
    _nameCtls[tag.id]!.text = tag.name;
    _editingColors[tag.id] = tag.colorHex;
    setState(() {
      _editingId = tag.id;
      _addingNew = false;
    });
  }

  Future<void> _saveEdit(TagItem tag) async {
    final name = _nameCtls[tag.id]?.text.trim() ?? tag.name;
    if (name.isEmpty) return;
    final color = _editingColors[tag.id] ?? tag.colorHex;
    try {
      if (widget.isEventMode) {
        await ref
            .read(eventTagListProvider.notifier)
            .updateTag(tag.copyWith(name: name, colorHex: color));
      } else {
        await ref
            .read(tagListProvider.notifier)
            .updateTag(tag.copyWith(name: name, colorHex: color));
      }
      setState(() => _editingId = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
    }
  }

  Future<void> _deleteTag(TagItem tag) async {
    if (tag.id == TagItem.defaultId) return;
    try {
      if (widget.isEventMode) {
        await ref
            .read(eventListProvider.notifier)
            .replaceTagId(tag.id, TagItem.defaultId);
        await ref.read(eventTagListProvider.notifier).deleteTag(tag.id);
      } else {
        await ref
            .read(todoListProvider.notifier)
            .replaceTagId(tag.id, TagItem.defaultId);
        await ref.read(tagListProvider.notifier).deleteTag(tag.id);
      }
      if (_editingId == tag.id) setState(() => _editingId = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('삭제에 실패했습니다: $e')));
    }
  }

  Future<void> _addNew() async {
    final name = _newNameCtl.text.trim();
    if (name.isEmpty) return;
    final theme = ref.read(themeProvider).value ?? AppThemeType.classicGray;
    final palette = TagItem.paletteFor(theme);
    final color = palette.contains(_newColor)
        ? _newColor
        : TagItem.defaultColorFor(theme);
    try {
      final newTag = TagItem(name: name, colorHex: color);
      if (widget.isEventMode) {
        await ref.read(eventTagListProvider.notifier).addTag(newTag);
      } else {
        await ref.read(tagListProvider.notifier).addTag(newTag);
      }
      _newNameCtl.clear();
      setState(() {
        _addingNew = false;
        _newColor = TagItem.defaultColorFor(theme);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = ref.watch(themeProvider).maybeWhen(
          data: (value) => value,
          orElse: () => AppThemeType.classicGray,
        );
    final tags =
        ref.watch(widget.isEventMode ? eventTagListProvider : tagListProvider)
                .value ??
            [TagItem.defaultTagFor(theme)];

    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('태그 편집',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...tags.map((tag) => _buildTagRow(tag, cs)),
              const SizedBox(height: 4),
              if (_addingNew) _buildNewTagRow(cs),
              TextButton.icon(
                onPressed: () => setState(() {
                  _addingNew = true;
                  _editingId = null;
                  _newColor = TagItem.defaultColorFor(theme);
                }),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ 태그 추가'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('닫기',
              style: TextStyle(color: cs.onSurfaceVariant)),
        ),
      ],
    );
  }

  Widget _buildTagRow(TagItem tag, ColorScheme cs) {
    final isEditing = _editingId == tag.id;
    final color = hexToColor(tag.colorHex);
    final isDefault = tag.id == TagItem.defaultId;
    return Column(
      children: [
        if (!isEditing)
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4),
              leading: Container(
                width: 18,
                height: 18,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              title: Text(tag.name,
                  style: const TextStyle(fontSize: 14)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 17),
                    onPressed: () => _startEdit(tag),
                    color: cs.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (!isDefault) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 17),
                      onPressed: () => _deleteTag(tag),
                      color: Colors.red.shade400,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          _buildEditRow(tag, cs),
        Divider(height: 1, color: cs.outlineVariant),
      ],
    );
  }

  Widget _buildEditRow(TagItem tag, ColorScheme cs) {
    final editColor = _editingColors[tag.id] ?? tag.colorHex;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtls[tag.id],
            autofocus: true,
            decoration: InputDecoration(
              labelText: '태그 이름',
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF374151)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildColorPalette(
              selected: editColor,
              onSelect: (h) =>
                  setState(() => _editingColors[tag.id] = h)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _editingId = null),
                child: Text('취소',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _saveEdit(tag),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2937),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                ),
                child: const Text('저장'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewTagRow(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _newNameCtl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '새 태그 이름',
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF374151)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildColorPalette(
              selected: _newColor,
              onSelect: (h) => setState(() => _newColor = h)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _addingNew = false),
                child: Text('취소',
                    style: TextStyle(color: cs.onSurfaceVariant)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addNew,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2937),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                ),
                child: const Text('추가'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette({
    required String selected,
    required void Function(String) onSelect,
  }) {
    final theme = ref.watch(themeProvider).maybeWhen(
          data: (value) => value,
          orElse: () => AppThemeType.classicGray,
        );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: TagItem.paletteFor(theme).map((hex) {
        final color = hexToColor(hex);
        final isSel = hex == selected;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onSelect(hex),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: isSel
                    ? Border.all(color: Colors.black87, width: 2.5)
                    : Border.all(color: Colors.transparent),
                boxShadow: isSel
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 4,
                            spreadRadius: 1)
                      ]
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
