import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login.dart';
import '../features/auth/signup.dart';
import '../layout/main_layout.dart';
import '../features/dashboard.dart';
import '../features/todo/todo.dart';
import '../features/calender.dart';
import '../features/keepurl/keepurl.dart';
import '../features/retrospective.dart';
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
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      );

      return ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.025, 0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(
              begin: 0.94,
              end: 1,
            ).animate(curvedAnimation),
            child: child,
          ),
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
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
            path: '/retrospective',
            pageBuilder: (context, state) =>
                _pageTransition(state: state, child: const RetrospectiveScreen()),
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

  ref.onDispose(router.dispose);
  return router;
});
