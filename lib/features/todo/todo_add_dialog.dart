import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import 'tag_model.dart';
import 'tag_provider.dart';
import 'todo_model.dart';
import 'todo_provider.dart';

// ─── Public API ──────────────────────────────────────────────────────────────

void showTodoAddDialog(
  BuildContext context,
  WidgetRef ref, {
  TodoStatus initialStatus = TodoStatus.todo,
  DateTime? initialDate,
}) {
  showDialog<void>(
    context: context,
    builder: (_) =>
        _TodoDialog(initialStatus: initialStatus, initialDate: initialDate),
  );
}

void showTodoEditDialog(BuildContext context, WidgetRef ref, TodoItem item) {
  showDialog<void>(
    context: context,
    builder: (_) => _TodoDialog(editItem: item),
  );
}

// ─── Main dialog ─────────────────────────────────────────────────────────────

class _TodoDialog extends ConsumerStatefulWidget {
  final TodoItem? editItem;
  final TodoStatus initialStatus;
  final DateTime? initialDate;

  const _TodoDialog({
    this.editItem,
    this.initialStatus = TodoStatus.todo,
    this.initialDate,
  });

  @override
  ConsumerState<_TodoDialog> createState() => _TodoDialogState();
}

class _TodoDialogState extends ConsumerState<_TodoDialog> {
  late final TextEditingController _titleCtl;
  late DateTime _date;
  late String _selectedTagId;

