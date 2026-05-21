import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // 회원가입 API 연동 (성공 시 null, 실패 시 에러 메시지 반환)
  Future<String?> signUp(String username, String password) async {
    try {
      final response = await ref
          .read(dioProvider)
          .post(
            '/api/auth/signup',
            data: {'username': username, 'password': password},
          );

      if (response.statusCode == 200) {
        return null; // 성공
      }
      return "회원가입에 실패했습니다.";
    } on DioException catch (e) {
      // 명세서 조건: 400 Bad Request 시 username 중복
      if (e.response?.statusCode == 400) {
        return "이미 존재하는 사용자명입니다.";
      }
      return "서버와 연결할 수 없습니다.";
    }
  }

  // 로그인 API 연동
  Future<bool> login(String username, String password) async {
    try {
      final response = await ref
          .read(dioProvider)
          .post(
            '/api/auth/login',
            data: {'username': username, 'password': password},
          );

      if (response.statusCode == 200) {
        state = true; // 로그인 상태 true로 변경
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("로그인 에러: $e");
      return false;
    }
  }
}
