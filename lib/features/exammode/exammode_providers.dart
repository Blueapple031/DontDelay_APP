import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exammode_models.dart';
import 'exammode_service.dart';

final examModeServiceProvider = Provider((ref) => ExamModeService());

// --- Exams Provider ---
final examsProvider =
    AsyncNotifierProvider<ExamsNotifier, List<ExamItem>>(
  ExamsNotifier.new,
);

class ExamsNotifier extends AsyncNotifier<List<ExamItem>> {
  ExamModeService get _service => ref.read(examModeServiceProvider);

  @override
  Future<List<ExamItem>> build() async {
    return _service.loadExams();
  }

  Future<void> addExam(String name, DateTime date) async {
    final previous = state.value ?? [];
    final newExam = ExamItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      date: date,
    );
    final updated = [...previous, newExam];
    state = AsyncData(updated);
    await _service.saveExams(updated);
  }

  Future<void> deleteExam(String id) async {
    final previous = state.value ?? [];
    final updated = previous.where((e) => e.id != id).toList();
    state = AsyncData(updated);
    await _service.saveExams(updated);
  }
}

// --- Subjects Provider ---
final subjectsProvider =
    AsyncNotifierProvider<SubjectsNotifier, List<StudySubject>>(
  SubjectsNotifier.new,
);

class SubjectsNotifier extends AsyncNotifier<List<StudySubject>> {
  ExamModeService get _service => ref.read(examModeServiceProvider);

  @override
  Future<List<StudySubject>> build() async {
    return _service.loadSubjects();
  }

  Future<void> addSubject(String name) async {
    final previous = state.value ?? [];
    // Prevent duplicate name
    if (previous.any((s) => s.name == name)) return;
    
    final newSubject = StudySubject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      accumulatedSeconds: 0,
    );
    final updated = [...previous, newSubject];
    state = AsyncData(updated);
    await _service.saveSubjects(updated);
  }

  Future<void> deleteSubject(String id) async {
    final previous = state.value ?? [];
    final updated = previous.where((s) => s.id != id).toList();
    state = AsyncData(updated);
    await _service.saveSubjects(updated);
  }

  Future<void> incrementSeconds(String id, int seconds) async {
    final previous = state.value ?? [];
    final updated = previous.map((s) {
      if (s.id == id) {
        return s.copyWith(accumulatedSeconds: s.accumulatedSeconds + seconds);
      }
      return s;
    }).toList();
    state = AsyncData(updated);
    await _service.saveSubjects(updated);
  }

  Future<void> resetAllSeconds() async {
    final previous = state.value ?? [];
    final updated = previous.map((s) => s.copyWith(accumulatedSeconds: 0)).toList();
    state = AsyncData(updated);
    await _service.saveSubjects(updated);
  }
}

// --- Tasks Provider ---
final examTasksProvider =
    AsyncNotifierProvider<ExamTasksNotifier, List<ExamTask>>(
  ExamTasksNotifier.new,
);

class ExamTasksNotifier extends AsyncNotifier<List<ExamTask>> {
  ExamModeService get _service => ref.read(examModeServiceProvider);

  @override
  Future<List<ExamTask>> build() async {
    return _service.loadTasks();
  }

  Future<void> addTask(String title, String subject) async {
    final previous = state.value ?? [];
    final newTask = ExamTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      isCompleted: false,
      subject: subject,
    );
    final updated = [...previous, newTask];
    state = AsyncData(updated);
    await _service.saveTasks(updated);
  }

  Future<void> toggleTask(String id) async {
    final previous = state.value ?? [];
    final updated = previous.map((t) {
      if (t.id == id) {
        return t.copyWith(isCompleted: !t.isCompleted);
      }
      return t;
    }).toList();
    state = AsyncData(updated);
    await _service.saveTasks(updated);
  }

  Future<void> deleteTask(String id) async {
    final previous = state.value ?? [];
    final updated = previous.where((t) => t.id != id).toList();
    state = AsyncData(updated);
    await _service.saveTasks(updated);
  }
}

// --- Total Study Time Provider ---
final totalStudyTimeProvider =
    AsyncNotifierProvider<TotalStudyTimeNotifier, int>(
  TotalStudyTimeNotifier.new,
);

class TotalStudyTimeNotifier extends AsyncNotifier<int> {
  ExamModeService get _service => ref.read(examModeServiceProvider);

  @override
  Future<int> build() async {
    return _service.loadTotalStudyTime();
  }

  Future<void> increment(int seconds) async {
    final current = state.value ?? 0;
    final updated = current + seconds;
    state = AsyncData(updated);
    await _service.saveTotalStudyTime(updated);
  }

  Future<void> reset() async {
    state = const AsyncData(0);
    await _service.saveTotalStudyTime(0);
  }
}

class DndNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}

final dndProvider = NotifierProvider<DndNotifier, bool>(DndNotifier.new);
