import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const MainLayout({super.key, required this.child, required this.currentPath});

  final List<Map<String, dynamic>> _menuItems = const [
    {'title': '대시보드', 'icon': Icons.dashboard_outlined, 'path': '/dashboard'},
    {'title': '할 일', 'icon': Icons.check_box_outlined, 'path': '/todo'},
    {
      'title': '캘린더',
      'icon': Icons.calendar_today_outlined,
      'path': '/calendar',
    },
    {'title': 'URL 보관함', 'icon': Icons.bookmark_border, 'path': '/keepurl'},
    {'title': '회고록', 'icon': Icons.book_outlined, 'path': '/retrospective'},
    {'title': '시험기간 모드', 'icon': Icons.school_outlined, 'path': '/exam_mode'},
    {'title': 'AI 코치', 'icon': Icons.smart_toy_outlined, 'path': '/ai_coach'},
    {'title': '마이페이지', 'icon': Icons.person_outline, 'path': '/mypage'},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

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
                      style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                        fontSize: 28,
                        
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
                        final isSelected = currentPath.startsWith(
                          item['path'] as String,
                        );
                        final selectedColor = Color.lerp(
                          cs.primary,
                          cs.onSurface,
                          0.18,
                        )!;
                        final selectedBg = Color.lerp(
                          cs.primaryContainer,
                          cs.surface,
                          0.42,
                        )!;

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 3.0,
                          ),
                          child: ListTile(
                            leading: Icon(
                              item['icon'] as IconData,
                              color: isSelected
                                  ? selectedColor
                                  : cs.onSurfaceVariant,
                              size: 20,
                            ),
                            title: Text(
                              item['title'] as String,
                              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                color: isSelected ? selectedColor : cs.onSurface,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            selected: isSelected,
                            selectedTileColor: selectedBg,
                            onTap: () => context.go(item['path'] as String),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 구분선
          VerticalDivider(thickness: 1, width: 1, color: cs.outlineVariant),

          // ── 메인 컨텐츠 ─────────────────────────────────────────────────────
          Expanded(
            child: ColoredBox(color: cs.surface, child: child),
          ),
        ],
      ),
    );
  }
}
