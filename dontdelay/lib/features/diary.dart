import 'package:flutter/material.dart';

class DiaryScreen extends StatelessWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 더미 데이터
    final List<Map<String, dynamic>> dummyDiaries = [
      {
        'date': '2026-05-09',
        'emoji': '😊',
        'title': '알고리즘 과제 진행상황',
        'content': '오늘은 DP 문제를 집중적으로 풀었다. 처음엔 어려웠지만 점화식을 세우는 패턴이 보이기 시작했다...',
        'tags': ['학습', '알고리즘'],
      },
      {
        'date': '2026-05-08',
        'emoji': '😐',
        'title': '운영체제 공부 계획',
        'content': '시험이 2주 남았다. 3단원과 4단원이 약한 것 같아서 내일부터 집중적으로 복습해야겠다...',
        'tags': ['계획', '운영체제'],
      },
      {
        'date': '2026-05-07',
        'emoji': '🤔',
        'title': '팀 프로젝트 회의',
        'content':
            '오늘 팀원들과 프로젝트 방향을 정했다. 내가 백엔드를 맡기로 했는데 Spring Boot를 공부해야 할 것 같다...',
        'tags': ['프로젝트', '팀워크'],
      },
      {
        'date': '2026-05-06',
        'emoji': '🤩',
        'title': '생산성 높은 하루',
        'content':
            '오늘은 집중이 정말 잘 됐다! 할 일 목록의 80%를 완료했고, 운동도 했다. 이런 날이 계속되면 좋겠다...',
        'tags': ['생산성', '성취'],
      },
    ];

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
                  const Text(
                    '일기',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '하루를 기록하고 되돌아보세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text(
                  '새 일기 작성',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6D28D9),
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
          const SizedBox(height: 24),

          // 2. 검색 바
          TextField(
            decoration: InputDecoration(
              hintText: '일기 검색...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF6D28D9)),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 3. 일기 카드 그리드
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 2.2, // 카드 비율 조정
              ),
              itemCount: dummyDiaries.length,
              itemBuilder: (context, index) {
                final diary = dummyDiaries[index];
                return _buildDiaryCard(diary);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 일기 카드 위젯
  Widget _buildDiaryCard(Map<String, dynamic> diary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                diary['date'],
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              Text(diary['emoji'], style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            diary['title'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              diary['content'],
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: (diary['tags'] as List<String>).map((tag) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
