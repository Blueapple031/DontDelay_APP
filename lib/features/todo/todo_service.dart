import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'todo_model.dart';

/// OS별 [getApplicationDocumentsDirectory] 아래 `DontDelay/todos.json`에
/// 할 일 목록을 JSON으로 저장합니다. (Windows 예: `...\Documents\DontDelay\todos.json`)
class TodoService {
  static const _appFolderName = 'DontDelay';
  static const _fileName = 'todos.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/$_appFolderName');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File('${appDir.path}/$_fileName');
  }

  Future<List<TodoItem>> loadTodos() async {
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
      throw TodoStorageException('todos.json 내용이 유효한 JSON이 아닙니다: $e');
    }
    if (decoded is! List) {
      throw const TodoStorageException(
        'todos.json의 루트가 배열(List)이 아닙니다.',
      );
    }
    try {
      return decoded
          .cast<Map<String, dynamic>>()
          .map(TodoItem.fromJson)
          .toList();
    } catch (e, st) {
      Error.throwWithStackTrace(
        TodoStorageException('할 일 데이터 형식이 올바르지 않습니다: $e'),
        st,
      );
    }
  }

  Future<void> saveTodos(List<TodoItem> todos) async {
    final file = await _file;
    final jsonString = const JsonEncoder.withIndent('  ')
        .convert(todos.map((t) => t.toJson()).toList());
    await file.writeAsString(jsonString);
  }
}

class TodoStorageException implements Exception {
  final String message;
  const TodoStorageException(this.message);

  @override
  String toString() => 'TodoStorageException: $message';
}
