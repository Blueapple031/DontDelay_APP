enum DocumentStatus {
  uploaded,
  extracting,
  indexing,
  ready,
  failed;

  static DocumentStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'UPLOADED':
        return DocumentStatus.uploaded;
      case 'EXTRACTING':
        return DocumentStatus.extracting;
      case 'INDEXING':
        return DocumentStatus.indexing;
      case 'READY':
        return DocumentStatus.ready;
      case 'FAILED':
        return DocumentStatus.failed;
      default:
        return DocumentStatus.uploaded;
    }
  }

  String get label {
    switch (this) {
      case DocumentStatus.uploaded:
        return '업로드됨';
      case DocumentStatus.extracting:
        return '텍스트 추출 중';
      case DocumentStatus.indexing:
        return '인덱싱 중';
      case DocumentStatus.ready:
        return '준비됨';
      case DocumentStatus.failed:
        return '실패';
    }
  }

  bool get isProcessing =>
      this == DocumentStatus.uploaded ||
      this == DocumentStatus.extracting ||
      this == DocumentStatus.indexing;
}

class ExamDocument {
  const ExamDocument({
    required this.documentId,
    required this.title,
    this.subject,
    required this.status,
    this.progress = 0,
    this.pageCount,
    this.chunkCount,
    this.fileSizeBytes,
    this.errorCode,
    this.errorMessage,
    required this.createdAt,
    this.updatedAt,
  });

  final String documentId;
  final String title;
  final String? subject;
  final DocumentStatus status;
  final int progress;
  final int? pageCount;
  final int? chunkCount;
  final int? fileSizeBytes;
  final String? errorCode;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory ExamDocument.fromJson(Map<String, dynamic> json) {
    return ExamDocument(
      documentId: json['documentId'] as String,
      title: json['title'] as String? ?? '제목 없음',
      subject: json['subject'] as String?,
      status: DocumentStatus.fromApi(json['status'] as String? ?? 'UPLOADED'),
      progress: json['progress'] as int? ?? 0,
      pageCount: json['pageCount'] as int?,
      chunkCount: json['chunkCount'] as int?,
      fileSizeBytes: json['fileSizeBytes'] as int?,
      errorCode: json['errorCode'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

class ExamDocumentListResponse {
  const ExamDocumentListResponse({
    required this.items,
    required this.total,
  });

  final List<ExamDocument> items;
  final int total;

  factory ExamDocumentListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ExamDocumentListResponse(
      items: rawItems
          .cast<Map<String, dynamic>>()
          .map(ExamDocument.fromJson)
          .toList(),
      total: json['total'] as int? ?? rawItems.length,
    );
  }
}
