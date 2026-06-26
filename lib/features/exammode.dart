import 'package:flutter/material.dart';

class ExamModeScreen extends StatefulWidget {
  const ExamModeScreen({super.key});

  @override
  State<ExamModeScreen> createState() => _ExamModeScreenState();
}

class _ExamModeScreenState extends State<ExamModeScreen> {
  bool _isTimerRunning = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 헤더 영역
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '시험기간 모드',
                          style: Theme.of(context).textTheme.headlineLarge!.copyWith(fontSize: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '다른 알림을 끄고 목표 달성에만 집중하세요',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
                // 집중 모드 토글 (디자인 요소)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2), // 연한 빨간색 배경
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF87171)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.do_not_disturb_on,
                        color: Color(0xFFDC2626),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '방해금지 켜짐',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          color: const Color(0xFFDC2626),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 2. D-Day 카드 섹션
            Row(
              children: [
                _buildDDayCard('운영체제 중간고사', 'D-9', Colors.red),
                const SizedBox(width: 16),
                _buildDDayCard('알고리즘 실기시험', 'D-11', Colors.orange),
                const SizedBox(width: 16),
                _buildDDayCard('데이터베이스 기말', 'D-20', colorScheme.primary),
              ],
            ),
            const SizedBox(height: 32),

            // 3. 메인 집중 영역 (타이머 + 오늘 할 일)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 좌측: 포모도로 타이머
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '집중 시간',
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // 타이머 원형 UI
                          Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isTimerRunning
                                    ? colorScheme.primary
                                    : Colors.grey.shade200,
                                width: 8,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '25:00',
                                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                                      fontSize: 56,
                                      color: _isTimerRunning
                                          ? colorScheme.primary
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '포모도로 1세트',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 48),
                          // 타이머 컨트롤 버튼
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(16),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: Icon(
                                  Icons.refresh,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 24),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isTimerRunning = !_isTimerRunning;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isTimerRunning
                                      ? Colors.orange
                                      : colorScheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 40,
                                    vertical: 20,
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  _isTimerRunning ? '일시정지' : '집중 시작',
                                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 24),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  shape: const CircleBorder(),
                                  padding: const EdgeInsets.all(16),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: Icon(
                                  Icons.stop,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // 우측: 시험기간 전용 할 일 목록
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '오늘의 필수 목표',
                                style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 18),
                              ),
                              Text(
                                '1/3 완료',
                                style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // 진행률 바
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0.33,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // 할 일 목록
                          Expanded(
                            child: ListView(
                              children: [
                                _buildExamTask(
                                  title: '운영체제 3단원 기출문제 3회독',
                                  isCompleted: true,
                                  subject: '운영체제',
                                ),
                                _buildExamTask(
                                  title: '알고리즘 DP 유형 5문제 풀이',
                                  isCompleted: false,
                                  subject: '알고리즘',
                                ),
                                _buildExamTask(
                                  title: '데이터베이스 정규화 개념 암기',
                                  isCompleted: false,
                                  subject: '데이터베이스',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  // D-Day 카드 빌더
  Widget _buildDDayCard(String title, String dDay, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall!.copyWith(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            Text(
              dDay,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontSize: 20,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 시험 전용 할 일 아이템 빌더
  Widget _buildExamTask({
    required String title,
    required bool isCompleted,
    required String subject,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? Colors.grey.shade200 : const Color(0xFFE3EAB6),
        ), // 약간 푸른 테두리
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCompleted ? Colors.green : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontSize: 15,
                    color: isCompleted ? Colors.grey.shade500 : Colors.black87,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subject,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
