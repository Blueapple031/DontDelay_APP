part of 'calender.dart';

extension _CalendarOverflow on _CalendarScreenState {
  void _scheduleOverflowPopup(
    BuildContext cellCtx,
    DateTime date,
    List<TodoItem> todos,
    List<EventItem> events,
    Map<String, TagItem> tagMap,
  ) {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) _showOverflowPopup(cellCtx, date, todos, events, tagMap);
    });
  }

  void _cancelHoverTimer() {
    _hoverTimer?.cancel();
    _hoverTimer = null;
  }

  void _showOverflowPopup(
    BuildContext cellCtx,
    DateTime date,
    List<TodoItem> todos,
    List<EventItem> events,
    Map<String, TagItem> tagMap,
  ) {
    _closeOverflowPopup();
    final box = cellCtx.findRenderObject() as RenderBox?;
    if (box == null) return;

    // 이벤트 태그 맵 로컬 조회 (OverlayEntry는 별도 빌드 컨텍스트이므로 ref.read 사용)
    final eventTagMap = {
      for (final t in (ref.read(eventTagListProvider).value ??
          [TagItem.defaultTag]))
        t.id: t
    };

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final pos = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final cellW = box.size.width;
    final cellH = box.size.height;

    final overlaySize = overlayBox?.size ?? MediaQuery.of(context).size;
    const maxExpandH = 320.0;

    final top = (pos.dy + maxExpandH > overlaySize.height - 8)
        ? (pos.dy + cellH - maxExpandH)
            .clamp(8.0, overlaySize.height - maxExpandH - 8)
        : pos.dy;
    final left = pos.dx.clamp(0.0, overlaySize.width - cellW - 4);

    _overflowEntry = OverlayEntry(builder: (_) {
      return Positioned(
        left: left,
        top: top,
        width: cellW,
        child: MouseRegion(
          onExit: (_) => _closeOverflowPopup(),
          child: _buildExpandedCell(
              date, todos, events, tagMap, eventTagMap, cellH),
        ),
      );
    });
    Overlay.of(context).insert(_overflowEntry!);
  }

  void _closeOverflowPopup() {
    _overflowEntry?.remove();
    _overflowEntry = null;
  }

  /// 해당 날짜 칸을 세로로 확장한 뷰.
  /// _buildMonthBlock / _buildEventBlock 재사용 → 드래그&드롭 자동 포함.
  Widget _buildExpandedCell(
    DateTime date,
    List<TodoItem> todos,
    List<EventItem> events,
    Map<String, TagItem> tagMap,
    Map<String, TagItem> eventTagMap,
    double minH,
  ) {
    final cs = Theme.of(context).colorScheme;
    final dateKey = _fmtKey(date);
    final isToday = _sameDay(date, _today);

    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(8),
      color: cs.surfaceContainerLowest,
      child: Container(
        constraints: BoxConstraints(minHeight: minH, maxHeight: 320),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isToday
                ? const Color(0xFF1F2937).withValues(alpha: 0.4)
                : cs.outlineVariant,
            width: isToday ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 3, 5, 1),
              child: isToday
                  ? Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1F2937),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text('${date.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          )),
                    )
                  : Text('${date.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      )),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 4),
                children: [
                  ...events.map((e) => _buildEventBlock(e, cs, eventTagMap, date)),
                  ...todos.map((t) => _buildMonthBlock(
                        t, tagMap, date,
                        isDone: t.isDoneOnDate(dateKey),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
