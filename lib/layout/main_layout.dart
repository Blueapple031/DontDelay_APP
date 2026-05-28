import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String currentPath;

  MainLayout({super.key, required this.child, required this.currentPath});

  // 사이드바 메뉴 리스트
  final List<Map<String, dynamic>> _menuItems = [
    {'title': '대시보드', 'icon': Icons.dashboard_outlined, 'path': '/dashboard'},
    {'title': '할 일', 'icon': Icons.check_box_outlined, 'path': '/todo'},
    {
      'title': '캘린더',
      'icon': Icons.calendar_today_outlined,
      'path': '/calendar',
    },
    {'title': 'URL 보관함', 'icon': Icons.bookmark_border, 'path': '/keepurl'},
    {'title': '일기', 'icon': Icons.book_outlined, 'path': '/diary'},
    {'title': '시험기간 모드', 'icon': Icons.school_outlined, 'path': '/exam_mode'},
    {
      'title': '시험 문제 생성',
      'icon': Icons.quiz_outlined,
      'path': '/exam_generator',
    },
    {'title': 'AI 코치', 'icon': Icons.smart_toy_outlined, 'path': '/ai_coach'},
    {'title': '마이페이지', 'icon': Icons.person_outline, 'path': '/mypage'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 1. 좌측 사이드바 영역
          Container(
            width: 220,
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'DontDelay',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      // 현재 경로와 메뉴의 경로가 일치하는지 확인 (선택 상태 결정)
                      final isSelected = currentPath.startsWith(item['path']);

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          leading: Icon(
                            item['icon'],
                            color: isSelected
                                ? const Color(0xFF6D28D9)
                                : Colors.grey[600],
                            size: 20,
                          ),
                          title: Text(
                            item['title'],
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF6D28D9)
                                  : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          selected: isSelected,
                          selectedTileColor: const Color(
                            0xFFF3E8FF,
                          ), // 연한 보라색 배경
                          onTap: () {
                            if (item['path'] == '/dashboard' ||
                                item['path'] == '/todo' ||
                                item['path'] == '/calendar' ||
                                item['path'] == '/keepurl' ||
                                item['path'] == '/diary' ||
                                item['path'] == '/mypage' ||
                                item['path'] == '/exam_mode' ||
                                item['path'] == '/exam_generator' ||
                                item['path'] == '/ai_coach') {
                              context.go(item['path']);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('아직 준비 중인 화면입니다.'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(
            thickness: 1,
            width: 1,
            color: Color(0xFFEEEEEE),
          ),

          // 2. 우측 메인 컨텐츠 영역
          Expanded(
            child: Container(
              color: const Color(0x00BDDFB2),
              child: child, // 라우터에서 전달받은 화면을 여기에 보여줌
            ),
          ),
        ],
      ),
    );
  }
}
