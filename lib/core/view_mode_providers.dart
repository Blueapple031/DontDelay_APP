import 'package:flutter_riverpod/flutter_riverpod.dart';

// 0 = month, 1 = week
class _CalendarViewModeNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int v) => state = v;
}

final calendarViewModeProvider =
    NotifierProvider<_CalendarViewModeNotifier, int>(
        _CalendarViewModeNotifier.new);

// 0 = kanban, 1 = eisenhower
class _TodoViewModeNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int v) => state = v;
}

final todoViewModeProvider =
    NotifierProvider<_TodoViewModeNotifier, int>(_TodoViewModeNotifier.new);
