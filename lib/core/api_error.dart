import 'package:dio/dio.dart';

String? messageFromResponse(dynamic data) {
  if (data is Map) {
    final message = data['message'];
    if (message != null) return message.toString();
  }
  if (data is String && data.isNotEmpty) return data;
  return null;
}

String? errorCodeFromResponse(dynamic data) {
  if (data is Map && data['error'] != null) {
    return data['error'].toString();
  }
  return null;
}

String? parseConnectionError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
      return '서버 응답 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.';
    case DioExceptionType.connectionError:
      return '서버와 연결할 수 없습니다. 서버가 실행 중인지 확인해주세요.';
    default:
      if (e.response == null) {
        return '서버와 연결할 수 없습니다. 네트워크 또는 서버 주소를 확인해주세요.';
      }
      return null;
  }
}

bool isAuthEndpointBlocked(DioException e) {
  final code = errorCodeFromResponse(e.response?.data);
  final message = messageFromResponse(e.response?.data);
  return code == 'UNAUTHORIZED' &&
      (message?.contains('로그인이 필요') == true);
}

bool isInvalidCredentials(DioException e) {
  return errorCodeFromResponse(e.response?.data) == 'INVALID_CREDENTIALS';
}

bool isUnauthorized(DioException e) {
  return e.response?.statusCode == 401 ||
      errorCodeFromResponse(e.response?.data) == 'UNAUTHORIZED';
}
