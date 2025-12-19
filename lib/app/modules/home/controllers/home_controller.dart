import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class HomeController extends GetxController {
  // Config
  static const double marbleSize = 50;
  static const double gap = 8;
  static const double overlapFactor = 0.95;
  static const double snapThreshold = 40;
  static const int count = 25;

  // State
  final positions = <Offset>[].obs;
  final isDragging = false.obs;
  Size area = Size.zero;
  final GlobalKey stackKey = GlobalKey();
  late List<int> _parent;
  Offset? _dragStartLocal;
  Map<int, Offset>? _clusterStartPositions;
  // Stable cluster anchoring and order to avoid jumping when merging
  final Map<int, Offset> _clusterAnchor = {}; // root -> anchor center
  final Map<int, List<int>> _clusterOrder = {}; // root -> insertion order of members
  // Cluster layout mode: true => rectangular grid, false/absent => clover
  final Map<int, bool> _clusterRectPattern = {};
  // Visual state per marble
  final fills = <Color?>[].obs; // null means default
  final rectFlags = <bool>[].obs; // true => rectangle
  // Flag to indicate a DragTarget handled the drop to avoid extra snap logic
  bool _dropHandledByTarget = false;

  // Assignments state
  final List<String> assignmentList = const [
    '24 / 3',
    '4 * 1',
    '5 - 3',
    '10 / 2',
    '3 + 5',
  ];
  final RxInt assignmentIndex = 0.obs;
  final RxString currentAssignment = ''.obs;

  // Colors used by the three AnswerContainers
  static const Color answerColor1 = Color(0xffe5a882);
  static const Color answerColor2 = Color(0xffdde487);
  static const Color answerColor3 = Color(0xff82dae4);

  @override
  void onInit() {
    super.onInit();
    _parent = List<int>.generate(count, (i) => i);
    // initialize visual states
    fills.assignAll(List<Color?>.filled(count, null));
    rectFlags.assignAll(List<bool>.filled(count, false));
    // init assignment text
    currentAssignment.value = assignmentList.first;
  }

  // Double-tap: split a merged cluster back into individual marbles and scatter them
  void onDoubleTapMarble(int index) {
    final members = _clusterMembers(index);
    if (members.length <= 1) return;
    // Determine center to scatter from: use cluster anchor if available, else centroid
    final root = _find(index);
    Offset center;
    if (_clusterAnchor.containsKey(root)) {
      center = _clusterAnchor[root]!;
    } else {
      double sumX = 0, sumY = 0;
      for (final m in members) {
        sumX += positions[m].dx + marbleSize / 2;
        sumY += positions[m].dy + marbleSize / 2;
      }
      center = Offset(sumX / members.length, sumY / members.length);
    }
    // Scatter radius
    final rnd = Random();
    final radius = marbleSize * 2;
    for (int k = 0; k < members.length; k++) {
      final m = members[k];
      final theta = rnd.nextDouble() * 2 * pi;
      final r = (radius * 0.4) + rnd.nextDouble() * (radius * 0.6);
      final cx = center.dx + r * cos(theta);
      final cy = center.dy + r * sin(theta);
      final topLeft = Offset(cx - marbleSize / 2, cy - marbleSize / 2);
      positions[m] = _clampToBounds(topLeft);
      // Reset visuals to default
      if (m < fills.length) fills[m] = null;
      // Reset union-find parent to itself
      _parent[m] = m;
    }
    // Clear cluster metadata for the old root
    _clusterOrder.remove(root);
    _clusterAnchor.remove(root);
    _clusterRectPattern.remove(root);
    fills.refresh();
    positions.refresh();
  }

  // Check Answer helpers
  int _countByColor(Color color) {
    int n = 0;
    for (int i = 0; i < fills.length; i++) {
      if (fills[i] == color) n++;
    }
    return n;
  }

  ({int c1, int c2, int c3, int total}) countAnswerContainers() {
    final c1 = _countByColor(answerColor1);
    final c2 = _countByColor(answerColor2);
    final c3 = _countByColor(answerColor3);
    return (c1: c1, c2: c2, c3: c3, total: c1 + c2 + c3);
  }

  // Parses strings like "24 / 30" into two integers (a, b)
  (int a, int b)? parseAssignment(String text) {
    final parts = text.split('/');
    if (parts.length != 2) return null;
    final aStr = parts[0].trim();
    final bStr = parts[1].trim();
    final a = int.tryParse(aStr);
    final b = int.tryParse(bStr);
    if (a == null || b == null) return null;
    return (a, b);
  }

  // Evaluate simple arithmetic expressions: a op b, supports + - * /
  // Returns the computed total, and boxes if division form should imply per-box check
  ({int total, int? boxes})? evaluateExpression(String text) {
    final exp = text.replaceAll(' ', '');
    final match = RegExp(r'^(\d+)([+\-*/])(\d+)$').firstMatch(exp);
    if (match == null) return null;
    final a = int.parse(match.group(1)!);
    final op = match.group(2)!;
    final b = int.parse(match.group(3)!);
    switch (op) {
      case '+':
        return (total: a + b, boxes: null);
      case '-':
        return (total: a - b, boxes: null);
      case '*':
        return (total: a * b, boxes: null);
      case '/':
        return (total: a, boxes: b);
      default:
        return null;
    }
  }

  // Compute expected counts per Answer Box for all operators
  // New rule: every Answer Box must contain the SAME count equal to the result of (a op b)
  ({int? b1, int? b2, int? b3})? expectedPerBox(String text) {
    final exp = text.replaceAll(' ', '');
    final match = RegExp(r'^(\d+)([+\-*/])(\d+)$').firstMatch(exp);
    if (match == null) return null;
    final a = int.parse(match.group(1)!);
    final op = match.group(2)!;
    final b = int.parse(match.group(3)!);
    switch (op) {
      case '+': {
        final r = a + b;
        return (b1: r, b2: r, b3: r);
      }
      case '-': {
        final r = a - b;
        return (b1: r, b2: r, b3: r);
      }
      case '*': {
        final r = a * b;
        return (b1: r, b2: r, b3: r);
      }
      case '/':
        if (b == 0) return (b1: null, b2: null, b3: null);
        if (a % b != 0) return (b1: null, b2: null, b3: null);
        final r = a ~/ b;
        return (b1: r, b2: r, b3: r);
      default:
        return null;
    }
  }

  void _advanceAssignment() {
    assignmentIndex.value = (assignmentIndex.value + 1) % assignmentList.length;
    currentAssignment.value = assignmentList[assignmentIndex.value];
  }

  void resetAndScatterAll() {
    final rnd = Random();
    for (int i = 0; i < positions.length; i++) {
      // random positions within area
      final x = rnd.nextDouble() * max(1.0, area.width - marbleSize);
      final y = rnd.nextDouble() * max(1.0, area.height - marbleSize);
      positions[i] = _clampToBounds(Offset(x, y));
      _parent[i] = i;
      if (i < fills.length) fills[i] = null;
    }
    _clusterOrder.clear();
    _clusterAnchor.clear();
    _clusterRectPattern.clear();
    fills.refresh();
    positions.refresh();
  }

  // Require each Answer Box to match its expected count per operator
  void onCheckAnswer(String assignmentText) {
    final expected = expectedPerBox(assignmentText);
    final counts = countAnswerContainers();
    bool correct = false;
    if (expected != null && expected.b1 != null && expected.b2 != null && expected.b3 != null) {
      correct = (counts.c1 == expected.b1 && counts.c2 == expected.b2 && counts.c3 == expected.b3);
    }

    Get.dialog(
      AlertDialog(
        title: const Text('Check Answer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assignment: $assignmentText'),
            const SizedBox(height: 8),
            Text('Answer Box 1: ${counts.c1.toString()}'),
            Text('Answer Box 2: ${counts.c2.toString()}'),
            Text('Answer Box 3: ${counts.c3.toString()}'),
            const SizedBox(height: 8),
            if (expected != null) ...[
              if (expected.b1 != null && counts.c1 != expected.b1)
                const Text('Answer Box 1 wrong number of marbles', style: TextStyle(color: Colors.red)),
              if (expected.b2 != null && counts.c2 != expected.b2)
                const Text('Answer Box 2 wrong number of marbles', style: TextStyle(color: Colors.red)),
              if (expected.b3 != null && counts.c3 != expected.b3)
                const Text('Answer Box 3 wrong number of marbles', style: TextStyle(color: Colors.red)),
              if (expected.b3 == null)
                const Text('Division result is not an integer; cannot distribute exactly', style: TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            Text(correct ? 'Answer Correct' : 'Answer Incorrect',
                style: TextStyle(
                  color: correct ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                )),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );

    if (correct == true) {
      _advanceAssignment();
      resetAndScatterAll();
    }
  }

  void ensureInitialized(Size newArea) {
    area = newArea;
    if (positions.isEmpty) {
      final rnd = Random();
      final list = <Offset>[];
      for (int i = 0; i < count; i++) {
        final x = rnd.nextDouble() * max(1.0, area.width - marbleSize);
        final y = rnd.nextDouble() * max(1.0, area.height - marbleSize);
        list.add(Offset(x, y));
      }
      positions.assignAll(list);
    } else {
      // Clamp
      for (int i = 0; i < positions.length; i++) {
        positions[i] = _clampToBounds(positions[i]);
      }
      positions.refresh();
    }
  }

  void postUpdateAreaFromKey() {
    final ctx = stackKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject();
      if (box is RenderBox) {
        area = box.size;
      }
    }
  }

  // Drag lifecycle
  void onDragStarted(int index) {
    isDragging.value = true;
    _dragStartLocal = null;
    final cluster = _clusterMembers(index);
    _clusterStartPositions = {for (final i in cluster) i: positions[i]};
    // When starting a drag, revert any target-applied color back to default
    if (cluster.isEmpty) return;
    for (final m in cluster) {
      if (m < fills.length) {
        fills[m] = null; // null = default color in UI
      }
    }
    fills.refresh();
    // Also revert cluster layout back to clover for this cluster
    final root = _find(index);
    _clusterRectPattern[root] = false;
  }

  void onDragUpdate(Offset globalPosition) {
    final local = _toLocal(globalPosition);
    _dragStartLocal ??= local;
    final delta = local - _dragStartLocal!;
    final startMap = _clusterStartPositions;
    if (startMap != null) {
      // Move all members and keep anchor in sync
      for (final e in startMap.entries) {
        positions[e.key] = _clampToBounds(e.value + delta);
      }
      // Update anchor of the active cluster
      if (startMap.isNotEmpty) {
        final root = _find(startMap.keys.first);
        final anchor = _clusterAnchor[root] ?? Offset.zero;
        _clusterAnchor[root] = _clampToBounds(anchor + delta);
      }
      positions.refresh();
    }
  }

  void onDragEnd(int index) {
    // If a DragTarget accepted the drop, skip default snap/merge behavior
    if (_dropHandledByTarget) {
      _dropHandledByTarget = false;
      _dragStartLocal = null;
      _clusterStartPositions = null;
      isDragging.value = false;
      return;
    }
    final dropLocal = positions[index];
    _onDrop(index, dropLocal);
    _dragStartLocal = null;
    _clusterStartPositions = null;
    isDragging.value = false;
  }

  // Core logic
  void _onDrop(int index, Offset dropPos) {
    final neighborIdx = _nearestNeighbor(index, dropPos);
    Offset target = dropPos;
    bool merged = false;
    if (neighborIdx != null) {
      final neighborPos = positions[neighborIdx];
      if ((neighborPos - dropPos).distance <= snapThreshold) {
        final snappedNeighbor = _snapToGrid(neighborPos);
        final adjacentCells = [
          Offset(snappedNeighbor.dx + marbleSize + gap, snappedNeighbor.dy),
          Offset(snappedNeighbor.dx - marbleSize - gap, snappedNeighbor.dy),
          Offset(snappedNeighbor.dx, snappedNeighbor.dy + marbleSize + gap),
          Offset(snappedNeighbor.dx, snappedNeighbor.dy - marbleSize - gap),
        ];
        target = _firstFreeCell(adjacentCells) ?? _snapToGrid(dropPos);
        _union(index, neighborIdx);
        // Set stable anchor near the actual drop position to avoid jumping
        final root = _find(index);
        final dropCenter = _clampToBounds(dropPos) + const Offset(marbleSize / 2, marbleSize / 2);
        _clusterAnchor[root] = dropCenter;
        _reflowCluster(index);
        merged = true;
      } else {
        target = _snapToGrid(dropPos);
      }
    } else {
      target = _snapToGrid(dropPos);
    }

    // Only translate the cluster if not merged; merged clusters already reflowed to stable anchor
    if (!merged) {
      final delta = _clampToBounds(target) - positions[index];
      final cluster = _clusterMembers(index);
      for (final i in cluster) {
        positions[i] = _clampToBounds(positions[i] + delta);
      }
      positions.refresh();
    }
  }

  // Reflow with cross-first pattern and slight overlap
  void _reflowCluster(int anyMember) {
    final members = _clusterMembers(anyMember);
    if (members.isEmpty) return;
    final root = _find(anyMember);
    final useRectGrid = _clusterRectPattern[root] == true;
    // If layout area is not ready, avoid reflow that can push items to corners
    if (area.width <= 0 || area.height <= 0) return;
    // Determine or reuse stable anchor
    Offset anchorCenter;
    if (_clusterAnchor.containsKey(root)) {
      anchorCenter = _clusterAnchor[root]!;
    } else {
      double sumX = 0, sumY = 0;
      for (final i in members) {
        sumX += positions[i].dx + marbleSize / 2;
        sumY += positions[i].dy + marbleSize / 2;
      }
      anchorCenter = Offset(
        (sumX / members.length).clamp(marbleSize / 2, area.width - marbleSize / 2),
        (sumY / members.length).clamp(marbleSize / 2, area.height - marbleSize / 2),
      );
      _clusterAnchor[root] = anchorCenter;
    }
    // Base distance gives slight overlap (15%)
    final baseDist = marbleSize * 0.85;

    List<Offset> generatePattern(int needed) {
      if (!useRectGrid) {
        // Diagonal flower layered (quincunx diagonal)
        final list = <Offset>[];
        if (needed > 0) list.add(const Offset(0, 0));
        int placed = list.length;
        int layer = 1;
        while (placed < needed) {
          final items = 4 * layer;
          for (int i = 0; i < items && placed < needed; i++) {
            final theta = (pi / 4) + (2 * pi * i / items);
            final r = baseDist * layer;
            list.add(Offset(r * cos(theta), r * sin(theta)));
            placed++;
          }
          layer++;
        }
        return list;
      } else {
        // Rectangular grid centered at anchor
        final list = <Offset>[];
        final cols = max(1, (sqrt(needed)).ceil());
        final rows = max(1, (needed / cols).ceil());
        final halfW = (cols - 1) * baseDist / 2;
        final halfH = (rows - 1) * baseDist / 2;
        for (int r = 0, k = 0; r < rows && k < needed; r++) {
          for (int c2 = 0; c2 < cols && k < needed; c2++, k++) {
            final dx = -halfW + c2 * baseDist;
            final dy = -halfH + r * baseDist;
            list.add(Offset(dx, dy));
          }
        }
        return list;
      }
    }

    // Clamp anchor so pattern fits in area
    if (!useRectGrid) {
      final kMax = ((members.length - 1 + 3) ~/ 4); // ceil((n-1)/4)
      final margin = baseDist * max(1, kMax) + marbleSize / 2;
      anchorCenter = Offset(
        anchorCenter.dx.clamp(margin, max(margin, area.width - margin)),
        anchorCenter.dy.clamp(margin, max(margin, area.height - margin)),
      );
    } else {
      final cols = max(1, (sqrt(members.length)).ceil());
      final rows = max(1, (members.length / cols).ceil());
      final halfW = (cols - 1) * baseDist / 2 + marbleSize / 2;
      final halfH = (rows - 1) * baseDist / 2 + marbleSize / 2;
      anchorCenter = Offset(
        anchorCenter.dx.clamp(halfW, max(halfW, area.width - halfW)),
        anchorCenter.dy.clamp(halfH, max(halfH, area.height - halfH)),
      );
    }
    _clusterAnchor[root] = anchorCenter;

    final pattern = generatePattern(members.length);
    // Stable order mapping
    final order = _clusterOrder.putIfAbsent(root, () => <int>[]);
    for (final m in members) {
      if (!order.contains(m)) order.add(m);
    }
    order.removeWhere((id) => !members.contains(id));

    for (int k = 0; k < order.length; k++) {
      final id = order[k];
      final g = pattern[k];
      final px = anchorCenter.dx + g.dx - marbleSize / 2;
      final py = anchorCenter.dy + g.dy - marbleSize / 2;
      positions[id] = _clampToBounds(Offset(px, py));
    }
    positions.refresh();
  }

  // Public helpers for DragTarget usage
  bool isMergedIndex(int index) => _clusterMembers(index).length > 1;

  void applyTargetStyle(int index, Color background) {
    final members = _clusterMembers(index);
    if (members.length <= 1) return;
    for (final m in members) {
      fills[m] = background;
    }
    fills.refresh();
    // Switch cluster layout to rectangular grid and reflow
    final root = _find(index);
    _clusterRectPattern[root] = true;
    // Pin anchor near the current cluster centroid to avoid jumping
    double sumX = 0, sumY = 0;
    for (final i in members) {
      sumX += positions[i].dx + marbleSize / 2;
      sumY += positions[i].dy + marbleSize / 2;
    }
    final center = Offset(
      (sumX / members.length).clamp(marbleSize / 2, area.width - marbleSize / 2),
      (sumY / members.length).clamp(marbleSize / 2, area.height - marbleSize / 2),
    );
    _clusterAnchor[root] = center;
    _reflowCluster(index);
  }

  // Called by DragTarget when it accepts a drop
  void markDropHandledByTarget() {
    _dropHandledByTarget = true;
  }

  // Unified handler for drops on targets (works for single or merged clusters)
  void onAcceptedByTarget(int index, Offset globalDropOffset, {Color? targetColor}) {
    // prevent default onDrop snap/merge
    markDropHandledByTarget();
    final local = _toLocal(globalDropOffset);
    final members = _clusterMembers(index);
    if (members.length <= 1) {
      // Move single marble to drop center and apply target color
      final center = _clampToBounds(local);
      final topLeft = Offset(center.dx - marbleSize / 2, center.dy - marbleSize / 2);
      positions[index] = _clampToBounds(topLeft);
      if (targetColor != null) {
        fills[index] = targetColor;
        fills.refresh();
      }
      positions.refresh();
      return;
    }
    // For merged clusters: apply color (if provided), switch to rect grid, pin anchor at drop center, and reflow
    if (targetColor != null) {
      for (final m in members) {
        fills[m] = targetColor;
      }
      fills.refresh();
    }
    final root = _find(index);
    _clusterRectPattern[root] = true;
    final center = _clampToBounds(local);
    _clusterAnchor[root] = center;
    _reflowCluster(index);
  }

  // Union-find helpers
  int _find(int x) => _parent[x] == x ? x : _parent[x] = _find(_parent[x]);
  void _union(int a, int b) {
    final ra = _find(a);
    final rb = _find(b);
    if (ra == rb) return;
    // Prefer keeping anchor of larger ordered cluster
    final listA = _clusterOrder[ra] ?? [ra];
    final listB = _clusterOrder[rb] ?? [rb];
    final newRoot = listA.length >= listB.length ? ra : rb;
    final child = newRoot == ra ? rb : ra;
    _parent[child] = newRoot;
    // Merge order
    final merged = <int>[]..addAll(_clusterOrder[newRoot] ?? [newRoot])..addAll(_clusterOrder[child] ?? [child]);
    _clusterOrder[newRoot] = merged;
    _clusterOrder.remove(child);
    // Keep anchor of chosen root if exists, else adopt from child or compute later
    if (!_clusterAnchor.containsKey(newRoot) && _clusterAnchor.containsKey(child)) {
      _clusterAnchor[newRoot] = _clusterAnchor[child]!;
    }
    _clusterAnchor.remove(child);
    // Merge layout flags: if any child was rectangular, new root stays rectangular
    final rectNew = (_clusterRectPattern[newRoot] == true) || (_clusterRectPattern[child] == true);
    if (rectNew) _clusterRectPattern[newRoot] = true;
    _clusterRectPattern.remove(child);
  }
  List<int> _clusterMembers(int idx) {
    final r = _find(idx);
    final members = <int>[];
    for (int i = 0; i < positions.length; i++) {
      if (_find(i) == r) members.add(i);
    }
    return members;
  }

  // Geometry helpers
  Offset? _firstFreeCell(List<Offset> candidates) {
    for (final c in candidates) {
      final snapped = _snapToGrid(c);
      final overlapped = positions.any((p) => (p - snapped).distance < (marbleSize * 0.5));
      if (!overlapped) return snapped;
    }
    return null;
  }

  int? _nearestNeighbor(int selfIndex, Offset pos) {
    int? idx;
    double best = double.infinity;
    for (int i = 0; i < positions.length; i++) {
      if (i == selfIndex) continue;
      final d = (positions[i] - pos).distance;
      if (d < best) {
        best = d;
        idx = i;
      }
    }
    return idx;
  }

  Offset _snapToGrid(Offset pos) {
    final cell = marbleSize + gap;
    double gx = (pos.dx / cell).round() * cell;
    double gy = (pos.dy / cell).round() * cell;
    return Offset(gx, gy);
  }

  Offset _clampToBounds(Offset pos) {
    final maxX = max(0.0, area.width - marbleSize);
    final maxY = max(0.0, area.height - marbleSize);
    return Offset(pos.dx.clamp(0.0, maxX), pos.dy.clamp(0.0, maxY));
  }

  Offset _toLocal(Offset globalDropOffset) {
    final ctx = stackKey.currentContext;
    if (ctx != null) {
      final box = ctx.findRenderObject();
      if (box is RenderBox) {
        final local = box.globalToLocal(globalDropOffset);
        return _clampToBounds(local);
      }
    }
    return _clampToBounds(globalDropOffset);
  }
}
