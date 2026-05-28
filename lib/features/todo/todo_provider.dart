import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_model.dart';
import 'todo_service.dart';

final todoServiceProvider = Provider((ref) => TodoService());

final todoListProvider =
    AsyncNotifierProvider<TodoListNotifier, List<TodoItem>>(
  TodoListNotifier.new,
);

class TodoListNotifier extends AsyncNotifier<List<TodoItem>> {
  TodoService get _service => ref.read(todoServiceProvider);

  @override
  Future<List<TodoItem>> build() async {
    return _service.loadTodos();
  }

  List<TodoItem> _currentList() {
    return state.value ?? [];
  }

  Future<void> addTodo(TodoItem todo) async {
    final previous = List<TodoItem>.from(_currentList());
    final updated = [...previous, todo];
    state = AsyncData<List<TodoItem>>(updated);
    try {
      await _service.saveTodos(updated);
    } catch (e, st) {
      state = AsyncData<List<TodoItem>>(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> updateTodo(TodoItem todo) async {
    final previous = List<TodoItem>.from(_currentList());
    final updated =
        previous.map((t) => t.id == todo.id ? todo : t).toList();
    state = AsyncData<List<TodoItem>>(updated);
    try {
      await _service.saveTodos(updated);
    } catch (e, st) {
      state = AsyncData<List<TodoItem>>(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> deleteTodo(String id) async {
    final previous = List<TodoItem>.from(_currentList());
    final updated = previous.where((t) => t.id != id).toList();
    state = AsyncData<List<TodoItem>>(updated);
    try {
      await _service.saveTodos(updated);
    } catch (e, st) {
      state = AsyncData<List<TodoItem>>(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> changeStatus(String id, TodoStatus newStatus) async {
    final previous = List<TodoItem>.from(_currentList());
    final updated = previous
        .map((t) => t.id == id ? t.copyWith(status: newStatus) : t)
        .toList();
    state = AsyncData<List<TodoItem>>(updated);
    try {
      await _service.saveTodos(updated);
    } catch (e, st) {
      state = AsyncData<List<TodoItem>>(previous);
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> updateUrgencyImportance(
    String id,
    int urgency,
    int importance,
  ) async {
    final u = urgency.clamp(1, 8).toInt();
    final im = importance.clamp(1, 8).toInt();
    final previous = List<TodoItem>.from(_currentList());
    final updated = previous
        .map(
          (t) => t.id == id
              ? t.copyWith(urgency: u, importance: im)
              : t,
        )
        .toList();
    state = AsyncData<List<TodoItem>>(updated);
    try {
      await _service.saveTodos(updated);
    } catch (e, st) {
      state = AsyncData<List<TodoItem>>(previous);
      Error.throwWithStackTrace(e, st);
    }
  }
}
