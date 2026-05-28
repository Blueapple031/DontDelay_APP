import 'dart:io';

/// 기본 브라우저에서 URL을 새 창/탭으로 엽니다.
Future<void> openUrlInBrowser(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return;

  if (Platform.isWindows) {
    await Process.start('cmd', ['/c', 'start', '', url], runInShell: true);
  } else if (Platform.isMacOS) {
    await Process.start('open', [url]);
  } else if (Platform.isLinux) {
    await Process.start('xdg-open', [url]);
  }
}
