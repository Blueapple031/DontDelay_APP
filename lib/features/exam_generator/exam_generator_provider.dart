import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import 'exam_document_model.dart';
import 'exam_generator_service.dart';

class ExamGeneratorState {
  const ExamGeneratorState({
    this.documents = const AsyncLoading(),
    this.selectedDocumentId,
    this.isUploading = false,
    this.lastError,
  });

  final AsyncValue<List<ExamDocument>> documents;
  final String? selectedDocumentId;
  final bool isUploading;
  final String? lastError;

  ExamDocument? get selectedDocument {
    final list = documents.value;
    if (list == null || selectedDocumentId == null) return null;
    for (final doc in list) {
      if (doc.documentId == selectedDocumentId) return doc;
    }
    return null;
  }

  ExamGeneratorState copyWith({
    AsyncValue<List<ExamDocument>>? documents,
    String? selectedDocumentId,
    bool? isUploading,
    String? lastError,
    bool clearError = false,
    bool clearSelection = false,
  }) {
    return ExamGeneratorState(
      documents: documents ?? this.documents,
      selectedDocumentId: clearSelection
          ? null
          : (selectedDocumentId ?? this.selectedDocumentId),
      isUploading: isUploading ?? this.isUploading,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

final examGeneratorProvider =
    NotifierProvider<ExamGeneratorNotifier, ExamGeneratorState>(
  ExamGeneratorNotifier.new,
);

class ExamGeneratorNotifier extends Notifier<ExamGeneratorState> {
  Timer? _pollTimer;

  ExamGeneratorService get _service => ref.read(examGeneratorServiceProvider);

  @override
  ExamGeneratorState build() {
    ref.onDispose(_stopPolling);
    Future.microtask(refreshDocuments);
    return const ExamGeneratorState();
  }

  Future<void> refreshDocuments() async {
    if (!ref.read(authProvider)) {
      state = state.copyWith(
        documents: const AsyncData([]),
        clearError: true,
      );
      _stopPolling();
      return;
    }

    state = state.copyWith(
      documents: const AsyncLoading(),
      clearError: true,
    );

    try {
      final items = await _service.listDocuments();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(documents: AsyncData(items));
      _syncPolling(items);
    } catch (e) {
      state = state.copyWith(
        documents: AsyncError(e, StackTrace.current),
        lastError: _errorMessage(e),
      );
    }
  }

  void selectDocument(String? documentId) {
    state = state.copyWith(
      selectedDocumentId: documentId,
      clearSelection: documentId == null,
      clearError: true,
    );
  }

  Future<void> uploadDocument({
    required String filePath,
    String? title,
    String? subject,
  }) async {
    if (!ref.read(authProvider)) {
      state = state.copyWith(lastError: '로그인이 필요합니다.');
      return;
    }
    if (state.isUploading) return;

    state = state.copyWith(isUploading: true, clearError: true);

    try {
      final uploaded = await _service.uploadDocument(
        filePath: filePath,
        title: title,
        subject: subject,
      );

      final current = state.documents.value ?? [];
      final updated = [uploaded, ...current];
      state = state.copyWith(
        documents: AsyncData(updated),
        selectedDocumentId: uploaded.documentId,
        isUploading: false,
      );
      _syncPolling(updated);
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        lastError: _errorMessage(e),
      );
    }
  }

  void _syncPolling(List<ExamDocument> documents) {
    final needsPolling =
        documents.any((doc) => doc.status.isProcessing);
    if (needsPolling) {
      _startPolling();
    } else {
      _stopPolling();
    }
  }

  void _startPolling() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollProcessingDocuments();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollProcessingDocuments() async {
    final list = state.documents.value;
    if (list == null) return;

    final processing =
        list.where((doc) => doc.status.isProcessing).toList();
    if (processing.isEmpty) {
      _stopPolling();
      return;
    }

    try {
      final refreshed = List<ExamDocument>.from(list);
      for (final doc in processing) {
        final index =
            refreshed.indexWhere((d) => d.documentId == doc.documentId);
        if (index == -1) continue;
        refreshed[index] = await _service.getDocument(doc.documentId);
      }
      refreshed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = state.copyWith(documents: AsyncData(refreshed));
      if (!refreshed.any((doc) => doc.status.isProcessing)) {
        _stopPolling();
      }
    } catch (_) {
      // 폴링 실패는 조용히 무시 — 다음 주기에 재시도
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _errorMessage(Object e) {
    if (e is ExamGeneratorException) return e.message;
    return '요청 처리 중 오류가 발생했습니다.';
  }
}
