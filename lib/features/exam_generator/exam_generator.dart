import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../auth/auth_provider.dart';
import 'exam_document_model.dart';
import 'exam_generator_provider.dart';

class ExamGeneratorScreen extends ConsumerStatefulWidget {
  const ExamGeneratorScreen({super.key});

  @override
  ConsumerState<ExamGeneratorScreen> createState() =>
      _ExamGeneratorScreenState();
}

class _ExamGeneratorScreenState extends ConsumerState<ExamGeneratorScreen> {
  final _subjectController = TextEditingController();
  final _dateFormat = DateFormat('yyyy.MM.dd HH:mm');

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(examGeneratorProvider, (prev, next) {
      final error = next.lastError;
      if (error != null && error != prev?.lastError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        ref.read(examGeneratorProvider.notifier).clearError();
      }
    });

    final isLoggedIn = ref.watch(authProvider);
    final state = ref.watch(examGeneratorProvider);
    final selected = state.selectedDocument;

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (!isLoggedIn) ...[
            const SizedBox(height: 16),
            _buildLoginBanner(context),
          ],
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildDocumentList(state)),
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: _buildDetailPanel(
                    isLoggedIn: isLoggedIn,
                    state: state,
                    selected: selected,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.quiz_outlined, color: Color(0xFF6D28D9), size: 28),
        const SizedBox(width: 12),
        const Text(
          '시험 문제 생성',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          tooltip: '새로고침',
          onPressed: ref.read(authProvider)
              ? () => ref.read(examGeneratorProvider.notifier).refreshDocuments()
              : null,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildLoginBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD97706)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('PDF 업로드는 로그인 후 이용할 수 있습니다.'),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('로그인'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentList(ExamGeneratorState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '업로드한 PDF',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: state.documents.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '목록을 불러오지 못했습니다.',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(examGeneratorProvider.notifier)
                            .refreshDocuments(),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (documents) {
                if (documents.isEmpty) {
                  return Center(
                    child: Text(
                      '아직 업로드한 PDF가 없습니다.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: documents.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = documents[index];
                    final isSelected =
                        doc.documentId == state.selectedDocumentId;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: const Color(0xFFF3E8FF),
                      title: Text(
                        doc.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          if (doc.subject != null) doc.subject!,
                          _dateFormat.format(doc.createdAt),
                        ].join(' · '),
                      ),
                      trailing: _StatusBadge(status: doc.status),
                      onTap: () => ref
                          .read(examGeneratorProvider.notifier)
                          .selectDocument(doc.documentId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel({
    required bool isLoggedIn,
    required ExamGeneratorState state,
    required ExamDocument? selected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PDF 업로드',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              enabled: isLoggedIn && !state.isUploading,
              decoration: const InputDecoration(
                labelText: '과목 (선택)',
                hintText: '예: 선형대수',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildUploadArea(isLoggedIn: isLoggedIn, state: state),
            if (selected != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),
              _buildSelectedDocumentDetail(selected),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea({
    required bool isLoggedIn,
    required ExamGeneratorState state,
  }) {
    return InkWell(
      onTap: isLoggedIn && !state.isUploading ? _pickAndUpload : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6D28D9),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.upload_file_outlined,
              size: 48,
              color: isLoggedIn ? const Color(0xFF6D28D9) : Colors.grey,
            ),
            const SizedBox(height: 12),
            Text(
              state.isUploading
                  ? '업로드 중...'
                  : 'PDF 파일을 선택하세요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isLoggedIn ? Colors.black87 : Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '최대 50MB · application/pdf',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (state.isUploading) ...[
              const SizedBox(height: 16),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDocumentDetail(ExamDocument doc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '선택한 문서',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            _StatusBadge(status: doc.status),
          ],
        ),
        const SizedBox(height: 12),
        Text(doc.title, style: const TextStyle(fontSize: 15)),
        if (doc.subject != null) ...[
          const SizedBox(height: 4),
          Text('과목: ${doc.subject}', style: TextStyle(color: Colors.grey[700])),
        ],
        if (doc.status.isProcessing) ...[
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: doc.progress > 0 ? doc.progress / 100 : null,
            backgroundColor: const Color(0xFFEDE9FE),
            color: const Color(0xFF6D28D9),
          ),
          const SizedBox(height: 8),
          Text(
            '${doc.status.label}${doc.progress > 0 ? ' (${doc.progress}%)' : ''}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
        ],
        if (doc.status == DocumentStatus.ready) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Text(
              '인덱싱이 완료되었습니다. '
              '문제 생성·PDF 다운로드는 Phase 4에서 연결됩니다.',
              style: TextStyle(color: Colors.green[800], fontSize: 13),
            ),
          ),
          if (doc.pageCount != null || doc.chunkCount != null) ...[
            const SizedBox(height: 12),
            Text(
              [
                if (doc.pageCount != null) '${doc.pageCount}페이지',
                if (doc.chunkCount != null) '${doc.chunkCount}개 chunk',
              ].join(' · '),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ],
        if (doc.status == DocumentStatus.failed) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Text(
              doc.errorMessage ?? doc.errorCode ?? '문서 처리에 실패했습니다.',
              style: TextStyle(color: Colors.red[800], fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withReadStream: false,
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final fileName = result.files.single.name;

    await ref.read(examGeneratorProvider.notifier).uploadDocument(
          filePath: path,
          title: fileName,
          subject: _subjectController.text.trim().isEmpty
              ? null
              : _subjectController.text.trim(),
        );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      DocumentStatus.ready => (const Color(0xFFDCFCE7), const Color(0xFF166534)),
      DocumentStatus.failed => (const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
      DocumentStatus.uploaded ||
      DocumentStatus.extracting ||
      DocumentStatus.indexing =>
        (const Color(0xFFEDE9FE), const Color(0xFF6D28D9)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
