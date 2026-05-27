import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'url_folder_model.dart';
import 'url_folder_service.dart';

const _uuid = Uuid();

final urlFolderServiceProvider = Provider((ref) => UrlFolderService());

final urlFolderListProvider =
    AsyncNotifierProvider<UrlFolderListNotifier, List<UrlFolder>>(
  UrlFolderListNotifier.new,
);

class UrlFolderListNotifier extends AsyncNotifier<List<UrlFolder>> {
  UrlFolderService get _service => ref.read(urlFolderServiceProvider);

  @override
  Future<List<UrlFolder>> build() async {
    return _service.loadFolders();
  }

  List<UrlFolder> _current() => state.value ?? [];

  Future<void> addFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_current().any((f) => f.name == trimmed)) {
      throw const UrlFolderDuplicateNameException();
    }
    final previous = List<UrlFolder>.from(_current());
    final updated = [
      ...previous,
      UrlFolder(
        id: _uuid.v4(),
        name: trimmed,
        sortOrder: previous.length,
      ),
    ];
    state = AsyncData(updated);
    try {
      await _service.saveFolders(updated);
    } catch (e, st) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> renameFolder(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    if (_current().any((f) => f.id != id && f.name == trimmed)) {
      throw const UrlFolderDuplicateNameException();
    }
    final previous = List<UrlFolder>.from(_current());
    final updated = previous
        .map((f) => f.id == id ? f.copyWith(name: trimmed) : f)
        .toList();
    state = AsyncData(updated);
    try {
      await _service.saveFolders(updated);
    } catch (e, st) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> deleteFolder(String id) async {
    final folder = _service.findById(_current(), id);
    if (folder?.name == UrlFolder.defaultFolderName) {
      throw const UrlFolderProtectedException();
    }
    final previous = List<UrlFolder>.from(_current());
    final updated = previous.where((f) => f.id != id).toList();
    state = AsyncData(updated);
    try {
      await _service.saveFolders(updated);
    } catch (e, st) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(e, st);
    }
  }
}

class UrlFolderDuplicateNameException implements Exception {
  const UrlFolderDuplicateNameException();
}

class UrlFolderProtectedException implements Exception {
  const UrlFolderProtectedException();
}
