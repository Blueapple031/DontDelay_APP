/// Phase 4+ 문제 생성 Job용 모델 (Phase 1에서는 UI placeholder만 사용)
enum ExamJobStatus {
  pending,
  generating,
  rendering,
  completed,
  failed;

  static ExamJobStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return ExamJobStatus.pending;
      case 'GENERATING':
        return ExamJobStatus.generating;
      case 'RENDERING':
        return ExamJobStatus.rendering;
      case 'COMPLETED':
        return ExamJobStatus.completed;
      case 'FAILED':
        return ExamJobStatus.failed;
      default:
        return ExamJobStatus.pending;
    }
  }

  bool get isProcessing =>
      this == ExamJobStatus.pending ||
      this == ExamJobStatus.generating ||
      this == ExamJobStatus.rendering;
}

class ExamJobOptions {
  const ExamJobOptions({
    required this.questionCount,
    required this.types,
    this.difficulty = 'medium',
    this.subject,
    this.includeExplanation = true,
  });

  final int questionCount;
  final List<String> types;
  final String difficulty;
  final String? subject;
  final bool includeExplanation;

  Map<String, dynamic> toJson() => {
        'questionCount': questionCount,
        'types': types,
        'difficulty': difficulty,
        if (subject != null) 'subject': subject,
        'includeExplanation': includeExplanation,
      };
}

class ExamJob {
  const ExamJob({
    required this.jobId,
    required this.documentId,
    required this.status,
    this.progress = 0,
    this.examId,
    this.errorCode,
    required this.createdAt,
    this.updatedAt,
  });

  final String jobId;
  final String documentId;
  final ExamJobStatus status;
  final int progress;
  final String? examId;
  final String? errorCode;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory ExamJob.fromJson(Map<String, dynamic> json) {
    return ExamJob(
      jobId: json['jobId'] as String,
      documentId: json['documentId'] as String,
      status: ExamJobStatus.fromApi(json['status'] as String? ?? 'PENDING'),
      progress: json['progress'] as int? ?? 0,
      examId: json['examId'] as String?,
      errorCode: json['errorCode'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}
