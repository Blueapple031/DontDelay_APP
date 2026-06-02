import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class RetrospectiveItem {
  final String id;
  final String date;
  final String emoji;
  final String title;
  final String content;
  final List<String> tags;

  RetrospectiveItem({
    required this.id,
    required this.date,
    required this.emoji,
    required this.title,
    required this.content,
    required this.tags,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'emoji': emoji,
        'title': title,
        'content': content,
        'tags': tags,
      };

  factory RetrospectiveItem.fromJson(Map<String, dynamic> json) => RetrospectiveItem(
        id: json['id'] as String,
        date: json['date'] as String,
        emoji: json['emoji'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        tags: List<String>.from(json['tags'] as List),
      );
}

class RetrospectiveService {
  static const _appFolderName = 'DontDelay';
  static const _fileName = 'retrospectives.json';

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/$_appFolderName');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return File('${appDir.path}/$_fileName');
  }

  Future<List<RetrospectiveItem>> loadRetrospectives() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return _getDefaultRetrospectives();
      }
      final jsonString = await file.readAsString();
      if (jsonString.trim().isEmpty) {
        return _getDefaultRetrospectives();
      }
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((item) => RetrospectiveItem.fromJson(item)).toList();
    } catch (e) {
      return _getDefaultRetrospectives();
    }
  }

  Future<void> saveRetrospectives(List<RetrospectiveItem> list) async {
    try {
      final file = await _file;
      final jsonString = const JsonEncoder.withIndent('  ')
          .convert(list.map((r) => r.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      debugPrint('Failed to save retrospectives: $e');
    }
  }

  List<RetrospectiveItem> _getDefaultRetrospectives() {
    return [
      RetrospectiveItem(
        id: '1',
        date: '2026-05-09',
        emoji: '😊',
        title: '알고리즘 과제 회고',
        content: '오늘은 DP 문제를 집중적으로 풀었다. 처음엔 어려웠지만 점화식을 세우는 패턴이 보이기 시작했다. 지속적인 연습이 필요하다.',
        tags: ['학습', '알고리즘', 'KPT'],
      ),
      RetrospectiveItem(
        id: '2',
        date: '2026-05-08',
        emoji: '😐',
        title: '운영체제 중간고사 대비 회고',
        content: '시험이 2주 남았다. 3단원과 4단원이 약한 것 같아서 내일부터 집중적으로 복습해야겠다. 시간 배분을 잘하자.',
        tags: ['계획', '운영체제', '회고'],
      ),
      RetrospectiveItem(
        id: '3',
        date: '2026-05-07',
        emoji: '🤔',
        title: '팀 프로젝트 1차 스프린트 회고',
        content: '오늘 팀원들과 프로젝트 방향을 정했다. 내가 백엔드를 맡기로 했는데 Spring Boot 기초를 다져야 진행에 무리가 없을 것 같다.',
        tags: ['프로젝트', '팀워크', '스프린트'],
      ),
      RetrospectiveItem(
        id: '4',
        date: '2026-05-06',
        emoji: '🤩',
        title: '주간 생산성 및 피드백 회고',
        content: '오늘은 집중이 정말 잘 됐다! 할 일 목록의 80%를 완료했고, 운동도 병행했다. 매일 일일 피드백 루프를 돌리는 것이 유용하다.',
        tags: ['생산성', '성취', '피드백'],
      ),
    ];
  }
}

class RetrospectiveScreen extends StatefulWidget {
  const RetrospectiveScreen({super.key});

  @override
  State<RetrospectiveScreen> createState() => _RetrospectiveScreenState();
}

class _RetrospectiveScreenState extends State<RetrospectiveScreen> {
  final _searchController = TextEditingController();
  late RetrospectiveService _service;
  List<RetrospectiveItem> _retrospectives = [];

  @override
  void initState() {
    super.initState();
    _service = RetrospectiveService();
    _loadRetrospectivesData();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRetrospectivesData() async {
    final loaded = await _service.loadRetrospectives();
    setState(() {
      _retrospectives = loaded;
    });
  }

  List<RetrospectiveItem> get _filteredRetrospectives {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _retrospectives;
    return _retrospectives.where((r) {
      return r.title.toLowerCase().contains(query) ||
          r.content.toLowerCase().contains(query) ||
          r.tags.any((t) => t.toLowerCase().contains(query));
    }).toList();
  }

  void _showAddRetrospectiveDialog(Color themeColor, Color themeColorLight) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final tagsController = TextEditingController();
    String selectedEmoji = '😊';
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final List<String> emojis = ['😊', '😐', '🤔', '🤩', '😢', '🔥', '💻', '💪'];

    final result = await showDialog<RetrospectiveItem?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('새 회고 작성', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Emoji 선택
                      const Text(
                        '오늘의 감정/상태',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: emojis.map((emoji) {
                          final isSelected = selectedEmoji == emoji;
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedEmoji = emoji;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? themeColorLight : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? themeColor : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(emoji, style: const TextStyle(fontSize: 20)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      // 제목
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: '제목',
                          hintText: '오늘의 회고 제목을 입력하세요',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 내용
                      TextField(
                        controller: contentController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: '회고 내용',
                          hintText: '오늘 무엇을 배웠고, 무엇이 부족했는지 기록해 보세요',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 태그
                      TextField(
                        controller: tagsController,
                        decoration: const InputDecoration(
                          labelText: '태그 (쉼표로 구분)',
                          hintText: '예: 학습, 알고리즘, KPT',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: Text('취소', style: TextStyle(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final content = contentController.text.trim();
                    if (title.isEmpty || content.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('제목과 내용을 모두 입력해 주세요.')),
                      );
                      return;
                    }
                    final tagsRaw = tagsController.text.trim();
                    final tags = tagsRaw.isEmpty
                        ? <String>[]
                        : tagsRaw
                            .split(',')
                            .map((t) => t.trim())
                            .where((t) => t.isNotEmpty)
                            .toList();

                    Navigator.pop(
                      ctx,
                      RetrospectiveItem(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        date: dateStr,
                        emoji: selectedEmoji,
                        title: title,
                        content: content,
                        tags: tags,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('저장', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _retrospectives.insert(0, result);
      });
      _service.saveRetrospectives(_retrospectives);
    }
  }

  void _confirmDeleteRetrospective(RetrospectiveItem retro) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회고록 삭제'),
        content: Text('"${retro.title}" 회고록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _retrospectives.removeWhere((r) => r.id == retro.id);
              });
              _service.saveRetrospectives(_retrospectives);
              Navigator.pop(context);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.primary;
    final themeColorLight = Theme.of(context).colorScheme.primaryContainer;
    final themeOnColorLight = Theme.of(context).colorScheme.onPrimaryContainer;

    final filtered = _filteredRetrospectives;

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
                    '회고록',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '성장 과정을 기록하고 정기적으로 회고해 보세요',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddRetrospectiveDialog(themeColor, themeColorLight),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text(
                  '새 회고 작성',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
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
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '회고록 검색...',
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
                borderSide: BorderSide(color: themeColor),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // 3. 회고 카드 리스트
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      '등록된 회고록이 없습니다.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final retrospective = filtered[index];
                      return _buildRetrospectiveRow(
                        context,
                        retrospective,
                        themeColorLight,
                        themeOnColorLight,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 회고 로우 리스트 위젯 (낮은 높이 리스트 뷰 형태)
  Widget _buildRetrospectiveRow(
    BuildContext context,
    RetrospectiveItem retrospective,
    Color tagBg,
    Color tagText,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Emoji & Date
          SizedBox(
            width: 100,
            child: Row(
              children: [
                Text(retrospective.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    retrospective.date,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 수직 구분선
          Container(
            height: 32,
            width: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(width: 20),
          // 2. 제목 & 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  retrospective.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  retrospective.content,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // 3. 태그들
          if (retrospective.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: retrospective.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: tagBg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: tagText,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(width: 16),
          // 4. 삭제 버튼
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade400),
            onPressed: () => _confirmDeleteRetrospective(retrospective),
            tooltip: '회고 삭제',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
