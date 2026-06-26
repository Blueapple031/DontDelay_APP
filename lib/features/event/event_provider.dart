import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'event_model.dart';
import 'event_service.dart';

final eventServiceProvider = Provider((ref) => EventService());

final eventListProvider =
    AsyncNotifierProvider<EventListNotifier, List<EventItem>>(
  EventListNotifier.new,
);

class EventListNotifier extends AsyncNotifier<List<EventItem>> {
  EventService get _service => ref.read(eventServiceProvider);

  @override
  Future<List<EventItem>> build() => _service.loadEvents();

  List<EventItem> _current() => state.value ?? [];

  Future<void> addEvent(EventItem event) async {
    final prev = List<EventItem>.from(_current());
    final updated = [...prev, event];
    state = AsyncData(updated);
    try {
      await _service.saveEvents(updated);
    } catch (e, st) {
      state = AsyncData(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> updateEvent(EventItem event) async {
    final prev = List<EventItem>.from(_current());
    final updated = prev.map((e) => e.id == event.id ? event : e).toList();
    state = AsyncData(updated);
    try {
      await _service.saveEvents(updated);
    } catch (e, st) {
      state = AsyncData(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> deleteEvent(String id) async {
    final prev = List<EventItem>.from(_current());
    final updated = prev.where((e) => e.id != id).toList();
    state = AsyncData(updated);
    try {
      await _service.saveEvents(updated);
    } catch (e, st) {
      state = AsyncData(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> addDeletedOverride(String id, String dateKey) async {
    final prev = List<EventItem>.from(_current());
    final updated = prev.map((e) {
      if (e.id != id) return e;
      final newDeleted = Set<String>.from(e.deletedOverrides)..add(dateKey);
      return e.copyWith(deletedOverrides: newDeleted);
    }).toList();
    state = AsyncData(updated);
    try {
      await _service.saveEvents(updated);
    } catch (e, st) {
      state = AsyncData(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> setRepeatEndDate(String id, String endDate) async {
    final prev = List<EventItem>.from(_current());
    final updated = prev.map((e) {
      if (e.id != id) return e;
      return e.copyWith(repeatEndDate: endDate);
    }).toList();
    state = AsyncData(updated);
    try {
      await _service.saveEvents(updated);
    } catch (e, st) {
      state = AsyncData(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> replaceTagId(String fromId, String toId) async {
    final previous = List<EventItem>.from(_current());
    final updated = previous
        .map((e) => e.tag == fromId ? e.copyWith(tag: toId) : e)
        .toList();
    state = AsyncData<List<EventItem>>(updated);
    try {
      await _service.saveEvents(updated);
    } catch (e, st) {
      state = AsyncData<List<EventItem>>(previous);
      Error.throwWithStackTrace(e, st);
    }
  }
}
