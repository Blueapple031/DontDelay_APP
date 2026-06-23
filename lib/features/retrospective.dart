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
    return [];
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

  Future<String?> _showEmojiPickerDialog(BuildContext context, Color themeColor) {
    final categories = {
      '표정': ['😊', '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '🥲', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😋', '😜', '🤪', '🤓', '😎', '🥳', '😏', '😒', '😞', '😔', '🥺', '😢', '😭', '😤', '😠', '😡', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤔', '🫣', '🤫', '🫡'],
      '공부/업무': ['💻', '⌨️', '🖥️', '📓', '📕', '📗', '📘', '📙', '📚', '📖', '✍️', '📝', '✏️', '🎨', '🎭', '🎬', '🎧', '💼', '📅', '📊', '📈', '📉', '📋', '📌', '📍', '📎', '🔑', '💡', '📢', '⏰', '🔋', '🏆', '🎖️', '🏅', '🥇'],
      '일상/활동': ['⚽', '🏀', '⚾', '🎾', '🏐', '🏉', '🎱', '🏓', '🏸', '🥋', '🛹', '⛷️', '🏂', '🏋️', '🧘', '🚴', '🏃', '🚶', '🏊', '🏄', '🧗', '⛺', '🏖️', '✈️', '🚗', '🚇', '🍿', '☕', '🍵', '🍺', '🥤', '🍕', '🍔', '🍟', '🍜', '🍰', '🍎', '🍙'],
      '사물/기호': ['🔥', '✨', '🌟', '⭐', '💫', '💥', '⚠️', '⚡', '💧', '💤', '💭', '💬', '🔔', '🎁', '🎈', '🎉', '🧸', '🔮', '🧿', '🍀', '🌸', '🌹', '🌈', '☀️', '☁️', '❄️', '☂️', '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💖', '💔']
    };

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return DefaultTabController(
          length: categories.length,
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            elevation: 8,
            child: Container(
              width: 360,
              height: 400,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '이모지 선택',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(ctx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    labelColor: themeColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: themeColor,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                    tabs: categories.keys.map((name) => Tab(text: name)).toList(),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: categories.values.map((emojiList) {
                        return GridView.builder(
                          padding: const EdgeInsets.only(top: 8),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: emojiList.length,
                          itemBuilder: (context, idx) {
                            final emoji = emojiList[idx];
                            return InkWell(
                              onTap: () => Navigator.pop(ctx, emoji),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade50,
                                  border: Border.all(color: Colors.grey.shade100),
                                ),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddRetrospectiveDialog(Color themeColor, Color themeColorLight) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final tagsController = TextEditingController();
    String selectedEmoji = '😊';
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final result = await showDialog<RetrospectiveItem?>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 8,
              backgroundColor: Colors.white,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(32),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 다이얼로그 헤더
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '새 회고 작성',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$dateStr · 오늘의 성장 기록',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.grey.shade400),
                            onPressed: () => Navigator.pop(ctx, null),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 이모지 선택 섹션
                      const Text(
                        '오늘 하루를 나타내는 이모지',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Text(
                              selectedEmoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '오늘의 분위기',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final chosenEmoji = await _showEmojiPickerDialog(context, themeColor);
                                if (chosenEmoji != null) {
                                  setDialogState(() {
                                    selectedEmoji = chosenEmoji;
                                  });
                                }
                              },
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                              label: const Text('변경'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColorLight,
                                foregroundColor: themeColor,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 제목 입력 필드
                      const Text(
                        '제목',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: '회고 제목을 입력하세요',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 내용 입력 필드
                      const Text(
                        '회고 내용',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: contentController,
                        maxLines: 5,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                        decoration: InputDecoration(
                          hintText: '오늘 달성한 점, 아쉬운 점, 그리고 내일 개선할 점(KPT)을 자유롭게 기록해 보세요.',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 태그 입력 필드
                      const Text(
                        '태그 (쉼표로 구분)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: tagsController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '예: 수업, 과제, 스터디, 과목명',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          prefixIcon: Icon(Icons.local_offer_outlined, size: 18, color: Colors.grey.shade400),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: themeColor, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 버튼 액션
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, null),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            child: Text(
                              '취소',
                              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              elevation: 0,
                            ),
                            child: const Text(
                              '회고 저장',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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

  // 회고 상세 보기 다이얼로그
  void _showRetrospectiveDetailDialog(RetrospectiveItem retro, Color tagBg, Color tagText) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          backgroundColor: Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 헤더: 닫기 아이콘
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey.shade400),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 이모지와 제목 영역 (제목 아래 날짜 표시)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Text(
                        retro.emoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            retro.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            retro.date,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(height: 1),
                const SizedBox(height: 24),

                // 본문 내용 영역
                const Text(
                  '오늘의 기록',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 240),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      retro.content,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 태그 영역
                if (retro.tags.isNotEmpty) ...[
                  const Text(
                    '태그',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: retro.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: tagText,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // 하단 닫기 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRetrospectiveDetailDialog(retrospective, tagBg, tagText),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Emoji & Date
                SizedBox(
                  width: 130,
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
                          maxLines: 1,
                          softWrap: false,
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
                  icon: const Icon(Icons.delete_outline, size: 18),
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.redAccent;
                      }
                      return Colors.grey.shade400;
                    }),
                    overlayColor: WidgetStateProperty.all(Colors.red.withValues(alpha: 0.05)),
                  ),
                  onPressed: () => _confirmDeleteRetrospective(retrospective),
                  tooltip: '회고 삭제',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
