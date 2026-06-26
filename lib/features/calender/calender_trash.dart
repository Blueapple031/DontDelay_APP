part of 'calender.dart';

extension _CalendarTrash on _CalendarScreenState {
  void _showTrashOverlay() {
    if (_trashEntry != null) return;
    _trashEntry = OverlayEntry(builder: (_) {
      return Positioned(
        bottom: 24,
        left: 0,
        right: 0,
        child: Center(
          child: DragTarget<Object>(
            builder: (ctx, candidates, _) {
              final isHover = candidates.isNotEmpty;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: isHover ? 72 : 56,
                height: isHover ? 72 : 56,
                decoration: BoxDecoration(
                  color: isHover
                      ? Colors.red.shade600
                      : const Color(0xFF1F2937),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black38,
                        blurRadius: 8,
                        spreadRadius: 1),
                  ],
                ),
                child: Icon(Icons.delete_outline,
                    color: Colors.white, size: isHover ? 34 : 26),
              );
            },
            onAcceptWithDetails: (details) {
              final data = details.data;
              if (data is _TodoDragData) {
                _handleTrashDrop(
                    data.todo, DateTime.tryParse(data.instanceDate));
              } else if (data is _EventDragData) {
                _handleTrashDropEvent(
                    data.event, DateTime.tryParse(data.instanceDate));
              }
            },
          ),
        ),
      );
    });
    Overlay.of(context).insert(_trashEntry!);
  }

  void _hideTrashOverlay() {
    _trashEntry?.remove();
    _trashEntry = null;
  }

  Future<void> _handleTrashDrop(
      TodoItem todo, DateTime? instanceDate) async {
    if (todo.repeat != RepeatType.none && instanceDate != null) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: const Text('반복 일정 삭제'),
          actions: [
            Row(children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'single'),
                child: const Text('이 일정만'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'future'),
                child: const Text('이후 모두',
                    style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
            ]),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      final dateKey = _fmtKey(instanceDate);
      if (choice == 'single') {
        await ref
            .read(todoListProvider.notifier)
            .addDeletedOverride(todo.id, dateKey);
      } else {
        await ref
            .read(todoListProvider.notifier)
            .setRepeatEndDate(todo.id, dateKey);
      }
    } else {
      await ref.read(todoListProvider.notifier).deleteTodo(todo.id);
    }
  }

  Future<void> _handleTrashDropEvent(
      EventItem event, DateTime? instanceDate) async {
    if (event.repeat != RepeatType.none && instanceDate != null) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          title: const Text('반복 일정 삭제'),
          actions: [
            Row(children: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'single'),
                child: const Text('이 일정만'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'future'),
                child: const Text('이후 모두',
                    style: TextStyle(color: Colors.red)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소'),
              ),
            ]),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      final dateKey = _fmtKey(instanceDate);
      if (choice == 'single') {
        await ref
            .read(eventListProvider.notifier)
            .addDeletedOverride(event.id, dateKey);
      } else {
        await ref
            .read(eventListProvider.notifier)
            .setRepeatEndDate(event.id, dateKey);
      }
    } else {
      await ref.read(eventListProvider.notifier).deleteEvent(event.id);
    }
  }
}
