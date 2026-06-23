import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'api_config.dart';

/// [main]에서 PersistCookieJar로 초기화 후 override 합니다.
final cookieJarProvider = Provider<CookieJar>(
  (ref) => throw StateError('cookieJarProvider must be overridden in main()'),
);

Future<CookieJar> createPersistCookieJar() async {
  final dir = await getApplicationDocumentsDirectory();
  return PersistCookieJar(
    storage: FileStorage('${dir.path}/dontdelay_cookies'),
  );
}

final dioProvider = Provider<Dio>((ref) {
  ref.keepAlive();
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.defaultTimeout,
      receiveTimeout: ApiConfig.defaultTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(CookieManager(ref.watch(cookieJarProvider)));
  return dio;
});

/// PDF 업로드·인덱싱 등 장시간 Exam API용 (동일 CookieJar 공유)
final examDioProvider = Provider<Dio>((ref) {
  ref.keepAlive();
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.examTimeout,
      sendTimeout: ApiConfig.examTimeout,
      receiveTimeout: ApiConfig.examTimeout,
    ),
  );
  dio.interceptors.add(CookieManager(ref.watch(cookieJarProvider)));
  return dio;
});
