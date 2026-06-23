import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'todo_model.dart';
import 'todo_provider.dart';

/// 긴급도(가로)·중요도(세로) 각각 **1~8** (8칸 사분면: 1~4 / 5~8 두 구간으로 2×2).
class TodoEisenhowerBoard extends ConsumerStatefulWidget {
  const TodoEisenhowerBoard({super.key, required this.todos});

  final List<TodoItem> todos;

  static const int scoreMin = 1;
  static const int scoreMax = 8;
  static const int scoreBins =
      scoreMax - scoreMin + 1; // 8 — 가로·세로 8등분 후 4+4 분면 가능

  static List<TodoItem> visibleForMatrix(List<TodoItem> all) =>
      all.where((t) => t.status != TodoStatus.done).toList();

  static const double _cardW = 136;
  static const double _cardH = 68;
  static const double _axisLeft = 40;
  /// 드롭 판정: 플롯 밖으로 카드 절반이 나가도 가장자리(1·8) 인식되도록 여유.
  static const double _dropEdgeSlop = 56;

  /// 긴급 `scoreMin…scoreMax` 각 구간의 중심 X.
  static double urgencyCenterX(int u, double plotW) =>
      plotW *
      (math.min(math.max(u, scoreMin), scoreMax) - 0.5) /
      scoreBins;

  /// 중요도 `scoreMax` 위쪽 · `scoreMin` 아래쪽, 구간 중심 Y.
  static double importanceCenterY(int imp, double plotH) =>
      plotH *
      (1 -
          (math.min(math.max(imp, scoreMin), scoreMax) - 0.5) /
              scoreBins);

  static Color priorityColor(TodoPriority p) {
    switch (p) {
      case TodoPriority.high:
        return Colors.red;
      case TodoPriority.medium:
        return Colors.orange;
      case TodoPriority.low:
        return Colors.green;
    }
  }

  /// 같은 (긴급, 중요) 점수로 겹칠 때 카드 크기 비율 (더 촘촘하게)
  static double pileScale(int count) {
    if (count <= 1) return 1;
    return math.pow(count, -0.52).clamp(0.22, 1.0).toDouble();
  }

  @override
  ConsumerState<TodoEisenhowerBoard> createState() =>
      _TodoEisenhowerBoardState();
}

