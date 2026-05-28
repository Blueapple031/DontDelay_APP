import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'url_folder_model.dart';
import 'url_folder_service.dart';
import 'url_model.dart';

class UrlService {
  static const _appFolderName = 'DontDelay';
  static const _fileName = 'urls.json';

  final UrlFolderService _folderService = UrlFolderService();

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/$_appFolderName');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File('${appDir.path}/$_fileName');
  }

  Future<List<UrlItem>> loadUrls() async {
    final folders = await _folderService.loadFolders();
    final defaultFolder = _folderService.defaultFolder(folders);

    final file = await _file;
    if (!await file.exists()) {
      return [];
    }
    final jsonString = await file.readAsString();
    if (jsonString.trim().isEmpty) {
      return [];
    }
    Object? decoded;
    try {
      decoded = json.decode(jsonString);
    } on FormatException catch (e) {
      throw UrlStorageException('urls.json 내용이 유효한 JSON이 아닙니다: $e');
    }
    if (decoded is! List) {
      throw const UrlStorageException(
        'urls.json의 루트가 배열(List)이 아닙니다.',
      );
    }
    try {
      return decoded.cast<Map<String, dynamic>>().map((raw) {
        return _parseItem(raw, folders, defaultFolder);
      }).toList();
    } catch (e, st) {
      Error.throwWithStackTrace(
        UrlStorageException('URL 데이터 형식이 올바르지 않습니다: $e'),
        st,
      );
    }
  }

  UrlItem _parseItem(
    Map<String, dynamic> raw,
    List<UrlFolder> folders,
    UrlFolder defaultFolder,
  ) {
    var folderId = raw['folderId'] as String?;
    if (folderId == null || folderId.isEmpty) {
      final legacyCategory = raw['category'] as String?;
      if (legacyCategory != null) {
        final folder = _folderService.findByName(folders, legacyCategory);
        folderId = folder?.id ?? defaultFolder.id;
      } else {
        final url = raw['url'] as String;
        final inferred = UrlItem.inferFolderNameFromUrl(url);
        final folder = _folderService.findByName(folders, inferred);
        folderId = folder?.id ?? defaultFolder.id;
      }
    }
    return UrlItem.fromJson({...raw, 'folderId': folderId});
  }

  Future<void> saveUrls(List<UrlItem> urls) async {
    final file = await _file;
    final jsonString = const JsonEncoder.withIndent('  ')
        .convert(urls.map((u) => u.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  bool hasDuplicate(List<UrlItem> urls, String rawUrl, {String? excludeId}) {
    final normalized = UrlItem.normalizeUrl(rawUrl);
    return urls.any(
      (u) =>
          u.id != excludeId && UrlItem.normalizeUrl(u.url) == normalized,
    );
  }

  String resolveFolderId({
    required List<UrlFolder> folders,
    required String url,
    String? explicitFolderId,
  }) {
    if (explicitFolderId != null && explicitFolderId.isNotEmpty) {
      return explicitFolderId;
    }
    final inferredName = UrlItem.inferFolderNameFromUrl(url);
    final folder = _folderService.findByName(folders, inferredName);
    if (folder != null) return folder.id;
    return _folderService.defaultFolder(folders).id;
  }
}

class UrlStorageException implements Exception {
  final String message;
  const UrlStorageException(this.message);

  @override
  String toString() => 'UrlStorageException: $message';
}
