import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/theme_provider.dart';
import '../todo/tag_model.dart';

class EventTagService {
  static const _appFolderName = 'DontDelay';
  static const _fileName = 'event_tags.json';

  static const _limeCoralColorMigration = {
    '#EF4444': '#E58AA5',
    '#F97316': '#EDA367',
    '#EAB308': '#D9B84F',
    '#22C55E': '#57B8A6',
    '#3B82F6': '#6FA8DC',
    '#2563EB': '#6FA8DC',
    '#6366F1': '#A88AD8',
    '#8B5CF6': '#A88AD8',
    '#B9D35D': '#C3DC68',
    '#DFA35E': '#D9B84F',
    '#B7B86E': '#D9B84F',
    '#8FBF88': '#57B8A6',
    '#75B7A5': '#57B8A6',
    '#8AA9C8': '#6FA8DC',
    '#B799C7': '#A88AD8',
  };
  static const _classicColorMigration = {
    '#C3DC68': '#6366F1',
    '#EDA367': '#F97316',
    '#6FA8DC': '#3B82F6',
    '#A88AD8': '#8B5CF6',
    '#E58AA5': '#EF4444',
    '#57B8A6': '#22C55E',
    '#D9B84F': '#EAB308',
    '#8B9AAE': '#3B82F6',
  };

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/$_appFolderName');
    if (!await appDir.exists()) await appDir.create(recursive: true);
    return File('${appDir.path}/$_fileName');
  }

  Future<List<TagItem>> loadTags(AppThemeType theme) async {
    final defaultTag = TagItem.defaultTagFor(theme);
    final file = await _file;
    if (!await file.exists()) {
      final defaults = [defaultTag];
      await saveTags(defaults);
      return defaults;
    }
    final jsonString = await file.readAsString();
    if (jsonString.trim().isEmpty) {
      final defaults = [defaultTag];
      await saveTags(defaults);
      return defaults;
    }
    try {
      final decoded = json.decode(jsonString);
      if (decoded is! List) return [defaultTag];
      final tags =
          decoded.cast<Map<String, dynamic>>().map(TagItem.fromJson).toList();
      var shouldSave = false;
      if (!tags.any((t) => t.id == TagItem.defaultId)) {
        tags.insert(0, defaultTag);
        shouldSave = true;
      }
      final migratedTags = tags.map((t) => _migrateThemeColor(t, theme)).toList();
      shouldSave = shouldSave ||
          migratedTags.indexed.any((entry) {
            final (index, tag) = entry;
            return tag.colorHex != tags[index].colorHex;
          });
      if (shouldSave) await saveTags(migratedTags);
      return migratedTags;
    } catch (_) {
      return [defaultTag];
    }
  }

  TagItem _migrateThemeColor(TagItem tag, AppThemeType theme) {
    final normalized = tag.colorHex.toUpperCase();
    final defaultColor = TagItem.defaultColorFor(theme);
    if (tag.id == TagItem.defaultId && normalized != defaultColor) {
      return tag.copyWith(colorHex: defaultColor);
    }
    final migration = switch (theme) {
      AppThemeType.classicGray => _classicColorMigration,
      AppThemeType.limeCoral => _limeCoralColorMigration,
    };
    final migrated = migration[normalized];
    if (migrated == null) return tag;
    return tag.copyWith(colorHex: migrated);
  }

  Future<void> saveTags(List<TagItem> tags) async {
    final file = await _file;
    await file.writeAsString(const JsonEncoder.withIndent('  ')
        .convert(tags.map((t) => t.toJson()).toList()));
  }
}