class _CardSlot {
  const _CardSlot({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.angle,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double angle;
}

class _TodoEisenhowerBoardState extends ConsumerState<TodoEisenhowerBoard>
    with SingleTickerProviderStateMixin {
  final GlobalKey _plotSurfaceKey = GlobalKey();

  /// 마우스로 끄는 중인 카드 (미리보기용)
  TodoItem? _activeDragItem;
  int? _previewUrgency;
  int? _previewImportance;
  int? _lastDropUrgency;
  int? _lastDropImportance;
  double _dragFeedbackW = 0;
  double _dragFeedbackH = 0;

  /// 중첩 카드 펼치기 애니메이션 — 펼치는 묶음 키: "${urgency}_${importance}"
  String? _hoveredPileKey;
  late AnimationController _pileRevealCtl;
  int _pileInteractionGeneration = 0;

  double _pileExpandT(String pileKey, int n) {
    if (n <= 1) return 0;
    if (_activeDragItem != null) return 0;
    if (_hoveredPileKey != pileKey) return 0;
    return _pileRevealCtl.value.clamp(0.0, 1.0);
  }

  void _pilePointerEnter(String key) {
    if (_activeDragItem != null) return;
    _pileInteractionGeneration++;
    setState(() => _hoveredPileKey = key);
    _pileRevealCtl.forward(from: _pileRevealCtl.value);
  }

  void _pilePointerExit() {
    final generation = ++_pileInteractionGeneration;
    _pileRevealCtl.reverse(from: _pileRevealCtl.value).whenComplete(() {
      if (!mounted || generation != _pileInteractionGeneration) return;
      if (_pileRevealCtl.isDismissed) {
        setState(() => _hoveredPileKey = null);
      }
    });
  }

  List<_CardSlot> _layoutPileCards({
    required String pileKey,
    required List<TodoItem> pile,
    required double cx,
    required double cy,
    required double plotW,
    required double plotH,
  }) {
    final n = pile.length;
    final baseScale = TodoEisenhowerBoard.pileScale(n);

    double swCollapsed = TodoEisenhowerBoard._cardW * baseScale * 0.82;
    double shCollapsed = TodoEisenhowerBoard._cardH * baseScale * 0.82;
    swCollapsed = swCollapsed.clamp(56.0, TodoEisenhowerBoard._cardW);
    shCollapsed = shCollapsed.clamp(40.0, TodoEisenhowerBoard._cardH);

    final staggerXCollapsed = math.min(4.5 + (n > 4 ? -0.5 : 0.0),
        math.max(2.8, swCollapsed * 0.042)).toDouble();
    final staggerYCollapsed =
        math.min(2.8, math.max(1.8, shCollapsed * 0.036)).toDouble();

    var staggerX = staggerXCollapsed;
    double spanCollapsed =
        n > 1 ? (n - 1) * staggerX + swCollapsed : swCollapsed;
    if (spanCollapsed > plotW - 12 && n > 1) {
      staggerX = math.max(
        2.2,
        (plotW - 12 - swCollapsed) / (n - 1),
      ).clamp(2.2, staggerXCollapsed).toDouble();
      spanCollapsed = (n - 1) * staggerX + swCollapsed;
    }
    var edgeColl = cx - spanCollapsed / 2;
    edgeColl = edgeColl.clamp(
      8.0,
      math.max(8.0, plotW - spanCollapsed - 8),
    );

    final availW = (plotW - 24).clamp(80.0, double.infinity);
    final targetWExpanded = math.min(
      TodoEisenhowerBoard._cardW * 0.9,
      n > 0 ? availW / (n + math.max(0, n - 1) * 0.42) : swCollapsed,
    );
    final targetHExpanded =
        TodoEisenhowerBoard._cardH * (targetWExpanded / TodoEisenhowerBoard._cardW);
    final overlap = math.min(22.0, targetWExpanded * 0.12);
    var spanExpanded = n <= 1
        ? targetWExpanded
        : targetWExpanded * n - overlap * (n - 1);
    spanExpanded = spanExpanded.clamp(targetWExpanded, availW.toDouble());

    double edgeExpanded = cx - spanExpanded / 2;
    edgeExpanded = edgeExpanded.clamp(
      8.0,
      math.max(8.0, plotW - spanExpanded - 8),
    );

    final t = Curves.easeOutCubic.transform(_pileExpandT(pileKey, n));

    final maxTurnExpanded = math.min(0.07, math.pi / 28 * math.min(n, 4));

    final out = <_CardSlot>[];
    for (var i = 0; i < n; i++) {
      final lw = lerpDouble(swCollapsed, targetWExpanded, t)!;
      final lh = lerpDouble(shCollapsed, targetHExpanded, t)!;

      late double lx;
      late double ly;
      if (n == 1) {
        lx = cx - lw / 2;
        ly = cy - lh / 2;
      } else {
        final u = i / (n - 1);
        final strideExpanded =
            math.max(targetWExpanded - overlap, targetWExpanded * 0.4);
        lx = lerpDouble(
              edgeColl + i * staggerX,
              edgeExpanded + i * strideExpanded,
              t,
            )!;
        ly = lerpDouble(
              cy - lh / 2 + i * staggerYCollapsed,
              cy -
                  lh / 2 +
                  math.sin(u * math.pi) * lh * _lerpSinLift(n),
              t,
            )!;
      }

      late double angle;
      if (n == 1) {
        angle = 0;
      } else {
        final frac = i / (n - 1) - 0.5;
        angle = frac * maxTurnExpanded * 2 * t;
      }

      lx = lx.clamp(8.0, math.max(8.0, plotW - lw - 8));
      ly = ly.clamp(8.0, math.max(8.0, plotH - lh - 8));

      out.add(_CardSlot(left: lx, top: ly, width: lw, height: lh, angle: angle));
    }
    return out;
  }

  static double _lerpSinLift(int n) {
    if (n <= 3) return 0.065;
    if (n <= 6) return 0.09;
    return (0.1 + math.min(n, 12) * 0.012).clamp(0.09, 0.18);
  }

  @override
  void initState() {
    super.initState();
    _pileRevealCtl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pileRevealCtl.dispose();
    super.dispose();
  }

  static int _scoreFromAxisNorm(double norm) {
    final n = norm.clamp(0.0, 1.0);
    if (n <= 0) return TodoEisenhowerBoard.scoreMin;
    if (n >= 1) return TodoEisenhowerBoard.scoreMax;
    return (n * TodoEisenhowerBoard.scoreBins)
        .ceil()
        .clamp(TodoEisenhowerBoard.scoreMin, TodoEisenhowerBoard.scoreMax);
  }

  static (int urgency, int importance) _scoresFromLocal(
    Offset local,
    Size plotSize,
  ) {
    final w = math.max(plotSize.width, 1e-6);
    final h = math.max(plotSize.height, 1e-6);
    final dx = local.dx.clamp(0.0, w);
    final dy = local.dy.clamp(0.0, h);
    final u = _scoreFromAxisNorm(dx / w);
    final imp = _scoreFromAxisNorm((h - dy) / h);
    return (u, imp);
  }

  (int, int)? _scoresFromDragFeedback(Offset globalFeedbackTopLeft) {
    final RenderBox? box =
        _plotSurfaceKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || _dragFeedbackW <= 0 || _dragFeedbackH <= 0) {
      return null;
    }
    final localTopLeft = box.globalToLocal(globalFeedbackTopLeft);
    final center = localTopLeft +
        Offset(_dragFeedbackW / 2, _dragFeedbackH / 2);
    return _scoresFromLocal(center, box.size);
  }

  void _updateDropPreviewFromDrag(Offset globalFeedbackTopLeft) {
    final scores = _scoresFromDragFeedback(globalFeedbackTopLeft);
    if (scores == null) return;
    final (u, imp) = scores;
    _lastDropUrgency = u;
    _lastDropImportance = imp;
    if (_previewUrgency != u || _previewImportance != imp) {
      setState(() {
        _previewUrgency = u;
        _previewImportance = imp;
      });
    }
  }

  Future<void> _persistDropScores(String todoId, int u, int imp) async {
    try {
      await ref.read(todoListProvider.notifier).updateUrgencyImportance(
            todoId,
            u,
            imp,
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장에 실패했습니다: $e')),
      );
    }
  }

  static Map<String, List<TodoItem>> _groupByScores(
    List<TodoItem> visible,
  ) {
    final map = <String, List<TodoItem>>{};
    for (final t in visible) {
      final k = '${t.urgency}_${t.importance}';
      map.putIfAbsent(k, () => <TodoItem>[]).add(t);
    }
    return map;
  }

  static int _previewPileCount(
    List<TodoItem> visible,
    int u,
    int imp,
    TodoItem dragging,
  ) {
    var n = 0;
    for (final t in visible) {
      if (t.id == dragging.id) continue;
      if (t.urgency == u && t.importance == imp) n++;
    }
    return n + 1;
  }

  Future<void> _onDrop(DragTargetDetails<TodoItem> details) async {
    final scores = _scoresFromDragFeedback(details.offset);
    if (scores == null) return;
    final (u, imp) = scores;
    await _persistDropScores(details.data.id, u, imp);
    _clearPreview();
  }

  void _clearPreview() {
    setState(() {
      _previewUrgency = null;
      _previewImportance = null;
    });
  }

  void _resetDragSession() {
    setState(() {
      _activeDragItem = null;
      _dragFeedbackW = 0;
      _dragFeedbackH = 0;
      _previewUrgency = null;
      _previewImportance = null;
      _lastDropUrgency = null;
      _lastDropImportance = null;
    });
  }

  Widget _matrixCardChrome(
    TodoItem item, {
    required double width,
    required double height,
    double textScale = 1,
    bool ultraCompact = false,
  }) {
    if (ultraCompact) {
      final pad = math.max(2.0,
              math.min(5.0, math.max(height, width) * 0.07))
          .toDouble();
      final innerH = math.max(0.0, height - 2 * pad);
      final metaFs = math.max(
        6.0,
        math.min(innerH * 0.32, (9 * textScale).clamp(6.0, 9.5)),
      );
      final titleFs = math
          .max(7.0, math.min((11 * textScale).clamp(7.5, 11), innerH * 0.42))
          .toDouble();

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      item.title,
                      maxLines: innerH >= 28 ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: titleFs,
                        height: 1.05,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: FittedBox(
                      alignment: Alignment.bottomLeft,
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: math.max(1.0, width - pad * 2 - 2),
                        child: Text(
                          '긴${item.urgency}·중${item.importance}·${item.priorityLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: metaFs,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade800,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pc = TodoEisenhowerBoard.priorityColor(item.priority);
    final fsTitle = (13 * textScale).clamp(9.5, 13).toDouble();
    final fsSmall = (10 * textScale).clamp(7.5, 10).toDouble();
    final pad = math.min(
      math.max(4.5, 9 * textScale),
      math.max(3.5, height * 0.12),
    ).toDouble();
    final innerH = math.max(0.0, height - 2 * pad);
    final titleMaxLines =
        innerH >= 62 ? 2 : innerH >= 42 ? (textScale >= 0.85 ? 2 : 1) : 1;
    final showFullChips = innerH >= 34;
    final chipAreaH =
        math.max(14.0, math.min(innerH * 0.48, fsSmall + 18));

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: math.max(4.0, 8 * textScale),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  item.title,
                  maxLines: titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: fsTitle,
                    height: 1.12,
                  ),
                ),
              ),
            ),
            if (showFullChips)
              SizedBox(
                height: chipAreaH,
                width: double.infinity,
                child: ClipRect(
                  child: FittedBox(
                    alignment: Alignment.bottomLeft,
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: width - pad * 2 - 4,
                      child: Wrap(
                        spacing: math.max(2.0, 3 * textScale),
                        runSpacing: 3,
                        children: [
                          _miniChip('긴:${item.urgency}', Colors.indigo.shade50,
                              Colors.indigo.shade800, fsSmall),
                          _miniChip('중:${item.importance}', Colors.teal.shade50,
                              Colors.teal.shade800, fsSmall),
                          _miniChip(
                            item.priorityLabel,
                            pc.withOpacity(0.12),
                            pc,
                            fsSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '긴${item.urgency}·중${item.importance}·${item.priorityLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: (fsSmall * 0.9).clamp(7.0, 9.5),
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropGhost({
    required double plotW,
    required double plotH,
    required int u,
    required int imp,
    required TodoItem dragging,
    required List<TodoItem> visible,
  }) {
    final n = _previewPileCount(visible, u, imp, dragging);
    final scale = TodoEisenhowerBoard.pileScale(n);
    final w = TodoEisenhowerBoard._cardW * scale;
    final h = TodoEisenhowerBoard._cardH * scale;
    final cx = TodoEisenhowerBoard.urgencyCenterX(u, plotW);
    final cy = TodoEisenhowerBoard.importanceCenterY(imp, plotH);
    var left = cx - w / 2;
    var top = cy - h / 2;
    left = left.clamp(0.0, math.max(0.0, plotW - w));
    top = top.clamp(0.0, math.max(0.0, plotH - h));

    final textScale = scale;
    final ghostPad =
        math.min(6.0, math.min(w, h) * 0.085).clamp(2.0, 8.0).toDouble();
    final iw = math.max(1.0, w - 2 * ghostPad);
    final ih = math.max(1.0, h - 2 * ghostPad);

    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1F2937).withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1F2937).withOpacity(0.85),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x48000000),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: FittedBox(
                    alignment: Alignment.center,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '여기 놓기\n급 $u · 중 $imp',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontSize: (13 * textScale).clamp(7.5, 14),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ),
              ),
              Opacity(
                opacity: 0.32,
                child: Padding(
                  padding: EdgeInsets.all(ghostPad),
                  child: _matrixCardChrome(
                    dragging,
                    width: iw,
                    height: ih,
                    textScale: textScale,
                    ultraCompact: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildScorePiles({
    required double plotW,
    required double plotH,
    required List<TodoItem> visible,
    required Widget Function(TodoItem item, double w, double h, double scale)
        wrapDraggable,
  }) {
    final out = <Widget>[];
    final groups = _groupByScores(visible).entries.toList()
      ..sort((a, b) {
        final dragging = _activeDragItem != null;
        int rank(String key) {
          final hovered = dragging ? false : (key == _hoveredPileKey);
          return hovered ? 1 : 0;
        }
        return rank(a.key).compareTo(rank(b.key));
      });

    for (final entry in groups) {
      final ids = entry.key.split('_');
      final u = int.parse(ids[0]);
      final imp = int.parse(ids[1]);
      final pile = entry.value;
      final n = pile.length;
      final cx = TodoEisenhowerBoard.urgencyCenterX(u, plotW);
      final cy = TodoEisenhowerBoard.importanceCenterY(imp, plotH);
      final expandT = _pileExpandT(entry.key, n);

      final slots = _layoutPileCards(
        pileKey: entry.key,
        pile: pile,
        cx: cx,
        cy: cy,
        plotW: plotW,
        plotH: plotH,
      );

      var minX = double.infinity;
      var minY = double.infinity;
      var maxX = double.negativeInfinity;
      var maxY = double.negativeInfinity;
      for (final s in slots) {
        final bump = s.width * s.angle.abs() * 0.55;
        minX = math.min(minX, s.left - bump);
        minY = math.min(minY, s.top - bump);
        maxX = math.max(maxX, s.left + s.width + bump);
        maxY = math.max(maxY, s.top + s.height + bump);
      }
      final pad = lerpDouble(10, 28, expandT)!;
      minX -= pad;
      minY -= pad;
      maxX += pad;
      maxY += pad;

      final pileChildren = <Widget>[];
      for (var idx = 0; idx < pile.length; idx++) {
        final item = pile[idx];
        final slot = slots[idx];
        final textScale = slot.width / TodoEisenhowerBoard._cardW;
        pileChildren.add(
          Positioned(
            left: slot.left - minX,
            top: slot.top - minY,
            width: slot.width,
            height: slot.height,
            child: Transform.rotate(
              angle: slot.angle,
              child: wrapDraggable(
                item,
                slot.width,
                slot.height,
                textScale,
              ),
            ),
          ),
        );
      }

      if (n > 1 && expandT < 0.35) {
        final topSlot = slots.last;
        pileChildren.add(
          Positioned(
            left: topSlot.left - minX + topSlot.width - 26,
            top: topSlot.top - minY - 6,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '×$n',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      out.add(
        Positioned(
          left: minX,
          top: minY,
          width: math.max(1, maxX - minX),
          height: math.max(1, maxY - minY),
          child: MouseRegion(
            hitTestBehavior: HitTestBehavior.translucent,
            onEnter: n > 1 && _activeDragItem == null
                ? (_) => _pilePointerEnter(entry.key)
                : null,
            onExit:
                n > 1 ? (_) => _pilePointerExit() : null,
            child: Stack(
              clipBehavior: Clip.none,
              children: pileChildren,
            ),
          ),
        ),
      );
    }
    return out;
  }

  static Widget _miniChip(
    String text,
    Color bgColor,
    Color textColor,
    double fontSize,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: math.max(4, fontSize * 0.6),
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Widget _badgeCircle(String text, Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static Widget _quadrant({
    required Color bg,
    required String titleKo,
    required String subtitle,
    required Color subtitleColor,
    required Widget badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: bg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  titleKo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    height: 1.2,
                  ),
                ),
              ),
              badge,
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = TodoEisenhowerBoard.visibleForMatrix(widget.todos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '카드를 바로 마우스로 끌어 플롯에 놓으면 긴급·중요 각각 1~8이 적용됩니다 '
                  '(축마다 1~4와 5~8로 네 칸씩 두 구간, 사분면과 맞춤). '
                  '손에서 띄워도 카드 더미 위가 아니라 네 칸 어디든 놓을 수 있습니다. '
                  '겹친 묶음은 마우스를 올리면 부채꼴로 펼쳐집니다.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
              Text(
                '완료 숨김',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: TodoEisenhowerBoard._axisLeft,
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      '중요도 높음',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_upward,
                                size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '중요도',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final plotW = constraints.maxWidth;
                          final plotH = constraints.maxHeight;

                          Widget draggableTile(
                            TodoItem item,
                            double sw,
                            double sh,
                            double sc,
                          ) {
                            return Draggable<TodoItem>(
                              data: item,
                              // 피드백 원점 기준 포인터 = 카드 중심 (포인터에서 이 오프셋을 빼 원점 배치)
                              feedbackOffset: Offset(sw / 2, sh / 2),
                              onDragStarted: () {
                                _pileInteractionGeneration++;
                                _pileRevealCtl.reset();
                                setState(() {
                                  _activeDragItem = item;
                                  _dragFeedbackW = sw;
                                  _dragFeedbackH = sh;
                                  _hoveredPileKey = null;
                                  _previewUrgency = null;
                                  _previewImportance = null;
                                  _lastDropUrgency = null;
                                  _lastDropImportance = null;
                                });
                              },
                              onDragEnd: (details) async {
                                final dragged = _activeDragItem;
                                if (!details.wasAccepted &&
                                    dragged != null &&
                                    _lastDropUrgency != null &&
                                    _lastDropImportance != null) {
                                  await _persistDropScores(
                                    dragged.id,
                                    _lastDropUrgency!,
                                    _lastDropImportance!,
                                  );
                                }
                                if (mounted) _resetDragSession();
                              },
                              feedback: Material(
                                elevation: 14,
                                color: Colors.transparent,
                                shadowColor: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                                clipBehavior: Clip.antiAlias,
                                child: Opacity(
                                  opacity: 0.9,
                                  child: SizedBox(
                                    width: sw,
                                    height: sh,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x59000000),
                                            blurRadius: 18,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: _matrixCardChrome(
                                        item,
                                        width: sw,
                                        height: sh,
                                        textScale: sc,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.18,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.open_with,
                                      size: 28 * math.max(0.65, sc),
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ),
                              child: _matrixCardChrome(
                                item,
                                width: sw,
                                height: sh,
                                textScale: sc,
                              ),
                            );
                          }

                          final slop = TodoEisenhowerBoard._dropEdgeSlop;

                          final stackChildren = <Widget>[
                            Positioned.fill(
                              child: IgnorePointer(
                                child: KeyedSubtree(
                                  key: _plotSurfaceKey,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _quadrant(
                                              bg: const Color(0xFFFFF9E6),
                                              titleKo: '급하지 않지만 중요한 일',
                                              subtitle: 'Decide',
                                              subtitleColor:
                                                  Colors.orange.shade800,
                                              badge: _badgeCircle(
                                                  '2', Colors.orange),
                                            ),
                                          ),
                                          Expanded(
                                            child: _quadrant(
                                              bg: const Color(0xFFE3F2FD),
                                              titleKo: '급하고 중요한 일',
                                              subtitle: 'Do',
                                              subtitleColor:
                                                  Colors.blue.shade700,
                                              badge: _badgeCircle(
                                                  '1', Colors.blue.shade700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: _quadrant(
                                              bg: const Color(0xFFF5F5F5),
                                              titleKo:
                                                  '급하지도 중요하지도 않은 일',
                                              subtitle: 'Delete',
                                              subtitleColor:
                                                  Colors.blueGrey.shade700,
                                              badge: _badgeCircle(
                                                  '4',
                                                  Colors.blueGrey.shade700),
                                            ),
                                          ),
                                          Expanded(
                                            child: _quadrant(
                                              bg: const Color(0xFFE8F5E9),
                                              titleKo:
                                                  '급하지만 중요하지 않은 일',
                                              subtitle: 'Delegate',
                                              subtitleColor:
                                                  Colors.green.shade800,
                                              badge: _badgeCircle(
                                                  '3',
                                                  Colors.green.shade700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ..._buildScorePiles(
                              plotW: plotW,
                              plotH: plotH,
                              visible: visible,
                              wrapDraggable: draggableTile,
                            ),
                          ];

                          if (_activeDragItem != null) {
                            stackChildren.add(
                              Positioned(
                                left: -slop,
                                top: -slop,
                                width: plotW + slop * 2,
                                height: plotH + slop * 2,
                                child: DragTarget<TodoItem>(
                                  onWillAcceptWithDetails: (_) => true,
                                  onAcceptWithDetails: _onDrop,
                                  onMove:
                                      (DragTargetDetails<TodoItem> details) {
                                    _updateDropPreviewFromDrag(details.offset);
                                  },
                                  onLeave: (_) => _clearPreview(),
                                  builder:
                                      (context, candidateData, rejected) {
                                    return const SizedBox.expand();
                                  },
                                ),
                              ),
                            );
                          }

                          if (_previewUrgency != null &&
                              _previewImportance != null &&
                              _activeDragItem != null) {
                            stackChildren.add(
                              _buildDropGhost(
                                plotW: plotW,
                                plotH: plotH,
                                u: _previewUrgency!,
                                imp: _previewImportance!,
                                dragging: _activeDragItem!,
                                visible: visible,
                              ),
                            );
                          }

                          final plotDragging = _activeDragItem != null;
                          final overPlotHighlight = plotDragging &&
                              _previewUrgency != null &&
                              _previewImportance != null;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: overPlotHighlight
                                    ? const Color(0xFF1F2937)
                                        .withValues(alpha: 0.55)
                                    : plotDragging
                                        ? const Color(0xFF1F2937)
                                            .withValues(alpha: 0.28)
                                        : Colors.grey.shade300,
                                width:
                                    plotDragging ? 2 : 1,
                              ),
                              boxShadow: overPlotHighlight
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x1A6D28D9),
                                        blurRadius: 16,
                                        spreadRadius: 0,
                                        offset: Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: stackChildren,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            children: [
              SizedBox(width: TodoEisenhowerBoard._axisLeft),
              Text(
                '긴급 낮음',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '긴급도',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Icon(Icons.arrow_forward,
                          size: 16, color: Colors.grey.shade600),
                    ],
                  ),
                ),
              ),
              Text(
                '긴급 높음',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
