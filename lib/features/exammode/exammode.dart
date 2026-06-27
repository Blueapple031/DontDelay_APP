import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exammode_models.dart';
import 'exammode_providers.dart';

class ExamModeScreen extends ConsumerStatefulWidget {
  const ExamModeScreen({super.key});

  @override
  ConsumerState<ExamModeScreen> createState() => _ExamModeScreenState();
}

class _ExamModeScreenState extends ConsumerState<ExamModeScreen> {
  // Timer State
  bool _isTimerRunning = false;
  int _remainingSeconds = 25 * 60; // Default: 25 minutes
  Timer? _timer;

  // Selected Subject for Timer
  String? _selectedSubjectId;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) return;
    setState(() {
      _isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });

        // Increment overall total study time
        ref.read(totalStudyTimeProvider.notifier).increment(1);

        // If a subject is selected, increment its accumulated time
        if (_selectedSubjectId != null) {
          ref
              .read(subjectsProvider.notifier)
              .incrementSeconds(_selectedSubjectId!, 1);
        }
      } else {
        _stopTimer();
        _showTimerCompletionDialog();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isTimerRunning = false;
      _remainingSeconds = 25 * 60;
    });
  }

  void _resetTimer() {
    setState(() {
      _remainingSeconds = 25 * 60;
    });
  }

  void _showTimerCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber),
            SizedBox(width: 8),
            Text('집중 완료!'),
          ],
        ),
        content: const Text('포모도로 1세트(25분)를 완료했습니다! 잠시 휴식을 취해보세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // --- Format Utils ---
  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minStr = minutes.toString().padLeft(2, '0');
    final secStr = seconds.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  String _formatAccumulatedTime(int totalSeconds) {
    if (totalSeconds == 0) return '0초';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    List<String> parts = [];
    if (hours > 0) parts.add('$hours시간');
    if (minutes > 0) parts.add('$minutes분');
    if (seconds > 0 || parts.isEmpty) parts.add('$seconds초');
    return parts.join(' ');
  }

  String _calculateDDay(DateTime examDate) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final targetDate = DateTime(examDate.year, examDate.month, examDate.day);
    final difference = targetDate.difference(todayDate).inDays;

    if (difference == 0) {
      return 'D-Day';
    } else if (difference > 0) {
      return 'D-$difference';
    } else {
      return 'D+${difference.abs()}';
    }
  }

  // --- Dialogs ---
  void _showAddExamDialog() {
    final nameController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('시험 일정 등록'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '시험 이름',
                  hintText: '예: 운영체제 중간고사',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '날짜: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365 * 5),
                        ),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: const Text('날짜 선택'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  ref.read(examsProvider.notifier).addExam(name, selectedDate);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('등록'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('과목 추가'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '과목 이름',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref.read(subjectsProvider.notifier).addSubject(name);
                Navigator.of(context).pop();
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog(List<StudySubject> subjects) {
    final titleController = TextEditingController();
    String selectedSubject = subjects.isNotEmpty ? subjects.first.name : '기타';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('오늘의 필수 목표 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '목표 내용',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedSubject,
                decoration: const InputDecoration(
                  labelText: '관련 과목',
                  border: OutlineInputBorder(),
                ),
                items: [
                  ...subjects.map(
                    (s) => DropdownMenuItem(value: s.name, child: Text(s.name)),
                  ),
                  if (!subjects.any((s) => s.name == '기타'))
                    const DropdownMenuItem(value: '기타', child: Text('기타')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      selectedSubject = val;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  ref
                      .read(examTasksProvider.notifier)
                      .addTask(title, selectedSubject);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _resetAllAccumulatedTimes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('학습 기록 초기화'),
        content: const Text(
          '전체 누적 시간 및 모든 과목의 학습 시간이 0초로 초기화됩니다. 정말 초기화하시겠습니까?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(totalStudyTimeProvider.notifier).reset();
              ref.read(subjectsProvider.notifier).resetAllSeconds();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('초기화', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Listen to providers
    final examsAsync = ref.watch(examsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final tasksAsync = ref.watch(examTasksProvider);
    final totalStudyTimeAsync = ref.watch(totalStudyTimeProvider);

    final overallTotalSeconds = totalStudyTimeAsync.value ?? 0;
    final subjects = subjectsAsync.value ?? [];
    final dndOn = ref.watch(dndProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 영역 (방해금지 모드 표시 + 시험 추가 버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        '시험기간 모드',
                        style: Theme.of(context).textTheme.headlineLarge!
                            .copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
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
              Row(
                children: [
                  // 집중 모드 토글 (방해금지 토글 버튼)
                  InkWell(
                    onTap: () {
                      ref.read(dndProvider.notifier).toggle();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: dndOn ? const Color(0xFFFEE2E2) : Colors.grey.shade100, // 연한 빨간색 또는 연한 회색
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: dndOn ? const Color(0xFFF87171) : Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            dndOn ? Icons.do_not_disturb_on : Icons.notifications_active_outlined,
                            color: dndOn ? const Color(0xFFDC2626) : Colors.grey.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dndOn ? '방해금지 켜짐' : '방해금지 꺼짐',
                            style: Theme.of(context).textTheme.labelLarge!
                                .copyWith(
                                  color: dndOn ? const Color(0xFFDC2626) : Colors.grey.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 시험 추가 버튼 (방해금지 켜짐 옆에 배치하여 더 작고 깔끔하게 수정)
                  OutlinedButton.icon(
                    onPressed: _showAddExamDialog,
                    icon: Icon(Icons.add, size: 14, color: colorScheme.primary),
                    label: Text(
                      '시험 추가',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      side: BorderSide(
                        color: colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. D-Day 카드 섹션 (가로 스크롤로 오버플로우 방지)
          examsAsync.when(
            data: (exams) {
              if (exams.isEmpty) {
                return SizedBox(
                  height: 70,
                  child: Center(
                    child: Text(
                      '등록된 시험 일정이 없습니다. 우측 상단에서 시험을 추가해보세요!',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 70,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: exams.length,
                        itemBuilder: (context, index) {
                          final exam = exams[index];
                          // D-Day 색상 결정
                          Color cardColor = colorScheme.primary;
                          if (index == 0) cardColor = Colors.red;
                          if (index == 1) cardColor = Colors.orange;

                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: Container(
                              width: 250,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: cardColor.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: cardColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          exam.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          '${exam.date.year}.${exam.date.month.toString().padLeft(2, '0')}.${exam.date.day.toString().padLeft(2, '0')}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Row(
                                    children: [
                                      Text(
                                        _calculateDDay(exam.date),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: cardColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.grey[400],
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(examsProvider.notifier)
                                              .deleteExam(exam.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(
              height: 70,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                const SizedBox(height: 70, child: Text('일정을 불러오지 못했습니다.')),
          ),
          const SizedBox(height: 24),

          // 3. 메인 집중 영역 (타이머 + 오늘 할 일)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 좌측: 포모도로 타이머
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 48,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 과목 선택 드롭다운 영역
                                subjectsAsync.when(
                                  data: (subjects) {
                                    // Ensure _selectedSubjectId is valid or null
                                    if (_selectedSubjectId != null &&
                                        !subjects.any(
                                          (s) => s.id == _selectedSubjectId,
                                        )) {
                                      _selectedSubjectId = null;
                                    }

                                    return Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: DropdownButtonHideUnderline(
                                                  child: DropdownButton<String>(
                                                    value: _selectedSubjectId,
                                                    hint: const Text(
                                                      '집중할 과목을 선택하세요',
                                                    ),
                                                    isExpanded: true,
                                                    items: [
                                                      const DropdownMenuItem<
                                                        String
                                                      >(
                                                        value: null,
                                                        child: Text('선택 안 함'),
                                                      ),
                                                      ...subjects.map(
                                                        (s) => DropdownMenuItem(
                                                          value: s.id,
                                                          child: Text(
                                                            s.name,
                                                          ), // 과목명 옆의 누적 시간 텍스트 제거
                                                        ),
                                                      ),
                                                    ],
                                                    onChanged: (val) {
                                                      setState(() {
                                                        _selectedSubjectId =
                                                            val;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // 과목 추가 버튼
                                            IconButton(
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                              ),
                                              color: colorScheme.primary,
                                              onPressed: _showAddSubjectDialog,
                                              tooltip: '과목 추가',
                                            ),
                                            // 과목 삭제 버튼
                                            IconButton(
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                              ),
                                              color: _selectedSubjectId != null
                                                  ? Colors.red
                                                  : Colors.grey,
                                              onPressed:
                                                  _selectedSubjectId != null
                                                  ? () {
                                                      final idToDelete =
                                                          _selectedSubjectId!;
                                                      setState(() {
                                                        _selectedSubjectId =
                                                            null;
                                                      });
                                                      ref
                                                          .read(
                                                            subjectsProvider
                                                                .notifier,
                                                          )
                                                          .deleteSubject(
                                                            idToDelete,
                                                          );
                                                    }
                                                  : null,
                                              tooltip: '현재 과목 삭제',
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                  loading: () =>
                                      const CircularProgressIndicator(),
                                  error: (err, stack) =>
                                      const Text('과목 목록을 불러오지 못했습니다.'),
                                ),
                                const SizedBox(height: 24),

                                // 타이머 원형 UI (화면 크기에 비례하여 크기 조정)
                                Container(
                                  width: 200,
                                  height: 200,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _formatTimer(_remainingSeconds),
                                          style: Theme.of(context)
                                              .textTheme
                                              .displayLarge!
                                              .copyWith(
                                                fontSize: 48,
                                                fontWeight: FontWeight.bold,
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
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // 타이머 컨트롤 버튼
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    OutlinedButton(
                                      onPressed: _resetTimer,
                                      style: OutlinedButton.styleFrom(
                                        shape: const CircleBorder(),
                                        padding: const EdgeInsets.all(12),
                                        side: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.refresh,
                                        color: Colors.grey.shade600,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton(
                                      onPressed: _isTimerRunning
                                          ? _pauseTimer
                                          : _startTimer,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isTimerRunning
                                            ? Colors.orange
                                            : colorScheme.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 16,
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        _isTimerRunning ? '일시정지' : '집중 시작',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge!
                                            .copyWith(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    OutlinedButton(
                                      onPressed: _stopTimer,
                                      style: OutlinedButton.styleFrom(
                                        shape: const CircleBorder(),
                                        padding: const EdgeInsets.all(12),
                                        side: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.stop,
                                        color: Colors.grey.shade600,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // 전체 누적 시간 및 과목별 누적 학습 시간 표시
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '전체 누적 학습 시간: ${_formatAccumulatedTime(overallTotalSeconds)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: EdgeInsets.zero,
                                            icon: Icon(
                                              Icons.refresh,
                                              size: 16,
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.7),
                                            ),
                                            tooltip: '누적 시간 초기화',
                                            onPressed:
                                                _resetAllAccumulatedTimes,
                                          ),
                                        ],
                                      ),
                                      // 공부한 이력이 있는 과목들만 필터링하여 하단에 표시
                                      if (subjects.any(
                                        (s) => s.accumulatedSeconds > 0,
                                      )) ...[
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          child: Divider(
                                            height: 1,
                                            thickness: 1,
                                          ),
                                        ),
                                        ...subjects
                                            .where(
                                              (s) => s.accumulatedSeconds > 0,
                                            )
                                            .map(
                                              (s) => Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 3,
                                                    ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      s.name,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[700],
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      _formatAccumulatedTime(
                                                        s.accumulatedSeconds,
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[800],
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
                    child: tasksAsync.when(
                      data: (tasks) {
                        final total = tasks.length;
                        final completed = tasks
                            .where((t) => t.isCompleted)
                            .length;
                        final double rate = total == 0
                            ? 0.0
                            : completed / total;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '오늘의 필수 목표',
                                  style: Theme.of(context).textTheme.titleLarge!
                                      .copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  '$completed/$total 완료 (${(rate * 100).toStringAsFixed(0)}%)',
                                  style: Theme.of(context).textTheme.labelLarge!
                                      .copyWith(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // 진행률 바
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: rate,
                                minHeight: 8,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 할 일 목록
                            Expanded(
                              child: total == 0
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.assignment_turned_in_outlined,
                                            size: 48,
                                            color: Colors.grey[300],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            '등록된 필수 목표가 없습니다.',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: tasks.length,
                                      itemBuilder: (context, index) {
                                        final task = tasks[index];
                                        return _buildExamTaskItem(task);
                                      },
                                    ),
                            ),

                            // 목표 추가 버튼
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Pass current subjects to dialog
                                  final subjects = subjectsAsync.value ?? [];
                                  _showAddGoalDialog(subjects);
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('필수 목표 추가'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) =>
                          const Center(child: Text('목표를 불러오지 못했습니다.')),
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

  // 시험 전용 할 일 아이템 빌더
  Widget _buildExamTaskItem(ExamTask task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: task.isCompleted ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: task.isCompleted
              ? Colors.grey.shade200
              : const Color(0xFFE2EAB5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: Icon(
              task.isCompleted
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: task.isCompleted ? Colors.green : Colors.grey.shade400,
              size: 24,
            ),
            onPressed: () {
              ref.read(examTasksProvider.notifier).toggleTask(task.id);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontSize: 14,
                    color: task.isCompleted
                        ? Colors.grey.shade500
                        : Colors.black87,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
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
                    task.subject,
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.grey[400], size: 20),
            onPressed: () {
              ref.read(examTasksProvider.notifier).deleteTask(task.id);
            },
          ),
        ],
      ),
    );
  }
}
