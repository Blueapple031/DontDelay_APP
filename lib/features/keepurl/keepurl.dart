import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'url_connection_service.dart';
import 'url_model.dart';
import 'url_opener.dart';
import 'url_provider.dart';

class UrlApiServerState {
  final bool isRunning;
  final String? startError;
  final UrlConnectionConfig? config;

  const UrlApiServerState({
    required this.isRunning,
    this.startError,
    this.config,
  });
}

final urlConnectionServiceProvider =
    Provider((ref) => UrlConnectionService());

final urlConnectionProvider = FutureProvider<UrlConnectionConfig>((ref) async {
  return ref.read(urlConnectionServiceProvider).loadOrCreate();
});

final urlApiServerStateProvider =
    NotifierProvider<UrlApiServerStateNotifier, UrlApiServerState>(
  UrlApiServerStateNotifier.new,
);

class UrlApiServerStateNotifier extends Notifier<UrlApiServerState> {
  @override
  UrlApiServerState build() => const UrlApiServerState(isRunning: false);

  void updateServerState(UrlApiServerState value) {
    state = value;
  }
}

class UrlScreen extends ConsumerStatefulWidget {
  const UrlScreen({super.key});

  @override
  ConsumerState<UrlScreen> createState() => _UrlScreenState();
}

class _UrlScreenState extends ConsumerState<UrlScreen> {
  int _selectedCategoryIndex = 0;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _watchLaterOnly = false;
  bool _showBrowserPanel = false;
  bool _testingConnection = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UrlItem> _filterUrls(List<UrlItem> urls) {
    var result = urls;

    if (_selectedCategoryIndex > 0) {
      final category = kUrlFilterCategories[_selectedCategoryIndex];
      result = result.where((u) => u.category == category).toList();
    }

    if (_watchLaterOnly) {
      result = result.where((u) => u.watchLater).toList();
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((u) {
        if (u.title.toLowerCase().contains(q)) return true;
        if (u.url.toLowerCase().contains(q)) return true;
        return u.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    result.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final asyncUrls = ref.watch(urlListProvider);
    final serverState = ref.watch(urlApiServerStateProvider);
    final asyncConnection = ref.watch(urlConnectionProvider);

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
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _showBrowserPanel = !_showBrowserPanel);
                    },
                    icon: Icon(
                      _showBrowserPanel
                          ? Icons.expand_less
                          : Icons.extension_outlined,
                      size: 18,
                    ),
                    label: Text(
                      serverState.isRunning ? '브라우저 연동 ●' : '브라우저 연동 ○',
                      style: TextStyle(
                        color: serverState.isRunning
                            ? const Color(0xFF059669)
                            : Colors.black87,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: serverState.isRunning
                            ? const Color(0xFF059669)
                            : Colors.grey.shade300,
                      ),
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
                    onPressed: () => _showAddUrlDialog(context),
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
            ],
          ),
          if (_showBrowserPanel) ...[
            const SizedBox(height: 16),
            _buildBrowserPanel(serverState, asyncConnection),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: '제목, 태그, URL로 검색...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.grey.shade400),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFF6D28D9)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _watchLaterOnly = !_watchLaterOnly);
                },
                icon: Icon(
                  _watchLaterOnly ? Icons.bookmark : Icons.filter_list,
                  size: 18,
                  color: _watchLaterOnly
                      ? const Color(0xFFF97316)
                      : Colors.black87,
                ),
                label: Text(
                  _watchLaterOnly ? '나중에 보기' : '필터',
                  style: TextStyle(
                    color: _watchLaterOnly
                        ? const Color(0xFFF97316)
                        : Colors.black87,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor:
                      _watchLaterOnly ? const Color(0xFFFFF7ED) : Colors.white,
                  side: BorderSide(
                    color: _watchLaterOnly
                        ? const Color(0xFFF97316)
                        : Colors.grey.shade300,
                  ),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(kUrlFilterCategories.length, (index) {
                final isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(kUrlFilterCategories[index]),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategoryIndex = index);
                    },
                    selectedColor: const Color(0xFF6D28D9),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('AI 자동 분류는 준비 중입니다.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6D28D9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '준비 중',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: asyncUrls.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류가 발생했습니다: $e')),
              data: (urls) {
                final filtered = _filterUrls(urls);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          urls.isEmpty
                              ? '저장된 URL이 없습니다.\nURL 추가 또는 브라우저 확장으로 저장해 보세요.'
                              : '검색 조건에 맞는 URL이 없습니다.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    childAspectRatio: 2.2,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildUrlCard(context, filtered[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrowserPanel(
    UrlApiServerState serverState,
    AsyncValue<UrlConnectionConfig> asyncConnection,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: asyncConnection.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('연결 정보를 불러올 수 없습니다: $e'),
        data: (connection) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    serverState.isRunning ? Icons.check_circle : Icons.error,
                    color: serverState.isRunning
                        ? const Color(0xFF059669)
                        : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    serverState.isRunning
                        ? '로컬 API 서버 실행 중 (127.0.0.1:${connection.port})'
                        : '로컬 API 서버가 실행되지 않았습니다',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (serverState.startError != null) ...[
                const SizedBox(height: 8),
                Text(
                  serverState.startError!,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                '1. Chrome/Edge에서 extension/ 폴더를 개발자 모드로 로드합니다.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                '2. 확장 popup에 아래 포트와 토큰을 입력합니다.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildCopyRow('포트', '${connection.port}'),
              const SizedBox(height: 8),
              _buildCopyRow('토큰', connection.token),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _testingConnection
                        ? null
                        : () => _testConnection(connection.port),
                    icon: _testingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_tethering, size: 18),
                    label: const Text('연결 테스트'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              '포트: ${connection.port}\n토큰: ${connection.token}',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('연결 정보가 복사되었습니다.')),
                      );
                    },
                    child: const Text('전체 복사'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCopyRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        IconButton(
          tooltip: '$label 복사',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label이(가) 복사되었습니다.')),
            );
          },
          icon: const Icon(Icons.copy, size: 18),
        ),
      ],
    );
  }

  Future<void> _testConnection(int port) async {
    setState(() => _testingConnection = true);
    try {
      final client = HttpClient();
      final request =
          await client.getUrl(Uri.parse('http://127.0.0.1:$port/api/health'));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (!mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연결 성공: $body')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연결 실패 (${response.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('연결 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _testingConnection = false);
    }
  }

  Future<void> _showAddUrlDialog(BuildContext context) async {
    final urlController = TextEditingController();
    final titleController = TextEditingController();
    final tagsController = TextEditingController();
    var category = kUrlSaveCategories.first;
    var watchLater = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('URL 추가'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL *',
                        hintText: 'https://...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '제목',
                        hintText: '비우면 URL을 사용합니다',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: '카테고리'),
                      items: kUrlSaveCategories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => category = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: '태그',
                        hintText: '쉼표로 구분 (예: React, Frontend)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('나중에 보기'),
                      value: watchLater,
                      onChanged: (v) {
                        setDialogState(() => watchLater = v ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final url = urlController.text.trim();
    if (!UrlItem.isValidHttpUrl(url)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('올바른 http/https URL을 입력해 주세요.')),
        );
      }
      return;
    }

    final tags = tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final title = titleController.text.trim();
    final item = UrlItem(
      url: url,
      title: title.isEmpty ? url : title,
      category: category,
      tags: tags,
      watchLater: watchLater,
      source: 'manual',
    );

    try {
      await ref.read(urlListProvider.notifier).addUrl(item);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL이 저장되었습니다.')),
        );
      }
    } on UrlDuplicateException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 저장된 URL입니다.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  Widget _buildUrlCard(BuildContext context, UrlItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openUrl(item),
        onSecondaryTapDown: (details) {
          _showCardMenu(context, details.globalPosition, item);
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: const Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.watchLater)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
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
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.grey[500]),
                      onSelected: (value) => _handleCardAction(value, item),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'open',
                          child: Text('브라우저에서 열기'),
                        ),
                        const PopupMenuItem(
                          value: 'copy',
                          child: Text('URL 복사'),
                        ),
                        PopupMenuItem(
                          value: 'watch',
                          child: Text(
                            item.watchLater
                                ? '나중에 보기 해제'
                                : '나중에 보기',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('삭제'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildBadge(
                  item.category,
                  const Color(0xFFEEF2FF),
                  const Color(0xFF6366F1),
                ),
                if (item.source == 'extension') ...[
                  const SizedBox(width: 6),
                  _buildBadge(
                    '확장',
                    Colors.green.shade50,
                    Colors.green.shade700,
                  ),
                ],
              ],
            ),
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.tags
                    .map(
                      (tag) => _buildBadge(
                        tag,
                        Colors.grey.shade100,
                        Colors.grey.shade600,
                      ),
                    )
                    .toList(),
              ),
            ],
            const Spacer(),
            Text(
              '저장일: ${item.savedDateLabel}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _openUrl(UrlItem item) async {
    try {
      await openUrlInBrowser(item.url);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('페이지를 열 수 없습니다: $e')),
      );
    }
  }

  void _showCardMenu(
    BuildContext context,
    Offset position,
    UrlItem item,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        const PopupMenuItem(value: 'open', child: Text('브라우저에서 열기')),
        const PopupMenuItem(value: 'copy', child: Text('URL 복사')),
        PopupMenuItem(
          value: 'watch',
          child: Text(item.watchLater ? '나중에 보기 해제' : '나중에 보기'),
        ),
        const PopupMenuItem(value: 'delete', child: Text('삭제')),
      ],
    ).then((value) {
      if (value != null) _handleCardAction(value, item);
    });
  }

  Future<void> _handleCardAction(String action, UrlItem item) async {
    switch (action) {
      case 'open':
        await _openUrl(item);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: item.url));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL이 복사되었습니다.')),
        );
      case 'watch':
        await ref.read(urlListProvider.notifier).toggleWatchLater(item.id);
      case 'delete':
        await ref.read(urlListProvider.notifier).deleteUrl(item.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL이 삭제되었습니다.')),
        );
    }
  }

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
