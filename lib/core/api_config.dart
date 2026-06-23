/// 백엔드 Base URL 설정.
///
/// 로컬 서버 테스트 시 [baseUrl]을 `http://localhost:8080`으로 바꾸거나
/// 실행 시 `--dart-define=API_BASE_URL=http://localhost:8080` 사용.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://dontdelay.duckdns.org:8080',
  );

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration examTimeout = Duration(seconds: 120);
}