  bool get _isEdit => widget.editItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    _titleCtl = TextEditingController(text: item?.title ?? '');
    _date = item != null
        ? (DateTime.tryParse(item.date) ?? widget.initialDate ?? DateTime.now())
        : (widget.initialDate ?? DateTime.now());
    _selectedTagId = item?.tag ?? TagItem.defaultId;
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref
        .watch(themeProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => AppThemeType.classicGray,
        );
    final tags =
        ref.watch(tagListProvider).value ?? [TagItem.defaultTagFor(theme)];
    if (!tags.any((t) => t.id == _selectedTagId)) {
      _selectedTagId = TagItem.defaultId;
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        _isEdit ? '할 일 수정' : '새 할 일 추가',
        style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 20),
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleCtl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '할 일 제목',
                hintText: '예: 운영체제 3단원 복습',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Date picker
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Tag selector header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '태그',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: _openTagEditDialog,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('태그 편집', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Tag chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((t) {
                final isSelected = _selectedTagId == t.id;
                final color = hexToColor(t.colorHex);
                return ChoiceChip(
                  label: Text(t.name),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedTagId = t.id),
                  selectedColor: color.withValues(alpha: 0.25),
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? color : Colors.grey.shade600,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected ? color : Colors.grey.shade300,
                    ),
                  ),
                  showCheckmark: false,
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              if (_isEdit)
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('삭제'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '취소',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  _isEdit ? '저장' : '추가',
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openTagEditDialog() {
    showDialog<void>(context: context, builder: (_) => const _TagEditDialog());
  }

  Future<void> _save() async {
    final title = _titleCtl.text.trim();
    if (title.isEmpty) return;
    final dateStr =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    try {
      if (_isEdit) {
        final updated = widget.editItem!.copyWith(
          title: title,
          date: dateStr,
          tag: _selectedTagId,
        );
        await ref.read(todoListProvider.notifier).updateTodo(updated);
      } else {
        final newTodo = TodoItem(
          title: title,
          date: dateStr,
          priority: TodoPriority.medium,
          tag: _selectedTagId,
          status: widget.initialStatus,
        );
        await ref.read(todoListProvider.notifier).addTodo(newTodo);
      }
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
    }
  }

  Future<void> _delete() async {
    final item = widget.editItem;
    if (item == null) return;
    try {
      await ref.read(todoListProvider.notifier).deleteTodo(item.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('할 일이 삭제되었습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('삭제에 실패했습니다: $e')));
    }
  }
}

// ─── Tag edit dialog ─────────────────────────────────────────────────────────

class _TagEditDialog extends ConsumerStatefulWidget {
  const _TagEditDialog();

  @override
  ConsumerState<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends ConsumerState<_TagEditDialog> {
  String? _editingId;
  final Map<String, TextEditingController> _nameCtls = {};
  final Map<String, String> _editingColors = {};
  bool _addingNew = false;
  final _newNameCtl = TextEditingController();
  String _newColor = TagItem.defaultColorFor(AppThemeType.classicGray);

  @override
  void dispose() {
    for (final c in _nameCtls.values) {
      c.dispose();
    }
    _newNameCtl.dispose();
    super.dispose();
  }

  void _startEdit(TagItem tag) {
    _nameCtls.putIfAbsent(tag.id, () => TextEditingController());
    _nameCtls[tag.id]!.text = tag.name;
    _editingColors[tag.id] = tag.colorHex;
    setState(() {
      _editingId = tag.id;
      _addingNew = false;
    });
  }

  Future<void> _saveEdit(TagItem tag) async {
    final name = _nameCtls[tag.id]?.text.trim() ?? tag.name;
    if (name.isEmpty) return;
    final color = _editingColors[tag.id] ?? tag.colorHex;
    try {
      await ref
          .read(tagListProvider.notifier)
          .updateTag(tag.copyWith(name: name, colorHex: color));
      setState(() => _editingId = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
    }
  }

  Future<void> _deleteTag(TagItem tag) async {
    if (tag.id == TagItem.defaultId) return;
    try {
      await ref
          .read(todoListProvider.notifier)
          .replaceTagId(tag.id, TagItem.defaultId);
      await ref.read(tagListProvider.notifier).deleteTag(tag.id);
      if (_editingId == tag.id) setState(() => _editingId = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
    }
  }

  Future<void> _addNew() async {
    final name = _newNameCtl.text.trim();
    if (name.isEmpty) return;
    final theme = ref.read(themeProvider).value ?? AppThemeType.classicGray;
    final palette = TagItem.paletteFor(theme);
    final color = palette.contains(_newColor)
        ? _newColor
        : TagItem.defaultColorFor(theme);
    try {
      await ref
          .read(tagListProvider.notifier)
          .addTag(TagItem(name: name, colorHex: color));
      _newNameCtl.clear();
      setState(() {
        _addingNew = false;
        _newColor = TagItem.defaultColorFor(theme);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장에 실패했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref
        .watch(themeProvider)
        .maybeWhen(
          data: (value) => value,
          orElse: () => AppThemeType.classicGray,
        );
    final tags =
        ref.watch(tagListProvider).value ?? [TagItem.defaultTagFor(theme)];

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        '태그 편집',
        style: Theme.of(context).textTheme.titleLarge!.copyWith(fontSize: 18),
      ),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...tags.map((tag) => _buildTagRow(tag)),
              const SizedBox(height: 4),
              if (_addingNew) _buildNewTagRow(),
              TextButton.icon(
                onPressed: () => setState(() {
                  _addingNew = true;
                  _editingId = null;
                  _newColor = TagItem.defaultColorFor(theme);
                }),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ 태그 추가'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('닫기', style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }

  Widget _buildTagRow(TagItem tag) {
    final isEditing = _editingId == tag.id;
    final color = hexToColor(tag.colorHex);
    final isDefault = tag.id == TagItem.defaultId;

    return Column(
      children: [
        if (!isEditing)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            title: Text(tag.name, style: const TextStyle(fontSize: 14)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 17),
                  onPressed: () => _startEdit(tag),
                  color: Colors.grey.shade500,
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (!isDefault) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 17),
                    onPressed: () => _deleteTag(tag),
                    color: Colors.red.shade400,
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          )
        else
          _buildEditRow(tag),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildEditRow(TagItem tag) {
    final editColor = _editingColors[tag.id] ?? tag.colorHex;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameCtls[tag.id],
            autofocus: true,
            decoration: InputDecoration(
              labelText: '태그 이름',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildColorPalette(
            selected: editColor,
            onSelect: (h) => setState(() => _editingColors[tag.id] = h),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _editingId = null),
                child: Text(
                  '취소',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _saveEdit(tag),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('저장', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewTagRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _newNameCtl,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '새 태그 이름',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildColorPalette(
            selected: _newColor,
            onSelect: (h) => setState(() => _newColor = h),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _addingNew = false),
                child: Text(
                  '취소',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addNew,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text('추가', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorPalette({
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          TagItem.paletteFor(
            ref
                .watch(themeProvider)
                .maybeWhen(
                  data: (value) => value,
                  orElse: () => AppThemeType.classicGray,
                ),
          ).map((hex) {
            final color = hexToColor(hex);
            final isSel = hex == selected;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onSelect(hex),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSel
                        ? Border.all(color: Colors.black87, width: 2.5)
                        : Border.all(color: Colors.transparent),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}
