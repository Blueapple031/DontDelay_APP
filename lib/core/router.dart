import 'package:go_router/go_router.dart';
import '../layout/main_layout.dart';
import '../features/dashboard.dart';
import '../features/todo/todo.dart';
import '../features/calender.dart';
import '../features/keepurl.dart';
import '../features/diary.dart';
import '../features/exammode.dart';
import '../features/aicoach.dart';

// GoRouter 설정
final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard', // 앱을 처음 켰을 때 보여줄 경로

  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return MainLayout(
          // 현재 활성화된 경로를 MainLayout에 전달하여 사이드바 메뉴 선택 상태를 업데이트할 수 있게 합니다.
          currentPath: state.uri.path,
          child: child,
        );
      },
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(path: '/todo', builder: (context, state) => const TodoScreen()),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/keepurl',
          builder: (context, state) => const UrlScreen(),
        ),
        GoRoute(
          path: '/diary',
          builder: (context, state) => const DiaryScreen(),
        ),
        GoRoute(
          path: '/exam_mode',
          builder: (context, state) => const ExamModeScreen(),
        ),
        GoRoute(
          path: '/ai_coach',
          builder: (context, state) => const AiCoachScreen(),
        ),
      ],
    ),
  ],
);
