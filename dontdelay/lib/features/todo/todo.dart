import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TodoScreen extends StatelessWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '할 일 관리',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '드래그하여 상태를 변경하세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF6D28D9),
                      size: 18,
                    ),
                    label: const Text(
                      'AI 자동 분류',
                      style: TextStyle(color: Color(0xFF6D28D9)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF6D28D9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text(
                      '새 할 일 추가',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5), // 인디고 색상
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 2. 칸반 보드 영역 (3개의 컬럼)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKanbanColumn(
                  title: '해야 할 일',
                  count: 3,
                  children: [
                    _buildTaskCard(
                      title: '운영체제 3단원 복습',
                      date: '2026-05-09',
                      priority: '높음',
                      tag: '학습',
                      priorityColor: Colors.red,
                    ),
                    _buildTaskCard(
                      title: '알고리즘 과제 제출',
                      date: '2026-05-09',
                      priority: '높음',
                      tag: '과제',
                      priorityColor: Colors.red,
                    ),
                    _buildTaskCard(
                      title: '데이터베이스 강의 시청',
                      date: '2026-05-10',
                      priority: '보통',
                      tag: '강의',
                      priorityColor: Colors.orange,
                    ),
                    _buildAddCardButton(),
                  ],
                ),
                const SizedBox(width: 24),
                _buildKanbanColumn(
                  title: '진행 중',
                  count: 2,
                  children: [
                    _buildTaskCard(
                      title: '팀 프로젝트 기획서 작성',
                      date: '2026-05-11',
                      priority: '보통',
                      tag: '프로젝트',
                      priorityColor: Colors.orange,
                    ),
                    _buildTaskCard(
                      title: '영어 에세이 초안 작성',
                      date: '2026-05-12',
                      priority: '낮음',
                      tag: '과제',
                      priorityColor: Colors.green,
                    ),
                    _buildAddCardButton(),
                  ],
                ),
                const SizedBox(width: 24),
                _buildKanbanColumn(
                  title: '완료',
                  count: 2,
                  children: [
                    _buildTaskCard(
                      title: '수학 문제 풀이',
                      date: '2026-05-08',
                      priority: '보통',
                      tag: '학습',
                      priorityColor: Colors.orange,
                    ),
                    _buildTaskCard(
                      title: '물리 실험 보고서',
                      date: '2026-05-07',
                      priority: '높음',
                      tag: '과제',
                      priorityColor: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 헬퍼 위젯 모음
  // ==========================================

  // 각 칸반 컬럼 (해야 할 일, 진행 중, 완료)
  Widget _buildKanbanColumn({
    required String title,
    required int count,
    required List<Widget> children,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent, // 배경을 투명하게 하거나 아주 연한 회색으로 할 수 있습니다.
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 컬럼 헤더
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // 태스크 카드 목록
            Expanded(child: ListView(children: children)),
          ],
        ),
      ),
    );
  }

  // 개별 할 일 카드
  Widget _buildTaskCard({
    required String title,
    required String date,
    required String priority,
    required String tag,
    required Color priorityColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBadge(
                priority,
                priorityColor.withOpacity(0.1),
                priorityColor,
              ),
              const SizedBox(width: 8),
              _buildBadge(
                tag,
                const Color(0xFFEEF2FF),
                const Color(0xFF6366F1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 카드 추가 버튼 (점선 테두리)
  Widget _buildAddCardButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: CustomPaintDecoration(
            border: Border.all(
              color: Colors.grey.shade400,
              style: BorderStyle.none,
            ),
            borderRadius: BorderRadius.circular(12),
            dashPattern: const [6, 4],
          ),
          child: const Center(
            child: Text(
              '+ 카드 추가',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  // 뱃지 (우선순위, 태그 등)
  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
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
}

class CustomPaintDecoration extends Decoration {
  final Border border;
  final BorderRadius borderRadius;
  final List<double> dashPattern;

  const CustomPaintDecoration({
    required this.border,
    required this.borderRadius,
    required this.dashPattern,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CustomPaintDecorationPainter(border, borderRadius, dashPattern);
  }
}

class _CustomPaintDecorationPainter extends BoxPainter {
  final Border border;
  final BorderRadius borderRadius;
  final List<double> dashPattern;

  _CustomPaintDecorationPainter(
    this.border,
    this.borderRadius,
    this.dashPattern,
  );

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final rect = offset & configuration.size!;
    final paint = Paint()
      ..color = border.top.color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(rect, borderRadius.topLeft);

    Path path = Path()..addRRect(rrect);
    Path dashPath = Path();
    double distance = 0.0;

    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        double dashLength = dashPattern[0];
        double spaceLength = dashPattern[1];
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + spaceLength;
      }
      distance = 0.0;
    }

    canvas.drawPath(dashPath, paint);
  }
}
