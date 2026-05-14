import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 임시 이벤트 데이터 (실제로는 Riverpod 등에서 가져와야 함)
  // key는 날짜(시간 제외), value는 일정 리스트
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
    DateTime.utc(2026, 5, 10): [
      {'title': '팀 프로젝트 회의', 'type': '일정', 'color': Colors.blue},
    ],
    DateTime.utc(2026, 5, 12): [
      {'title': '알고리즘 과제 제출', 'type': '마감', 'color': Colors.orange},
    ],
    DateTime.utc(2026, 5, 15): [
      {'title': '물리 실험', 'type': '일정', 'color': Colors.blue},
    ],
    DateTime.utc(2026, 5, 20): [
      {'title': '운영체제 시험', 'type': '시험', 'color': Colors.red},
    ],
    DateTime.utc(2026, 5, 22): [
      {'title': '알고리즘 시험', 'type': '시험', 'color': Colors.red},
    ],
    DateTime.utc(2026, 5, 25): [
      {'title': '데이터베이스 시험', 'type': '시험', 'color': Colors.red},
    ],
  };

  // 특정 날짜의 이벤트를 가져오는 함수
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 영역 (타이틀 & 버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '캘린더',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text(
                  '일정 추가',
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
          const SizedBox(height: 32),

          // 2. 메인 콘텐츠 (좌측 캘린더 7 : 우측 일정 리스트 3)
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
                        // 달력 헤더 및 본문 (TableCalendar 사용)
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

                          // 디자인 커스텀
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
                              color: const Color(0xFF6D28D9).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            todayTextStyle: const TextStyle(
                              color: Color(0xFF6D28D9),
                              fontWeight: FontWeight.bold,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: Color(0xFF6D28D9),
                              shape: BoxShape.circle,
                            ),
                            outsideDaysVisible: false,
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekendStyle: TextStyle(
                              color: Colors.blue,
                            ), // 일요일/토요일 색상 조정 필요시
                          ),

                          // 마커(이벤트 뱃지) 커스텀 빌더
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, date, events) {
                              if (events.isEmpty) return const SizedBox();

                              // 이벤트를 렌더링하기 위해 타입 캐스팅
                              final eventList =
                                  events as List<Map<String, dynamic>>;

                              return Positioned(
                                bottom: 4,
                                child: Column(
                                  children: eventList.map((event) {
                                    return Container(
                                      margin: const EdgeInsets.only(top: 2),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: event['color'],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        event['title'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        maxLines: 1,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          ),
                        ),

                        const Spacer(),
                        // 하단 범례
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              _buildLegendItem('시험', Colors.red),
                              const SizedBox(width: 16),
                              _buildLegendItem('마감', Colors.orange),
                              const SizedBox(width: 16),
                              _buildLegendItem('일정', Colors.blue),
                            ],
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
                          child: ListView(
                            children: [
                              _buildUpcomingEventCard(
                                '팀 프로젝트 회의',
                                '5월 10일',
                                '14:00',
                                Colors.blue,
                              ),
                              _buildUpcomingEventCard(
                                '알고리즘 과제 제출',
                                '5월 12일',
                                '23:59',
                                Colors.orange,
                              ),
                              _buildUpcomingEventCard(
                                '물리 실험',
                                '5월 15일',
                                '10:00',
                                Colors.blue,
                              ),
                              _buildUpcomingEventCard(
                                '운영체제 시험',
                                '5월 20일',
                                '전일',
                                Colors.red,
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

  // 캘린더 하단 범례 아이템
  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // 우측 다가오는 일정 카드
  Widget _buildUpcomingEventCard(
    String title,
    String date,
    String time,
    Color tagColor,
  ) {
    return Container(
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
              color: tagColor,
              borderRadius: BorderRadius.circular(4),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
