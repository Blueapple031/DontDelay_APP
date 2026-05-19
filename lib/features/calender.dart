import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 상태 관리를 위한 이벤트 맵 (고유 ID 추가)
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // 테스트를 위한 초기 데이터 세팅 (id 추가)
    final today = DateTime.utc(
      _focusedDay.year,
      _focusedDay.month,
      _focusedDay.day,
    );
    _events = {
      today.add(const Duration(days: 2)): [
        {
          'id': '1',
          'title': '팀 프로젝트 회의',
          'category': '일정',
          'color': const Color(0xFFB5B9D5),
          'startDate': today.add(const Duration(days: 2)),
        },
      ],
      today.add(const Duration(days: 5)): [
        {
          'id': '2',
          'title': '알고리즘 과제 제출',
          'category': 'PNU',
          'color': const Color(0xFF90C2F9),
          'startDate': today.add(const Duration(days: 5)),
        },
      ],
    };
  }

  // 특정 날짜의 이벤트를 가져오는 함수
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // 오늘 기준 '다가오는 일정'을 날짜순으로 가져오는 함수
  List<Map<String, dynamic>> _getUpcomingEvents() {
    final today = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    List<Map<String, dynamic>> upcoming = [];

    final sortedKeys = _events.keys.toList()..sort();

    for (var date in sortedKeys) {
      if (date.isAfter(today) || date.isAtSameMomentAs(today)) {
        for (var event in _events[date]!) {
          upcoming.add({
            ...event,
            'date': date, // 화면 표시용 날짜
          });
        }
      }
    }
    return upcoming.take(5).toList();
  }

  // 일정 추가/수정/삭제 처리 로직
  void _handleScheduleAction(String action, Map<String, dynamic> eventData) {
    setState(() {
      final dateKey = DateTime.utc(
        eventData['startDate'].year,
        eventData['startDate'].month,
        eventData['startDate'].day,
      );

      if (action == 'add') {
        if (_events[dateKey] == null) _events[dateKey] = [];
        _events[dateKey]!.add(eventData);
      } else if (action == 'edit' || action == 'delete') {
        // 기존 일정을 찾아서 제거 (날짜가 변경되었을 수도 있으므로 전체 맵에서 해당 id를 찾아서 제거)
        for (var key in _events.keys) {
          _events[key]?.removeWhere((e) => e['id'] == eventData['id']);
        }

        // 수정인 경우 새로운 날짜 키에 다시 추가
        if (action == 'edit') {
          if (_events[dateKey] == null) _events[dateKey] = [];
          _events[dateKey]!.add(eventData);
        }

        // 빈 리스트 정리
        _events.removeWhere((key, value) => value.isEmpty);
      }
    });
  }

  // 다이얼로그 호출 헬퍼
  void _openScheduleDialog({Map<String, dynamic>? existingEvent}) {
    showDialog(
      context: context,
      builder: (context) => ScheduleDialog(
        selectedDate: _selectedDay ?? _focusedDay,
        existingEvent: existingEvent,
        onAction: _handleScheduleAction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcomingEvents = _getUpcomingEvents();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 헤더 영역
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '캘린더',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openScheduleDialog(), // 일정 추가 모드
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: const Text(
                    '일정 추가',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
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
            const SizedBox(height: 32),

            // 2. 메인 콘텐츠 영역
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 좌측: 달력 영역
                  Expanded(
                    flex: 7,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          TableCalendar(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,
                            selectedDayPredicate: (day) =>
                                isSameDay(_selectedDay, day),
                            onDaySelected: (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },
                            onPageChanged: (focusedDay) {
                              _focusedDay = focusedDay;
                            },
                            eventLoader: _getEventsForDay,
                            headerStyle: const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: false,
                              titleTextStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left,
                                color: Colors.black54,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right,
                                color: Colors.black54,
                              ),
                            ),
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              todayTextStyle: const TextStyle(
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.bold,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: Color(0xFF4F46E5),
                                shape: BoxShape.circle,
                              ),
                              outsideDaysVisible: false,
                            ),
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                if (events.isEmpty) return const SizedBox();
                                final eventList =
                                    events as List<Map<String, dynamic>>;

                                return Positioned(
                                  bottom: 4,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: eventList.take(3).map((event) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1.5,
                                        ),
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: event['color'],
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // 우측: 다가오는 일정 리스트
                  Expanded(
                    flex: 3,
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
                          const Text(
                            '다가오는 일정',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: upcomingEvents.isEmpty
                                ? const Center(
                                    child: Text(
                                      '다가오는 일정이 없습니다.',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: upcomingEvents.length,
                                    itemBuilder: (context, index) {
                                      final event = upcomingEvents[index];
                                      return _buildUpcomingEventCard(event);
                                    },
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
      ),
    );
  }

  // 일정 카드 위젯 (클릭 기능 추가)
  Widget _buildUpcomingEventCard(Map<String, dynamic> event) {
    return InkWell(
      onTap: () => _openScheduleDialog(existingEvent: event), // 수정 모드로 다이얼로그 열기
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: event['color'],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['title'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MM월 dd일').format(event['date']),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: event['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event['category'],
                      style: TextStyle(
                        color: event['color'],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 일정 추가 및 수정 다이얼로그 (통합)
// ---------------------------------------------------------
class ScheduleDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Map<String, dynamic>? existingEvent; // null이면 추가, 있으면 수정 모드
  final Function(String action, Map<String, dynamic> eventData)
  onAction; // action: 'add', 'edit', 'delete'

  const ScheduleDialog({
    super.key,
    required this.selectedDate,
    this.existingEvent,
    required this.onAction,
  });

  @override
  State<ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<ScheduleDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _titleController;
  late bool _isEditMode;

  final List<Map<String, dynamic>> _categories = [
    {'name': '일정', 'color': const Color(0xFFB5B9D5), 'isPrivate': true},
  ];

  String? _selectedCategory;
  late DateTime _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.existingEvent != null;

    // 탭 컨트롤러 설정 (일반, 기간, 반복)
    _tabController = TabController(length: 3, vsync: this);

    // 기존 데이터가 있다면 폼 채우기 (수정 모드)
    if (_isEditMode) {
      final event = widget.existingEvent!;
      _titleController = TextEditingController(text: event['title']);
      _selectedCategory = event['category'];
      _startDate = event['startDate'] ?? widget.selectedDate;
      _endDate = event['endDate'];

      if (event['type'] == '기간') _tabController.index = 1;
      if (event['type'] == '반복') _tabController.index = 2;
    } else {
      // 추가 모드 초기화
      _titleController = TextEditingController();
      _startDate = widget.selectedDate;
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories[0]['name'];
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _submit(String action) {
    if (action != 'delete' && _titleController.text.trim().isEmpty) return;

    Color selectedColor = _categories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => _categories[0],
    )['color'];

    // 기존 ID가 없으면 새로 생성 (타임스탬프 활용)
    String eventId = _isEditMode
        ? widget.existingEvent!['id']
        : DateTime.now().millisecondsSinceEpoch.toString();

    widget.onAction(action, {
      'id': eventId,
      'title': _titleController.text.trim(),
      'category': _selectedCategory,
      'color': selectedColor,
      'startDate': _startDate,
      'endDate': _tabController.index == 1 ? _endDate : null,
      'type': _tabController.index == 2
          ? '반복'
          : (_tabController.index == 1 ? '기간' : '일반'),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 헤더 (카테고리 선택 및 삭제 버튼)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '카테고리 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    if (_isEditMode) // 수정 모드일 때만 삭제 버튼 표시
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: '일정 삭제',
                        onPressed: () => _submit('delete'),
                      ),
                    TextButton(
                      onPressed: () {
                        /* TODO: 마이페이지 편집 화면 이동 */
                      },
                      child: const Text(
                        '편집',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _categories
                  .map((cat) => _buildCategoryChip(cat))
                  .toList(),
            ),
            const SizedBox(height: 24),
            const Divider(),

            // 2. 날짜 설정 영역
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF4F46E5),
              tabs: const [
                Tab(text: '일반'),
                Tab(text: '기간'),
                Tab(text: '반복'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 60,
              child: TabBarView(
                controller: _tabController,
                children: [
                  Center(
                    child: Text(
                      '${DateFormat('yyyy년 MM월 dd일').format(_startDate)} (당일 일정)',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDateSelector(
                        _startDate,
                        (date) => setState(() => _startDate = date),
                      ),
                      const Text(
                        '~',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      _buildDateSelector(
                        _endDate ?? _startDate.add(const Duration(days: 1)),
                        (date) => setState(() => _endDate = date),
                      ),
                    ],
                  ),
                  const Center(child: Text('반복 옵션 선택 기능 (추후 구현)')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. 일정 내용 입력
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: '일정 제목을 입력하세요',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 4. 하단 액션 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _submit(_isEditMode ? 'edit' : 'add'),
                  child: Text(
                    _isEditMode ? '수정' : '등록',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(Map<String, dynamic> category) {
    bool isSelected = _selectedCategory == category['name'];
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category['name']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? category['color'] : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: category['color'].withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category['isPrivate'] ? Icons.lock : Icons.circle,
              size: 16,
              color: category['color'],
            ),
            const SizedBox(height: 8),
            Text(
              category['name'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector(DateTime date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onSelect(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(DateFormat('MM월 dd일').format(date)),
      ),
    );
  }
}
