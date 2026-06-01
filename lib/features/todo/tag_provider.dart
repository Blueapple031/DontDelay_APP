import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tag_model.dart';
import 'tag_service.dart';

final tagServiceProvider = Provider((ref) => TagService());

final tagListProvider =
    AsyncNotifierProvider<TagListNotifier, List<TagItem>>(TagListNotifier.new);

class TagListNotifier extends AsyncNotifier<List<TagItem>> {
  TagService get _service => ref.read(tagServiceProvider);

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
