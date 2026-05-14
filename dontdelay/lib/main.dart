import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'core/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 데스크탑 윈도우 설정
  await windowManager.ensureInitialized();
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800), // 초기 창 크기 설정
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

  runApp(ProviderScope(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AI Study Coach',
      theme: ThemeData(
        fontFamily: 'Pretendard', // 노션 느낌을 주려면 깔끔한 산세리프 폰트(Pretendard 추천) 적용
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
