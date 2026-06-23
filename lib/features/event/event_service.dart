import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'event_model.dart';

class EventService {
  static const _appFolderName = 'DontDelay';
  static const _fileName = 'events.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/$_appFolderName');
    if (!await appDir.exists()) await appDir.create(recursive: true);
    return File('${appDir.path}/$_fileName');
  }

  Future<List<EventItem>> loadEvents() async {
    final file = await _file;
    if (!await file.exists()) return [];
    final jsonString = await file.readAsString();
    if (jsonString.trim().isEmpty) return [];
    try {
      final decoded = json.decode(jsonString);
      if (decoded is! List) return [];
      return decoded
          .cast<Map<String, dynamic>>()
          .map(EventItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEvents(List<EventItem> events) async {
    final file = await _file;
    final jsonString = const JsonEncoder.withIndent('  ')
        .convert(events.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonString);
  }
}
