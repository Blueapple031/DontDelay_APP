import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login.dart';
import '../features/auth/signup.dart';
import '../layout/main_layout.dart';
import '../features/dashboard.dart';
import '../features/todo/todo.dart';
import '../features/calender.dart';
import '../features/keepurl/keepurl.dart';
import '../features/diary.dart';
import '../features/exammode.dart';
import '../features/aicoach.dart';
import '../features/mypage.dart';

Page<void> _pageTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    arguments: state.extra,
    restorationId: state.pageKey.value,
    transitionDuration: const Duration(milliseconds: 240),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuart,
        reverseCurve: Curves.easeInCubic,
      );

      return ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.88,
              end: 1,
            ).animate(curvedAnimation),
            child: child,
          ),
        ),
      );
    },
  );
}

// GoRouter 설정
final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard', // 앱 시작 시 가장 먼저 로그인 화면으로 이동
  routes: [
    // 1. 로그인 화면 (ShellRoute 바깥이므로 사이드바 없음)
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          _pageTransition(state: state, child: const LoginScreen()),
    ),
    GoRoute(
      path: '/signup',
      pageBuilder: (context, state) =>
          _pageTransition(state: state, child: const SignUpScreen()),
    ),
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
          pageBuilder: (context, state) =>
              _pageTransition(state: state, child: const DashboardScreen()),
        ),
        GoRoute(
          path: '/todo',
          pageBuilder: (context, state) =>
              _pageTransition(state: state, child: const TodoScreen()),
        ),
        GoRoute(
          path: '/calendar',
          pageBuilder: (context, state) =>
              _pageTransition(state: state, child: const CalendarScreen()),
        ),
        GoRoute(
          path: '/keepurl',
          pageBuilder: (context, state) =>
              _pageTransition(state: state, child: const UrlScreen()),
        ),
        GoRoute(
          path: '/diary',
          pageBuilder: (context, state) =>
              _pageTransition(state: state, child: const DiaryScreen()),
        ),
        GoRoute(
          path: '/exam_mode',
          pageBuilder: (context, state) =>
              _pageTransition(state: state, child: const ExamModeScreen()),
        ),
        GoRoute(
          path: '/ai_coach',
          pageBuilder: (context, state) =>
              _pageTransition(state: state, child: const AiCoachScreen()),
        ),
        GoRoute(
          path: '/mypage',
          pageBuilder: (context, state) =>
              _pageTransition(state: state, child: const MyPageScreen()),
        ),
      ],
    ),
  ],
);
