import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'url_model.dart';

/// OS별 [getApplicationDocumentsDirectory] 아래 `DontDelay/urls.json`에
/// URL 목록을 JSON으로 저장합니다.
class UrlService {
  static const _appFolderName = 'DontDelay';
  static const _fileName = 'urls.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/$_appFolderName');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File('${appDir.path}/$_fileName');
  }

  Future<List<UrlItem>> loadUrls() async {
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
      return decoded
          .cast<Map<String, dynamic>>()
          .map(UrlItem.fromJson)
          .toList();
    } catch (e, st) {
      Error.throwWithStackTrace(
        UrlStorageException('URL 데이터 형식이 올바르지 않습니다: $e'),
        st,
      );
    }
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
}

class UrlStorageException implements Exception {
  final String message;
  const UrlStorageException(this.message);

  @override
  String toString() => 'UrlStorageException: $message';
}
