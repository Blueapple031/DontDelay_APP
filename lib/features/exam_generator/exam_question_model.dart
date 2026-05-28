/// Phase 4+ 생성 시험 문항 모델
class ExamQuestion {
  const ExamQuestion({
    required this.number,
    required this.type,
    required this.stem,
    this.choices = const [],
    this.answer,
    this.explanation,
  });

  final int number;
  final String type;
  final String stem;
  final List<String> choices;
  final String? answer;
  final String? explanation;

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    final rawChoices = json['choices'] as List<dynamic>? ?? [];
    return ExamQuestion(
      number: json['number'] as int? ?? 0,
      type: json['type'] as String? ?? 'short_answer',
      stem: json['stem'] as String? ?? '',
      choices: rawChoices.map((e) => e.toString()).toList(),
      answer: json['answer'] as String?,
      explanation: json['explanation'] as String?,
    );
  }
}

class GeneratedExam {
  const GeneratedExam({
    required this.examId,
    required this.documentId,
    required this.title,
    this.subject,
    this.difficulty,
    required this.questions,
    required this.createdAt,
    this.downloadUrl,
  });

  final String examId;
  final String documentId;
  final String title;
  final String? subject;
  final String? difficulty;
  final List<ExamQuestion> questions;
  final DateTime createdAt;
  final String? downloadUrl;

  factory GeneratedExam.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List<dynamic>? ?? [];
    return GeneratedExam(
      examId: json['examId'] as String,
      documentId: json['documentId'] as String,
      title: json['title'] as String? ?? '시험',
      subject: json['subject'] as String?,
      difficulty: json['difficulty'] as String?,
      questions: rawQuestions
          .cast<Map<String, dynamic>>()
          .map(ExamQuestion.fromJson)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      downloadUrl: json['downloadUrl'] as String?,
    );
  }
}
