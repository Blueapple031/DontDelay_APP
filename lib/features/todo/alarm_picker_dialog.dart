import 'package:flutter/material.dart';

/// 알람 날짜/시간 선택 다이얼로그.
/// 선택 후 "설정" 누르면 "yyyy-MM-ddTHH:mm" 문자열 반환.
/// "취소" 누르면 null 반환.
Future<String?> showAlarmPickerDialog(
  BuildContext context, {
  required DateTime taskDate,
  String? initialAlarmTime,
}) {
  return showDialog<String?>(
    context: context,
    builder: (_) => _AlarmPickerDialog(
      taskDate: taskDate,
      initialAlarmTime: initialAlarmTime,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _AlarmPickerDialog extends StatefulWidget {
  final DateTime taskDate;
  final String? initialAlarmTime;

  const _AlarmPickerDialog({
    required this.taskDate,
    this.initialAlarmTime,
  });

  @override
  State<_AlarmPickerDialog> createState() => _AlarmPickerDialogState();
}

class _AlarmPickerDialogState extends State<_AlarmPickerDialog> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late DateTime _displayMonth;

  static const _weekLabels = ['월', '화', '수', '목', '금', '토', '일'];
  static const _monthNames = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    final init = widget.initialAlarmTime != null
        ? DateTime.tryParse(widget.initialAlarmTime!)
        : null;
    if (init != null) {
      _selectedDate = DateTime(init.year, init.month, init.day);
      _selectedTime = TimeOfDay(hour: init.hour, minute: init.minute);
    } else {
      _selectedDate = DateTime(
          widget.taskDate.year, widget.taskDate.month, widget.taskDate.day);
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
    }
    _displayMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  String _resultString() =>
      '${_selectedDate.year}-'
      '${_selectedDate.month.toString().padLeft(2, '0')}-'
      '${_selectedDate.day.toString().padLeft(2, '0')}T'
      '${_selectedTime.hour.toString().padLeft(2, '0')}:'
      '${_selectedTime.minute.toString().padLeft(2, '0')}';

  String _formatDisplayDate(DateTime d) => '${d.month}.${d.day}.${d.year}';

  String _formatDisplayTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _prevMonth() => setState(
      () => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1));

  void _nextMonth() => setState(
      () => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
              child: Text('미리 알림',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _FieldBox(
                      label: '날짜',
                      value: _formatDisplayDate(_selectedDate),
                      active: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickTime,
                      child: _FieldBox(
                        label: '시간',
                        value: _formatDisplayTime(_selectedTime),
                        active: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildCalendar(cs),
            ),
            const SizedBox(height: 8),
            Divider(height: 1, color: cs.outlineVariant),
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('취소',
                          style: TextStyle(
                              fontSize: 15,
                              color: cs.onSurface.withValues(alpha: 0.55))),
                    ),
                  ),
                  VerticalDivider(
                      width: 1, indent: 10, endIndent: 10,
                      color: cs.outlineVariant),
                  Expanded(
                    child: TextButton(
                      onPressed: () =>
                          Navigator.pop(context, _resultString()),
                      child: Text('설정',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: cs.primary)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(ColorScheme cs) {
    final monthLabel =
        '${_monthNames[_displayMonth.month - 1]} ${_displayMonth.year}';
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final firstDay = DateTime(_displayMonth.year, _displayMonth.month, 1);
    final lastDayNum =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final prevMonthLastDay =
        DateTime(_displayMonth.year, _displayMonth.month, 0).day;
    // Dart weekday: 1=Mon, 7=Sun → offset 0=Mon
    final startOffset = firstDay.weekday - 1;

    return Column(
      children: [
        Row(
          children: [
            Text(monthLabel,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            _NavBtn(icon: Icons.chevron_left, onTap: _prevMonth),
            const SizedBox(width: 4),
            _NavBtn(icon: Icons.chevron_right, onTap: _nextMonth),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: _weekLabels
              .map((w) => Expanded(
                    child: Center(
                      child: Text(w,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface.withValues(alpha: 0.4))),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),
        for (int week = 0; week < 6; week++)
          Row(
            children: List.generate(7, (dow) {
              final cellIdx = week * 7 + dow;
              final dayNum = cellIdx - startOffset + 1;

              if (dayNum < 1 || dayNum > lastDayNum) {
                final otherDay = dayNum < 1
                    ? prevMonthLastDay + dayNum
                    : dayNum - lastDayNum;
                return Expanded(
                  child: SizedBox(
                    height: 36,
                    child: Center(
                      child: Text('$otherDay',
                          style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withValues(alpha: 0.2))),
                    ),
                  ),
                );
              }

              final date = DateTime(
                  _displayMonth.year, _displayMonth.month, dayNum);
              final isSelected = date == _selectedDate;
              final isToday = date == todayDate;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: SizedBox(
                    height: 36,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected ? cs.primary : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isToday && !isSelected
                              ? Border.all(color: cs.primary, width: 1.5)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '$dayNum',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : cs.onSurface),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}

// ─── 날짜/시간 표시 박스 ────────────────────────────────────────────────────────

class _FieldBox extends StatelessWidget {
  final String label;
  final String value;
  final bool active;

  const _FieldBox({
    required this.label,
    required this.value,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? cs.primary.withValues(alpha: 0.7)
                  : cs.outlineVariant,
              width: active ? 2 : 1,
            ),
          ),
          child: Text(value,
              style: TextStyle(fontSize: 15, color: cs.onSurface)),
        ),
      ],
    );
  }
}

// ─── 월 이동 버튼 ──────────────────────────────────────────────────────────────

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: cs.onSurface.withValues(alpha: 0.07),
        ),
        child: Icon(icon, size: 18,
            color: cs.onSurface.withValues(alpha: 0.55)),
      ),
    );
  }
}
