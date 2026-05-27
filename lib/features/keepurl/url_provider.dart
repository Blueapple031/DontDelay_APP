import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'url_model.dart';
import 'url_service.dart';

final urlServiceProvider = Provider((ref) => UrlService());

final urlListProvider =
    AsyncNotifierProvider<UrlListNotifier, List<UrlItem>>(
  UrlListNotifier.new,
);

class UrlListNotifier extends AsyncNotifier<List<UrlItem>> {
  UrlService get _service => ref.read(urlServiceProvider);

  @override
  Future<List<UrlItem>> build() async {
    return _service.loadUrls();
  }

  List<UrlItem> _currentList() => state.value ?? [];

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _service.loadUrls());
  }

  Future<void> addUrl(UrlItem item) async {
    final previous = List<UrlItem>.from(_currentList());
    if (_service.hasDuplicate(previous, item.url)) {
      throw const UrlDuplicateException();
    }
    final updated = [...previous, item];
    state = AsyncData<List<UrlItem>>(updated);
    try {
      await _service.saveUrls(updated);
    } catch (e, st) {
      state = AsyncData<List<UrlItem>>(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<UrlAddResult> addFromApi({
    required String url,
    required String title,
    String source = 'extension',
  }) async {
    final normalized = UrlItem.normalizeUrl(url);
    if (!UrlItem.isValidHttpUrl(normalized)) {
      return UrlAddResult.invalid;
    }

    final previous = List<UrlItem>.from(_currentList());
    if (_service.hasDuplicate(previous, normalized)) {
      return UrlAddResult.duplicate;
    }

    final item = UrlItem(
      url: normalized,
      title: title.trim().isEmpty ? normalized : title.trim(),
      source: source,
    );

    final updated = [...previous, item];
    state = AsyncData<List<UrlItem>>(updated);
    try {
      await _service.saveUrls(updated);
      return UrlAddResult.saved;
    } catch (e, st) {
      state = AsyncData<List<UrlItem>>(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> deleteUrl(String id) async {
    final previous = List<UrlItem>.from(_currentList());
    final updated = previous.where((u) => u.id != id).toList();
    state = AsyncData<List<UrlItem>>(updated);
    try {
      await _service.saveUrls(updated);
    } catch (e, st) {
      state = AsyncData<List<UrlItem>>(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> updateUrl(UrlItem item) async {
    final previous = List<UrlItem>.from(_currentList());
    if (_service.hasDuplicate(previous, item.url, excludeId: item.id)) {
      throw const UrlDuplicateException();
    }
    final updated =
        previous.map((u) => u.id == item.id ? item : u).toList();
    state = AsyncData<List<UrlItem>>(updated);
    try {
      await _service.saveUrls(updated);
    } catch (e, st) {
      state = AsyncData<List<UrlItem>>(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> toggleWatchLater(String id) async {
    final previous = List<UrlItem>.from(_currentList());
    final updated = previous
        .map(
          (u) => u.id == id ? u.copyWith(watchLater: !u.watchLater) : u,
        )
        .toList();
    state = AsyncData<List<UrlItem>>(updated);
    try {
      await _service.saveUrls(updated);
    } catch (e, st) {
      state = AsyncData<List<UrlItem>>(previous);
      Error.throwWithStackTrace(e, st);
    }
  }
}

class UrlDuplicateException implements Exception {
  const UrlDuplicateException();
}
