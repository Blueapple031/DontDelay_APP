import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'core/router.dart';
import 'core/theme/app_themes.dart';
import 'core/theme/theme_provider.dart';
import 'features/keepurl/url_api_server.dart';
import 'features/keepurl/url_connection_service.dart';
import 'features/keepurl/url_provider.dart';
import 'features/keepurl/keepurl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(1024, 768),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final container = ProviderContainer();
  final connectionService = UrlConnectionService();
  final apiServer = UrlApiServer(
    connectionService: connectionService,
    resolveOnAddUrl: () => createUrlApiAddHandler(container),
  );

  await apiServer.start();
  final config = await connectionService.loadOrCreate();
  container.read(urlApiServerStateProvider.notifier).updateServerState(
    UrlApiServerState(
      isRunning: apiServer.isRunning,
      startError: apiServer.startError,
      config: config,
    ),
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // AsyncNotifier: 로드 전에는 기본 테마(무채색)로 fallback
    final themeType = ref.watch(themeProvider).maybeWhen(
          data: (t) => t,
          orElse: () => AppThemeType.grayscale,
        );
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DontDelay',
      theme: AppThemes.getTheme(themeType),
      routerConfig: appRouter,
    );
  }
}

// github issue 파기 실습입니다