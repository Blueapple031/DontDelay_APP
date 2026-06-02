import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme_provider.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentPath,
  });

  final List<Map<String, dynamic>> _menuItems = const [
    {'title': '대시보드', 'icon': Icons.dashboard_outlined, 'path': '/dashboard'},
    {'title': '할 일', 'icon': Icons.check_box_outlined, 'path': '/todo'},
    {'title': '캘린더', 'icon': Icons.calendar_today_outlined, 'path': '/calendar'},
    {'title': 'URL 보관함', 'icon': Icons.bookmark_border, 'path': '/keepurl'},
    {'title': '회고록', 'icon': Icons.book_outlined, 'path': '/retrospective'},
    {'title': '시험기간 모드', 'icon': Icons.school_outlined, 'path': '/exam_mode'},
    {'title': 'AI 코치', 'icon': Icons.smart_toy_outlined, 'path': '/ai_coach'},
    {'title': '마이페이지', 'icon': Icons.person_outline, 'path': '/mypage'},
  ];

  // 테마별 색상 표시
  static const _themeSwatches = {
    AppThemeType.grayscale: Color(0xFF8E8E8E),
    AppThemeType.blue: Color(0xFF7A9AB8),
    AppThemeType.greenTea: Color(0xFF7A9E80),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final currentTheme = ref.watch(themeProvider).maybeWhen(
          data: (t) => t,
          orElse: () => AppThemeType.grayscale,
        );

    return Scaffold(
      body: Row(
        children: [
          // ── 사이드바 ────────────────────────────────────────────────────────
          Material(
            color: cs.surface,
            child: SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                // 앱 타이틀
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'DontDelay',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),

                // 메뉴 목록
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      final isSelected =
                          currentPath.startsWith(item['path'] as String);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 3.0,
                        ),
                        child: ListTile(
                          leading: Icon(
                            item['icon'] as IconData,
                            color: isSelected ? cs.primary : cs.onSurfaceVariant,
                            size: 20,
                          ),
                          title: Text(
                            item['title'] as String,
                            style: TextStyle(
                              color: isSelected ? cs.primary : cs.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: cs.primaryContainer,
                          onTap: () => context.go(item['path'] as String),
                        ),
                      );
                    },
                  ),
                ),

                // ── 테마 스위처 ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(color: cs.outlineVariant, height: 1),
                      const SizedBox(height: 14),
                      Text(
                        '테마',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: AppThemeType.values.map((type) {
                          final isActive = type == currentTheme;
                          final swatchColor = _themeSwatches[type]!;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Tooltip(
                              message: type.label,
                              child: GestureDetector(
                                onTap: () => ref
                                    .read(themeProvider.notifier)
                                    .setTheme(type),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: swatchColor,
                                    shape: BoxShape.circle,
                                    border: isActive
                                        ? Border.all(
                                            color: cs.onSurface,
                                            width: 2,
                                          )
                                        : Border.all(
                                            color: Colors.transparent,
                                            width: 2,
                                          ),
                                    boxShadow: isActive
                                        ? [
                                            BoxShadow(
                                              color: swatchColor
                                                  .withOpacity(0.4),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),

          // 구분선
          VerticalDivider(
            thickness: 1,
            width: 1,
            color: cs.outlineVariant,
          ),

          // ── 메인 컨텐츠 ─────────────────────────────────────────────────────
          Expanded(
            child: ColoredBox(
              color: cs.surface,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
