import 'package:flutter/material.dart';

class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 영역
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF6D28D9),
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI 코치',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '학습 계획과 우선순위를 AI가 추천해드립니다',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 2. 채팅 영역 (메인 컨텐츠)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildUserMessage('오늘 뭐부터 해야 해?', '14:23'),
                        const SizedBox(height: 24),
                        _buildAiMessage(
                          time: '14:23',
                          content:
                              '안녕하세요! 오늘의 우선순위를 분석해드릴게요.\n\n'
                              '현재 상황을 정리하면:\n'
                              '1. **긴급**: 알고리즘 과제 마감이 오늘 23:59입니다\n'
                              '2. **중요**: 운영체제 복습이 3일째 밀려있어요 (시험 D-11)\n'
                              '3. **예정**: 오후 4시 알고리즘 스터디가 있습니다\n\n'
                              '추천 순서는 다음과 같아요:',
                          recommendations: [
                            {
                              'title': '알고리즘 과제 완성',
                              'time': '14:30 - 16:00',
                              'tag': '마감 임박',
                              'tagColor': Colors.red,
                            },
                            {
                              'title': '알고리즘 스터디 참여',
                              'time': '16:00 - 17:30',
                              'tag': '예정된 일정',
                              'tagColor': Colors.blue,
                            },
                            {
                              'title': '운영체제 3단원 복습',
                              'time': '18:00 - 18:30',
                              'tag': '복습 지연',
                              'tagColor': Colors.orange,
                            },
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),

                  // 3. 입력창 및 빠른 제안 칩
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'AI 코치에게 질문하기...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6D28D9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildQuickSuggestion('오늘 할 일 추천해줘'),
                            _buildQuickSuggestion('시험 공부 계획 세워줘'),
                            _buildQuickSuggestion('복습이 필요한 과목은?'),
                          ],
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
    );
  }

  // 사용자 메시지 버블
  Widget _buildUserMessage(String text, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF6D28D9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // AI 메시지 버블 (추천 카드 포함 가능)
  Widget _buildAiMessage({
    required String content,
    required String time,
    List<Map<String, dynamic>>? recommendations,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E8FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Color(0xFF6D28D9),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                      if (recommendations != null &&
                          recommendations.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...recommendations
                            .map((rec) => _buildRecommendationCard(rec))
                            ,
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48), // 우측 여백 확보
        ],
      ),
    );
  }

  // AI 추천 할 일 카드
  Widget _buildRecommendationCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['time'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item['tag'],
                      style: TextStyle(
                        color: item['tagColor'],
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_outline,
            color: Colors.grey.shade300,
            size: 24,
          ),
        ],
      ),
    );
  }

  // 빠른 제안 버튼
  Widget _buildQuickSuggestion(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}
