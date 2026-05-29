import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'tag_model.dart';

class TagService {
  static const _appFolderName = 'DontDelay';
  static const _fileName = 'tags.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/$_appFolderName');
    if (!await appDir.exists()) await appDir.create(recursive: true);
    return File('${appDir.path}/$_fileName');
  }

  Future<List<TagItem>> loadTags() async {
    final file = await _file;
    if (!await file.exists()) {
      final defaults = [TagItem.defaultTag];
      await saveTags(defaults);
      return defaults;
    }
    final jsonString = await file.readAsString();
    if (jsonString.trim().isEmpty) {
      final defaults = [TagItem.defaultTag];
      await saveTags(defaults);
      return defaults;
    }
    try {
      final decoded = json.decode(jsonString);
      if (decoded is! List) return [TagItem.defaultTag];
      final tags = decoded
          .cast<Map<String, dynamic>>()
          .map(TagItem.fromJson)
          .toList();
      if (!tags.any((t) => t.id == TagItem.defaultId)) {
        tags.insert(0, TagItem.defaultTag);
        await saveTags(tags);
      }
      return tags;
    } catch (_) {
      return [TagItem.defaultTag];
    }
  }

  Future<void> saveTags(List<TagItem> tags) async {
    final file = await _file;
    final jsonString = const JsonEncoder.withIndent('  ')
        .convert(tags.map((t) => t.toJson()).toList());
    await file.writeAsString(jsonString);
  }
}
