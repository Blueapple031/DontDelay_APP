import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'url_folder_model.dart';
import 'url_folder_provider.dart';
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
  String? _selectedFolderId;
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

    if (_selectedFolderId != null) {
      result =
          result.where((u) => u.folderId == _selectedFolderId).toList();
    }

    if (_watchLaterOnly) {
      result = result.where((u) => u.watchLater).toList();
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((u) {
        if (u.title.toLowerCase().contains(q)) return true;
        return u.url.toLowerCase().contains(q);
      }).toList();
    }

    result.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return result;
  }

  String _folderName(List<UrlFolder> folders, String folderId) {
    for (final f in folders) {
      if (f.id == folderId) return f.name;
    }
    return UrlFolder.defaultFolderName;
  }

  @override
  Widget build(BuildContext context) {
    final asyncUrls = ref.watch(urlListProvider);
    final asyncFolders = ref.watch(urlFolderListProvider);
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
                  OutlinedButton.icon(
                    onPressed: () => _showAddFolderDialog(context),
                    icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                    label: const Text('폴더 추가'),
                    style: OutlinedButton.styleFrom(
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
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
                    hintText: '제목, URL로 검색...',
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
                          BorderSide(color: Theme.of(context).colorScheme.primary),
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
          asyncFolders.when(
            loading: () => const SizedBox(
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('폴더를 불러올 수 없습니다: $e'),
            data: (folders) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFolderBar(folders),
                const SizedBox(height: 6),
                Text(
                  'URL 카드를 길게 눌러 폴더 칩 위에 놓으면 이동합니다',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
                final folders = asyncFolders.value ?? [];
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
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.65,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildUrlCard(context, filtered[index], folders);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderBar(List<UrlFolder> folders) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFolderChip(null, '전체'),
                ...folders.map((f) => _buildFolderChip(f.id, f.name)),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: '폴더 관리',
          onPressed: () => _showManageFoldersDialog(context, folders),
          icon: const Icon(Icons.folder_open_outlined),
        ),
      ],
    );
  }

  Widget _buildFolderChip(String? folderId, String label) {
    final isSelected = _selectedFolderId == folderId;
    final chip = ChoiceChip(
      avatar: folderId != null
          ? const Icon(Icons.folder_outlined, size: 16)
          : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFolderId = folderId),
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
        ),
      ),
      showCheckmark: false,
    );

    if (folderId == null) {
      return Padding(padding: const EdgeInsets.only(right: 8), child: chip);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) => details.data.isNotEmpty,
        onAcceptWithDetails: (details) async {
          await ref
              .read(urlListProvider.notifier)
              .moveToFolder(details.data, folderId);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"$label" 폴더로 이동했습니다.')),
          );
        },
        builder: (context, candidate, rejected) {
          final isHover = candidate.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: isHover ? const EdgeInsets.all(2) : EdgeInsets.zero,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: isHover
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
              color: isHover ? Theme.of(context).colorScheme.primaryContainer : null,
            ),
            child: chip,
          );
        },
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
    final folders = ref.read(urlFolderListProvider).value ?? [];
    final urlController = TextEditingController();
    final titleController = TextEditingController();
    final memoController = TextEditingController();
    var selectedFolderId = ''; // 빈 값 = 도메인 자동 분류
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
                      initialValue: selectedFolderId,
                      decoration: const InputDecoration(
                        labelText: '폴더',
                        helperText: '자동 선택 시 URL 도메인으로 폴더가 정해집니다',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('자동 (도메인 분류)'),
                        ),
                        ...folders.map(
                          (f) => DropdownMenuItem(
                            value: f.id,
                            child: Text(f.name),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setDialogState(() => selectedFolderId = v ?? '');
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: memoController,
                      decoration: const InputDecoration(
                        labelText: '메모 (선택)',
                        hintText: '나중에 볼 때 참고할 내용',
                      ),
                      maxLines: 2,
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
    if (!UrlItem.isValidSavableUrl(url)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장할 수 있는 URL 형식이 아닙니다.')),
        );
      }
      return;
    }

    final title = titleController.text.trim();

    try {
      await ref.read(urlListProvider.notifier).addUrl(
            url: url,
            title: title.isEmpty ? url : title,
            folderId: selectedFolderId.isEmpty ? null : selectedFolderId,
            memo: memoController.text,
            watchLater: watchLater,
          );
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

  Future<void> _showAddFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('폴더 추가'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '폴더 이름',
            hintText: '예: 시험 공부',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('추가')),
        ],
      ),
    );
    if (saved != true) return;
    try {
      await ref.read(urlFolderListProvider.notifier).addFolder(controller.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('폴더가 추가되었습니다.')),
        );
      }
    } on UrlFolderDuplicateNameException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 같은 이름의 폴더가 있습니다.')),
        );
      }
    }
  }

  Future<void> _showManageFoldersDialog(
    BuildContext context,
    List<UrlFolder> folders,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('폴더 관리'),
        content: SizedBox(
          width: 400,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: folders.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final folder = folders[i];
              final isDefault = folder.name == UrlFolder.defaultFolderName;
              return ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(folder.name),
                trailing: isDefault
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _showRenameFolderDialog(context, folder);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _deleteFolder(context, folder);
                            },
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
        ],
      ),
    );
  }

  Future<void> _showRenameFolderDialog(
    BuildContext context,
    UrlFolder folder,
  ) async {
    final controller = TextEditingController(text: folder.name);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('폴더 이름 변경'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('저장')),
        ],
      ),
    );
    if (saved != true) return;
    try {
      await ref
          .read(urlFolderListProvider.notifier)
          .renameFolder(folder.id, controller.text);
    } on UrlFolderDuplicateNameException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 같은 이름의 폴더가 있습니다.')),
        );
      }
    }
  }

  Future<void> _deleteFolder(BuildContext context, UrlFolder folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: Text(
          '"${folder.name}" 폴더를 삭제할까요?\n포함된 URL은 "${UrlFolder.defaultFolderName}" 폴더로 이동합니다.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('삭제')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref
        .read(urlListProvider.notifier)
        .reassignUrlsFromDeletedFolder(folder.id);
    if (_selectedFolderId == folder.id) {
      setState(() => _selectedFolderId = null);
    }
    try {
      await ref.read(urlFolderListProvider.notifier).deleteFolder(folder.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('폴더가 삭제되었습니다.')),
        );
      }
    } on UrlFolderProtectedException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기본 폴더는 삭제할 수 없습니다.')),
        );
      }
    }
  }

  Future<void> _showMoveFolderDialog(
    BuildContext context,
    UrlItem item,
    List<UrlFolder> folders,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('폴더 이동'),
        children: folders
            .map(
              (f) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, f.id),
                child: Row(
                  children: [
                    const Icon(Icons.folder_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(f.name),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
    if (selected == null || selected == item.folderId) return;
    await ref.read(urlListProvider.notifier).moveToFolder(item.id, selected);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('폴더가 변경되었습니다.')),
      );
    }
  }

  Future<void> _showMemoDialog(UrlItem item) async {
    final controller = TextEditingController(text: item.memo);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메모'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: '메모를 입력하세요 (비우면 삭제)',
          ),
          autofocus: true,
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
      ),
    );
    if (saved != true) return;
    await ref.read(urlListProvider.notifier).updateMemo(item.id, controller.text);
  }

  Widget _buildUrlCard(
    BuildContext context,
    UrlItem item,
    List<UrlFolder> folders,
  ) {
    final card = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openUrl(item),
        onSecondaryTapDown: (details) {
          _showCardMenu(context, details.globalPosition, item, folders);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      item.icon,
                      color: const Color(0xFF6366F1),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (item.watchLater)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '나중에',
                        style: TextStyle(
                          color: Color(0xFFF97316),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[500]),
                    onSelected: (value) =>
                        _handleCardAction(value, item, folders),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'open',
                        child: Text('브라우저에서 열기'),
                      ),
                      const PopupMenuItem(
                        value: 'move',
                        child: Text('폴더 이동'),
                      ),
                      const PopupMenuItem(
                        value: 'memo',
                        child: Text('메모'),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: Text('URL 복사'),
                      ),
                      PopupMenuItem(
                        value: 'watch',
                        child: Text(
                          item.watchLater ? '나중에 보기 해제' : '나중에 보기',
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
              if (item.memo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.memo,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildBadge(
                    _folderName(folders, item.folderId),
                    const Color(0xFFEEF2FF),
                    const Color(0xFF6366F1),
                  ),
                  if (item.source == 'extension') ...[
                    const SizedBox(width: 4),
                    _buildBadge(
                      '확장',
                      Colors.green.shade50,
                      Colors.green.shade700,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    item.savedDateLabel,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return LongPressDraggable<String>(
      data: item.id,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).colorScheme.primary),
          ),
          child: Text(
            item.title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
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
    List<UrlFolder> folders,
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
        const PopupMenuItem(value: 'move', child: Text('폴더 이동')),
        const PopupMenuItem(value: 'move', child: Text('폴더 이동')),
        const PopupMenuItem(value: 'memo', child: Text('메모')),
        const PopupMenuItem(value: 'copy', child: Text('URL 복사')),
        PopupMenuItem(
          value: 'watch',
          child: Text(item.watchLater ? '나중에 보기 해제' : '나중에 보기'),
        ),
        const PopupMenuItem(value: 'delete', child: Text('삭제')),
      ],
    ).then((value) {
      if (value != null) _handleCardAction(value, item, folders);
    });
  }

  Future<void> _handleCardAction(
    String action,
    UrlItem item,
    List<UrlFolder> folders,
  ) async {
    switch (action) {
      case 'open':
        await _openUrl(item);
      case 'move':
        await _showMoveFolderDialog(context, item, folders);
      case 'memo':
        await _showMemoDialog(item);
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
