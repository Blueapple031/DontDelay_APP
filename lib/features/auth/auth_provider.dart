import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_profile.dart';

// 1. 세션(쿠키) 관리를 위한 Dio Provider 세팅
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://dontdelay.duckdns.org:8080',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  // Spring Security 세션 ID 유지를 위해 CookieManager 추가
  final cookieJar = CookieJar();
  dio.interceptors.add(CookieManager(cookieJar));

  return dio;
});

// 2. 로그인 상태 관리를 위한 Provider
final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

// 3. 로그인 사용자 프로필 (GET /api/auth/me)
final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile?>(UserProfileNotifier.new);

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // 회원가입 API 연동 (성공 시 null, 실패 시 에러 메시지 반환)
  Future<String?> signUp({
    required String username,
    required String password,
    required String realName,
    required String email,
    required String department,
  }) async {
    try {
      final response = await ref.read(dioProvider).post(
            '/api/auth/signup',
            data: {
              'username': username,
              'password': password,
              'realName': realName,
              'email': email,
              'department': department,
            },
          );

      if (response.statusCode == 200) {
        return null;
      }
      return '회원가입에 실패했습니다.';
    } on DioException catch (e) {
      return _parseSignupError(e);
    }
  }

  // 로그인 API 연동
  Future<bool> login(String username, String password) async {
    try {
      final response = await ref.read(dioProvider).post(
            '/api/auth/login',
            data: {'username': username, 'password': password},
          );

      if (response.statusCode == 200) {
        state = true;
        await ref.read(userProfileProvider.notifier).load();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('로그인 에러: $e');
      return false;
    }
  }

  void logout() {
    state = false;
    ref.read(userProfileProvider.notifier).clear();
  }
}

class UserProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() => null;

  Future<void> load() async {
    try {
      final response = await ref.read(dioProvider).get('/api/auth/me');
      if (response.statusCode == 200 && response.data is Map) {
        state = UserProfile.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }
    } on DioException catch (e) {
      debugPrint('프로필 조회 에러: $e');
      state = null;
    }
  }

  void clear() => state = null;
}

String _parseSignupError(DioException e) {
  if (e.response?.statusCode == 400) {
    final message = _messageFromResponse(e.response?.data);
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return '입력값을 확인해주세요.';
  }
  return '서버와 연결할 수 없습니다.';
}

String? _messageFromResponse(dynamic data) {
  if (data is Map) {
    final message = data['message'] ?? data['error'];
    if (message != null) {
      return message.toString();
    }
  }
  if (data is String && data.isNotEmpty) {
    return data;
  }
  return null;
}
