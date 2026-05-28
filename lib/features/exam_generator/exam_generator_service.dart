import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import 'exam_document_model.dart';
import 'exam_job_model.dart';
import 'exam_question_model.dart';

class ExamGeneratorException implements Exception {
  const ExamGeneratorException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'ExamGeneratorException($code): $message';
}

/// 업로드·Job 등 장시간 API용 Dio (세션 쿠키는 dioProvider와 공유)
final examDioProvider = Provider<Dio>((ref) {
  final base = ref.watch(dioProvider);
  return Dio(
    BaseOptions(
      baseUrl: base.options.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
    ),
  )..interceptors.addAll(base.interceptors);
});

final examGeneratorServiceProvider = Provider((ref) {
  return ExamGeneratorService(ref.watch(examDioProvider));
});

class ExamGeneratorService {
  ExamGeneratorService(this._dio);

  final Dio _dio;

  static final _examOptions = Options(
    sendTimeout: const Duration(seconds: 120),
    receiveTimeout: const Duration(seconds: 120),
  );

  Future<ExamDocument> uploadDocument({
    required String filePath,
    String? title,
    String? subject,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const ExamGeneratorException(
        code: 'FILE_NOT_FOUND',
        message: '파일을 찾을 수 없습니다.',
      );
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: file.uri.pathSegments.last,
        contentType: DioMediaType.parse('application/pdf'),
      ),
      if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
      if (subject != null && subject.trim().isNotEmpty)
        'subject': subject.trim(),
    });

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/exam/documents',
        data: formData,
        options: _examOptions,
      );
      return ExamDocument.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<List<ExamDocument>> listDocuments({String? status}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/exam/documents',
        queryParameters: {
          if (status != null) 'status': status,
        },
      );
      return ExamDocumentListResponse.fromJson(response.data!).items;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ExamDocument> getDocument(String documentId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/exam/documents/$documentId',
      );
      return ExamDocument.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ExamJob> createJob(String documentId, ExamJobOptions options) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/exam/jobs',
        data: {
          'documentId': documentId,
          'options': options.toJson(),
        },
        options: _examOptions,
      );
      return ExamJob.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<ExamJob> getJob(String jobId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/exam/jobs/$jobId',
      );
      return ExamJob.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<GeneratedExam> getExam(String examId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/exam/exams/$examId',
      );
      return GeneratedExam.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> downloadExamPdf(String examId, String savePath) async {
    try {
      await _dio.download(
        '/api/exam/exams/$examId/download',
        savePath,
        options: _examOptions,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ExamGeneratorException _mapDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      return const ExamGeneratorException(
        code: 'UNAUTHORIZED',
        message: '로그인이 필요합니다.',
      );
    }

    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      return ExamGeneratorException(
        code: data['error'] as String? ?? 'UNKNOWN',
        message: data['message'] as String? ?? '요청에 실패했습니다.',
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const ExamGeneratorException(
        code: 'TIMEOUT',
        message: '서버 응답 시간이 초과되었습니다.',
      );
    }

    return ExamGeneratorException(
      code: 'NETWORK',
      message: e.message ?? '서버와 연결할 수 없습니다.',
    );
  }
}
