import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_profile.dart';

// 세션 쿠키를 앱 전역에서 하나만 사용
final cookieJarProvider = Provider<CookieJar>((ref) {
  ref.keepAlive();
  return CookieJar();
});

final dioProvider = Provider<Dio>((ref) {
  ref.keepAlive();
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://dontdelay.duckdns.org:8080',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(CookieManager(ref.watch(cookieJarProvider)));
  return dio;
});

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile?>(UserProfileNotifier.new);

class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;

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

  Future<bool> login(String username, String password) async {
    try {
      final response = await ref.read(dioProvider).post(
            '/api/auth/login',
            data: {'username': username, 'password': password},
          );

      if (response.statusCode == 200) {
        state = true;
        await ref.read(userProfileProvider.notifier).applyFromResponse(
              response.data,
              refetchIfIncomplete: true,
            );
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
      if (response.statusCode == 200) {
        await applyFromResponse(response.data, refetchIfIncomplete: false);
        return;
      }
      debugPrint('프로필 조회 실패: status=${response.statusCode} body=${response.data}');
    } on DioException catch (e) {
      debugPrint(
        '프로필 조회 에러: status=${e.response?.statusCode} body=${e.response?.data}',
      );
    }
    state = null;
  }

  /// 로그인·/me 응답 본문에서 프로필 반영. 필드가 비어 있으면 /me 재조회.
  Future<void> applyFromResponse(
    dynamic data, {
    required bool refetchIfIncomplete,
  }) async {
    final parsed = UserProfile.tryParse(data);
    if (parsed != null && _hasCoreFields(parsed)) {
      state = parsed;
      return;
    }

    if (!refetchIfIncomplete) {
      if (parsed != null) state = parsed;
      return;
    }

    await load();
  }

  bool _hasCoreFields(UserProfile profile) {
    return profile.realName.isNotEmpty || profile.username.isNotEmpty;
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
