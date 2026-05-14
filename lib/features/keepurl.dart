import 'package:flutter/material.dart';

class UrlScreen extends StatefulWidget {
  const UrlScreen({super.key});

  @override
  State<UrlScreen> createState() => _UrlScreenState();
}

class _UrlScreenState extends State<UrlScreen> {
  // 카테고리 탭 상태
  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['전체', '개발', '전공', '학습법', '자기계발'];

  // 더미 데이터
  final List<Map<String, dynamic>> _urlList = [
    {
      'title': 'React Hooks 완벽 가이드 - 벨로퍼트',
      'icon': Icons.play_circle_outline, // 유튜브/영상
      'category': '개발',
      'tags': ['React', 'Frontend', '강의'],
      'date': '2026-05-08',
      'watchLater': true,
    },
    {
      'title': '시험 공부법 - Notion 템플릿',
      'icon': Icons.language, // 웹페이지
      'category': '학습법',
      'tags': ['Notion', '생산성', '학습'],
      'date': '2026-05-07',
      'watchLater': true,
    },
    {
      'title': '운영체제 개념 정리 PDF',
      'icon': Icons.description_outlined, // 문서
      'category': '전공',
      'tags': ['운영체제', 'CS', '정리노트'],
      'date': '2026-05-06',
      'watchLater': false,
    },
    {
      'title': '알고리즘 문제 풀이 전략',
      'icon': Icons.play_circle_outline,
      'category': '개발',
      'tags': ['알고리즘', 'PS', '코딩테스트'],
      'date': '2026-05-05',
      'watchLater': false,
    },
    {
      'title': '데이터베이스 설계 패턴',
      'icon': Icons.language,
      'category': '전공',
      'tags': ['데이터베이스', 'SQL', '설계'],
      'date': '2026-05-04',
      'watchLater': true,
    },
    {
      'title': '효율적인 시간 관리법',
      'icon': Icons.language,
      'category': '자기계발',
      'tags': ['생산성', '시간관리'],
      'date': '2026-05-03',
      'watchLater': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 (타이틀 & 추가 버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'URL 보관함',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '나중에 볼 학습 자료를 한 곳에서 관리하세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text(
                  'URL 추가',
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

          // 2. 검색 및 필터 영역
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '제목, 태그로 검색...',
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
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(
                  Icons.filter_list,
                  size: 18,
                  color: Colors.black87,
                ),
                label: const Text(
                  '필터',
                  style: TextStyle(color: Colors.black87),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
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

          // 3. 카테고리 칩 (가로 스크롤 가능)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_categories.length, (index) {
                final isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(_categories[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                    selectedColor: const Color(0xFF6D28D9),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF6D28D9)
                            : Colors.grey.shade300,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // 4. AI 자동 분류 배너
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'AI 자동 분류',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '저장된 URL을 자동으로 카테고리와 태그로 분류합니다',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6D28D9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '분류 시작',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 5. URL 카드 그리드 (반응형 2열 구조)
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2열
                crossAxisSpacing: 24, // 가로 여백
                mainAxisSpacing: 24, // 세로 여백
                childAspectRatio: 2.2, // 카드 가로세로 비율 (디자인에 맞게 조절)
              ),
              itemCount: _urlList.length,
              itemBuilder: (context, index) {
                final item = _urlList[index];
                return _buildUrlCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 개별 URL 카드 위젯
  Widget _buildUrlCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상단: 아이콘 & 나중에 보기 뱃지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF), // 연한 파란색/보라색
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  item['icon'],
                  color: const Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              if (item['watchLater'])
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED), // 연한 주황색
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '나중에 보기',
                    style: TextStyle(
                      color: Color(0xFFF97316),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          // 중단: 제목
          Text(
            item['title'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // 하단: 카테고리, 태그, 날짜
          Row(
            children: [
              _buildBadge(
                item['category'],
                const Color(0xFFEEF2FF),
                const Color(0xFF6366F1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ...((item['tags'] as List<String>).map((tag) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: _buildBadge(
                    tag,
                    Colors.grey.shade100,
                    Colors.grey.shade600,
                  ),
                );
              }).toList()),
            ],
          ),
          const Spacer(),
          Text(
            '저장일: ${item['date']}',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // 뱃지 공통 위젯
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
}
