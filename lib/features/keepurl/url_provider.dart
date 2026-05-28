import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'url_api_server.dart';
import 'url_folder_model.dart';
import 'url_folder_provider.dart';
import 'url_folder_service.dart';
import 'url_model.dart';
import 'url_service.dart';

final urlServiceProvider = Provider((ref) => UrlService());

/// main()에서 UrlApiServer에 연결할 핸들러 (시그니처를 한곳에서 관리)
UrlApiAddHandler createUrlApiAddHandler(ProviderContainer container) {
  return ({
    required String url,
    required String title,
    required String source,
    String memo = '',
  }) {
    return container.read(urlListProvider.notifier).addFromApi(
          url: url,
          title: title,
          source: source,
          memo: memo,
        );
  };
}

final urlListProvider =
    AsyncNotifierProvider<UrlListNotifier, List<UrlItem>>(
  UrlListNotifier.new,
);

class UrlListNotifier extends AsyncNotifier<List<UrlItem>> {
  UrlService get _service => ref.read(urlServiceProvider);
  UrlFolderService get _folderService => ref.read(urlFolderServiceProvider);

  @override
  Future<List<UrlItem>> build() async {
    return _service.loadUrls();
  }

  List<UrlItem> _currentList() {
    final list = state.value;
    if (list == null) return [];
    return list.map(_rehydrate).toList();
  }

  /// Hot reload 후 메모리에 남은 구 인스턴스를 JSON 경유로 재생성
  UrlItem _rehydrate(UrlItem item) => UrlItem.fromJson(item.toJson());

  Future<List<UrlFolder>> _folders() async {
    return ref.read(urlFolderListProvider.future);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _service.loadUrls());
  }

  Future<void> addUrl({
    required String url,
    required String title,
    String? folderId,
    String memo = '',
    bool watchLater = false,
    String source = 'manual',
  }) async {
    final folders = await _folders();
    final normalized = UrlItem.normalizeUrl(url);
    final previous = List<UrlItem>.from(_currentList());
    if (_service.hasDuplicate(previous, normalized)) {
      throw const UrlDuplicateException();
    }

    final resolvedFolderId = _service.resolveFolderId(
      folders: folders,
      url: normalized,
      explicitFolderId: folderId,
    );

    final item = UrlItem(
      url: normalized,
      title: title.trim().isEmpty ? normalized : title.trim(),
      folderId: resolvedFolderId,
      memo: memo.trim(),
      watchLater: watchLater,
      source: source,
    );

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
    String memo = '',
  }) async {
    final normalized = UrlItem.normalizeUrl(url);
    if (!UrlItem.isValidSavableUrl(normalized)) {
      return UrlAddResult.invalid;
    }

    final previous = List<UrlItem>.from(_currentList());
    if (_service.hasDuplicate(previous, normalized)) {
      return UrlAddResult.duplicate;
    }

    try {
      await addUrl(
        url: normalized,
        title: title,
        source: source,
        memo: memo,
      );
      return UrlAddResult.saved;
    } catch (_) {
      return UrlAddResult.invalid;
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

  Future<void> updateMemo(String id, String memo) async {
    final previous = List<UrlItem>.from(_currentList());
    final updated = previous
        .map((u) => u.id == id ? u.copyWith(memo: memo.trim()) : u)
        .toList();
    state = AsyncData<List<UrlItem>>(updated);
    try {
      await _service.saveUrls(updated);
    } catch (e, st) {
      state = AsyncData<List<UrlItem>>(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> moveToFolder(String urlId, String folderId) async {
    final previous = List<UrlItem>.from(_currentList());
    final updated = previous
        .map((u) => u.id == urlId ? u.copyWith(folderId: folderId) : u)
        .toList();
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

  Future<void> reassignUrlsFromDeletedFolder(String folderId) async {
    final folders = await _folders();
    final defaultId = _folderService.defaultFolder(folders).id;
    final previous = List<UrlItem>.from(_currentList());
    final updated = previous
        .map(
          (u) => u.folderId == folderId ? u.copyWith(folderId: defaultId) : u,
        )
        .toList();
    if (updated == previous) return;
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
