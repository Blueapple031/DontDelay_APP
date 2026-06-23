import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../todo/tag_model.dart';
import 'event_tag_service.dart';

final eventTagServiceProvider = Provider((ref) => EventTagService());

final eventTagListProvider =
    AsyncNotifierProvider<EventTagNotifier, List<TagItem>>(
  EventTagNotifier.new,
);

class EventTagNotifier extends AsyncNotifier<List<TagItem>> {
  EventTagService get _service => ref.read(eventTagServiceProvider);

  @override
  Future<List<TagItem>> build() => _service.loadTags();

  List<TagItem> _current() => state.value ?? [TagItem.defaultTag];

  Future<void> addTag(TagItem tag) async {
    final prev = List<TagItem>.from(_current());
    final updated = [...prev, tag];
    state = AsyncData(updated);
    try {
      await _service.saveTags(updated);
    } catch (e, st) {
      state = AsyncData(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> updateTag(TagItem tag) async {
    final prev = List<TagItem>.from(_current());
    final updated = prev.map((t) => t.id == tag.id ? tag : t).toList();
    state = AsyncData(updated);
    try {
      await _service.saveTags(updated);
    } catch (e, st) {
      state = AsyncData(prev);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> deleteTag(String id) async {
    if (id == TagItem.defaultId) return;
    final prev = List<TagItem>.from(_current());
    final updated = prev.where((t) => t.id != id).toList();
    state = AsyncData(updated);
    try {
      await _service.saveTags(updated);
    } catch (e, st) {
      state = AsyncData(prev);
      Error.throwWithStackTrace(e, st);
    }
  }
}
