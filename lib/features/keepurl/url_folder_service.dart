import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'url_folder_model.dart';

class UrlFolderService {
  static const _appFolderName = 'DontDelay';
  static const _fileName = 'url_folders.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/$_appFolderName');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File('${appDir.path}/$_fileName');
  }

  Future<List<UrlFolder>> loadFolders() async {
    final file = await _file;
    if (!await file.exists()) {
      final defaults = UrlFolder.createDefaults();
      await saveFolders(defaults);
      return defaults;
    }
    final jsonString = await file.readAsString();
    if (jsonString.trim().isEmpty) {
      final defaults = UrlFolder.createDefaults();
      await saveFolders(defaults);
      return defaults;
    }
    final decoded = json.decode(jsonString);
    if (decoded is! List) {
      throw const UrlFolderStorageException('url_folders.json 형식이 올바르지 않습니다.');
    }
    final folders = decoded
        .cast<Map<String, dynamic>>()
        .map(UrlFolder.fromJson)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return folders;
  }

  Future<void> saveFolders(List<UrlFolder> folders) async {
    final file = await _file;
    final sorted = [...folders]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(sorted.map((f) => f.toJson()).toList()),
    );
  }

  UrlFolder defaultFolder(List<UrlFolder> folders) {
    return folders.firstWhere(
      (f) => f.name == UrlFolder.defaultFolderName,
      orElse: () => folders.first,
    );
  }

  UrlFolder? findById(List<UrlFolder> folders, String id) {
    for (final f in folders) {
      if (f.id == id) return f;
    }
    return null;
  }

  UrlFolder? findByName(List<UrlFolder> folders, String name) {
    for (final f in folders) {
      if (f.name == name) return f;
    }
    return null;
  }
}

class UrlFolderStorageException implements Exception {
  final String message;
  const UrlFolderStorageException(this.message);

  @override
  String toString() => 'UrlFolderStorageException: $message';
}
