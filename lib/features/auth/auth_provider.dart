import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/api_error.dart';
import 'user_profile.dart';

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile?>(UserProfileNotifier.new);

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  /// 서버 연결 확인 (`GET /api/health`)
  Future<String?> checkServerHealth() async {
    try {
      final response = await ref.read(dioProvider).get('/api/health');
      if (response.statusCode == 200) return null;
      return '서버 상태를 확인할 수 없습니다.';
    } on DioException catch (e) {
      return parseConnectionError(e) ?? '서버와 연결할 수 없습니다.';
    } catch (e) {
      debugPrint('서버 상태 확인 에러: $e');
      return '서버와 연결할 수 없습니다.';
    }
  }

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

  /// 성공 시 null, 실패 시 사용자에게 보여줄 메시지 반환
  Future<String?> login(String username, String password) async {
    try {
      final response = await ref.read(dioProvider).post(
            '/api/auth/login',
            data: {'username': username, 'password': password},
          );

      if (response.statusCode == 200) {
        state = true;
        await ref.read(userProfileProvider.notifier).syncAfterLogin(response.data);
        return null;
      }
      return '로그인에 실패했습니다.';
    } on DioException catch (e) {
      debugPrint(
        '로그인 에러: status=${e.response?.statusCode} body=${e.response?.data}',
      );
      return _parseLoginError(e);
    } catch (e) {
      debugPrint('로그인 에러: $e');
      return '서버와 연결할 수 없습니다.';
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
    final profile = await _fetchMe();
    if (profile != null) {
      state = profile;
    }
  }

  /// 1) 로그인 응답 프로필 반영 → 2) /me로 세션·프로필 확인
  Future<void> syncAfterLogin(dynamic loginBody) async {
    final fromLogin = UserProfile.tryParse(loginBody);
    if (fromLogin != null && fromLogin.username.isNotEmpty) {
      state = fromLogin;
    }

    final fromMe = await _fetchMe();
    if (fromMe != null) {
      state = fromMe;
    }
  }

  Future<UserProfile?> _fetchMe() async {
    try {
      final response = await ref.read(dioProvider).get('/api/auth/me');
      if (response.statusCode == 200) {
        return UserProfile.tryParse(response.data);
      }
      debugPrint('프로필 조회 실패: status=${response.statusCode} body=${response.data}');
    } on DioException catch (e) {
      debugPrint(
        '프로필 조회 에러: status=${e.response?.statusCode} body=${e.response?.data}',
      );
    }
    return null;
  }

  void clear() => state = null;
}

String _parseLoginError(DioException e) {
  final connectionError = parseConnectionError(e);
  if (connectionError != null) return connectionError;

  final message = messageFromResponse(e.response?.data);

  if (isInvalidCredentials(e)) {
    return message ?? '아이디 또는 비밀번호가 올바르지 않습니다.';
  }

  if (isAuthEndpointBlocked(e)) {
    return '서버에 연결되었지만 로그인 API가 차단되어 있습니다. '
        '백엔드에서 /api/auth/login, /api/auth/signup 을 permitAll로 설정해주세요.';
  }

  if (message != null && message.isNotEmpty) return message;
  return '로그인에 실패했습니다.';
}

String _parseSignupError(DioException e) {
  final connectionError = parseConnectionError(e);
  if (connectionError != null) return connectionError;

  if (e.response?.statusCode == 400) {
    final message = messageFromResponse(e.response?.data);
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return '입력값을 확인해주세요.';
  }

  if (isAuthEndpointBlocked(e)) {
    return '서버에 연결되었지만 회원가입 API가 차단되어 있습니다. '
        '백엔드에서 /api/auth/signup 을 permitAll로 설정해주세요.';
  }

  return '서버와 연결할 수 없습니다.';
}
