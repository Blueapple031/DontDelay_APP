import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'exammode_models.dart';

class ExamModeService {
  static const _appFolderName = 'DontDelay';
  static const _examsFileName = 'exams.json';
  static const _subjectsFileName = 'subjects.json';
  static const _tasksFileName = 'exam_tasks.json';

  Future<Directory> get _appDir async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/$_appFolderName');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  // --- Exams ---
  Future<File> get _examsFile async {
    final dir = await _appDir;
    return File('${dir.path}/$_examsFileName');
  }

  Future<List<ExamItem>> loadExams() async {
    try {
      final file = await _examsFile;
      if (!await file.exists()) return [];
      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) return [];
      final decoded = json.decode(jsonString);
      if (decoded is! List) return [];
      return decoded
          .cast<Map<String, dynamic>>()
          .map(ExamItem.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveExams(List<ExamItem> exams) async {
    try {
      final file = await _examsFile;
      final jsonString = const JsonEncoder.withIndent('  ')
          .convert(exams.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (_) {}
  }

  // --- Subjects ---
  Future<File> get _subjectsFile async {
    final dir = await _appDir;
    return File('${dir.path}/$_subjectsFileName');
  }

  Future<List<StudySubject>> loadSubjects() async {
    try {
      final file = await _subjectsFile;
      if (!await file.exists()) {
        // Return some default subjects
        return [
          StudySubject(id: '1', name: '운영체제', accumulatedSeconds: 0),
          StudySubject(id: '2', name: '알고리즘', accumulatedSeconds: 0),
          StudySubject(id: '3', name: '데이터베이스', accumulatedSeconds: 0),
        ];
      }
      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) return [];
      final decoded = json.decode(jsonString);
      if (decoded is! List) return [];
      return decoded
          .cast<Map<String, dynamic>>()
          .map(StudySubject.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSubjects(List<StudySubject> subjects) async {
    try {
      final file = await _subjectsFile;
      final jsonString = const JsonEncoder.withIndent('  ')
          .convert(subjects.map((s) => s.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (_) {}
  }

  // --- Tasks ---
  Future<File> get _tasksFile async {
    final dir = await _appDir;
    return File('${dir.path}/$_tasksFileName');
  }

  Future<List<ExamTask>> loadTasks() async {
    try {
      final file = await _tasksFile;
      if (!await file.exists()) {
        // Return default mock tasks
        return [
          ExamTask(
            id: '1',
            title: '운영체제 3단원 기출문제 3회독',
            isCompleted: true,
            subject: '운영체제',
          ),
          ExamTask(
            id: '2',
            title: '알고리즘 DP 유형 5문제 풀이',
            isCompleted: false,
            subject: '알고리즘',
          ),
          ExamTask(
            id: '3',
            title: '데이터베이스 정규화 개념 암기',
            isCompleted: false,
            subject: '데이터베이스',
          ),
        ];
      }
      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) return [];
      final decoded = json.decode(jsonString);
      if (decoded is! List) return [];
      return decoded
          .cast<Map<String, dynamic>>()
          .map(ExamTask.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks(List<ExamTask> tasks) async {
    try {
      final file = await _tasksFile;
      final jsonString = const JsonEncoder.withIndent('  ')
          .convert(tasks.map((t) => t.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (_) {}
  }

  // --- Total Study Time ---
  static const _totalTimeFileName = 'total_study_time.json';

  Future<File> get _totalTimeFile async {
    final dir = await _appDir;
    return File('${dir.path}/$_totalTimeFileName');
  }

  Future<int> loadTotalStudyTime() async {
    try {
      final file = await _totalTimeFile;
      if (!await file.exists()) return 0;
      final content = await file.readAsString();
      return int.tryParse(content.trim()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> saveTotalStudyTime(int seconds) async {
    try {
      final file = await _totalTimeFile;
      await file.writeAsString(seconds.toString());
    } catch (_) {}
  }
}
