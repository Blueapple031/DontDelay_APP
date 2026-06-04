import 'package:flutter/material.dart';

import 'coming_soon_overlay.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ComingSoonOverlay(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 대시보드 헤더 (인사말 & 날짜)
            const Text(
              '안녕하세요! 👋',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '2026년 5월 11일 월요일',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),

            // 2. 메인 컨텐츠 영역 (좌측 6 : 우측 4 비율)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 좌측 컬럼 (AI 추천, 할 일, 일정)
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      _buildAIBanner(context),
                      const SizedBox(height: 24),
                      _buildTodayTodos(),
                      const SizedBox(height: 24),
                      _buildTodaySchedule(),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                // 우측 컬럼 (진행률, 알림, 저장한 콘텐츠)
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _buildProgressSection(),
                      const SizedBox(height: 24),
                      _buildReviewNotifications(),
                      const SizedBox(height: 24),
                      _buildSavedContents(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI 추천',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '운영체제 복습 기록이 부족해요. 오늘 30분 복습을 추천합니다. 알고리즘 과제 마감이 임박했으니 우선 처리하세요.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '자세히 보기',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTodos() {
    return _buildCard(
      title: '오늘의 할 일',
      icon: Icons.check_circle_outline,
      trailing: const Text(
        '3개',
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
      ),
      child: Column(
        children: [
          _buildTodoItem('운영체제 3단원 복습', '오늘', '높음', Colors.red),
          _buildDivider(),
          _buildTodoItem('알고리즘 과제 제출', '오늘 23:59', '높음', Colors.red),
          _buildDivider(),
          _buildTodoItem('데이터베이스 강의 시청', '내일', '보통', Colors.orange),
        ],
      ),
    );
  }

  Widget _buildTodaySchedule() {
    return _buildCard(
      title: '오늘 일정',
      icon: Icons.calendar_today_outlined,
      child: Column(
        children: [
          _buildScheduleItem('10:00', '운영체제 강의'),
          _buildDivider(),
          _buildScheduleItem('14:00', '팀 프로젝트 회의'),
          _buildDivider(),
          _buildScheduleItem('16:00', '알고리즘 스터디'),
        ],
      ),
    );
  }

  // ==========================================
  // [우측 영역] 위젯 모음
  // ==========================================

  Widget _buildProgressSection() {
    return _buildCard(
      title: '학습 진행률',
      icon: Icons.trending_up,
      child: Column(
        children: [
          _buildProgressBar('운영체제', 0.65, const Color(0xFF7D8F24)),
          const SizedBox(height: 16),
          _buildProgressBar('알고리즘', 0.82, const Color(0xFF10B981)),
          const SizedBox(height: 16),
          _buildProgressBar('데이터베이스', 0.43, const Color(0xFFF97316)),
        ],
      ),
    );
  }

  Widget _buildReviewNotifications() {
    return _buildCard(
      title: '복습 알림',
      icon: Icons.notifications_none,
      child: Column(
        children: [
          _buildNotificationCard(
            '운영체제 2단원',
            '3일 전 학습 · 복습 필요',
            const Color(0xFFFFF7ED),
            const Color(0xFFF97316),
          ),
          const SizedBox(height: 12),
          _buildNotificationCard(
            '자료구조 트리',
            '1주일 전 학습 · 복습 권장',
            const Color(0xFFF0F7CC),
            const Color(0xFF7D8F24),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedContents() {
    return _buildCard(
      title: '저장한 콘텐츠',
      icon: Icons.bookmark_border,
      child: Column(
        children: [
          _buildContentItem('React Hooks 완벽 가이드', '유튜브', '개발'),
          _buildDivider(),
          _buildContentItem('시험 공부법 - Notion', '웹페이지', '학습법'),
        ],
      ),
    );
  }

  // ==========================================
  // [공통 컴포넌트] 디자인을 통일하기 위한 헬퍼 위젯들
  // ==========================================

  Widget _buildCard({
    required String title,
    required IconData icon,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.black87),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(padding: const EdgeInsets.all(20.0), child: child),
        ],
      ),
    );
  }

  Widget _buildTodoItem(
    String title,
    String time,
    String priority,
    Color priorityColor,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: false,
            onChanged: (val) {},
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            priority,
            style: TextStyle(
              color: priorityColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(String time, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String title, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              '${(percent * 100).toInt()}%',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(
    String title,
    String subtitle,
    Color bgColor,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentItem(String title, String source, String tag) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildBadge(source, Colors.grey.shade100, Colors.grey.shade700),
              const SizedBox(width: 8),
              _buildBadge(
                tag,
                const Color(0xFFF0F7CC),
                const Color(0xFF6F7F1F),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
    );
  }
}
