import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get/get.dart';
import 'package:studyo_assigment01/presentation/widgets/widget/AnswerContainer.dart';
import 'package:studyo_assigment01/presentation/widgets/widget/marbel.dart';
import 'package:studyo_assigment01/presentation/modules/home/controllers/home_controller.dart';

class MarblePlayground extends StatefulWidget {
  const MarblePlayground({super.key});

  @override
  State<MarblePlayground> createState() => _MarblePlaygroundState();
}

class _MarblePlaygroundState extends State<MarblePlayground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;

  HomeController get c => Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        // drive a lightweight repaint for idle/ripple animation
        if (mounted) setState(() {});
      })
      ..repeat(min: 0.0, max: 1.0, period: const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  // Compute visual offset for marble i (idle jitter + ripple), excluding marbles already in targets (filled)
  Offset _visualOffsetFor(int i) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final fills = c.fills;
    Offset total = Offset.zero;

    // Idle jitter if not dragging and not in target
    if (!c.isDragging.value && (i >= fills.length || fills[i] == null)) {
      final t = nowMs / 1000.0;
      final amp = 1.5; // pixels
      final dx = amp * (0.7 * (i.isEven ? 1 : -1)) * (0.5 + 0.5 * math.sin(t * 2.1 + i));
      final dy = amp * (0.7 * (i.isOdd ? 1 : -1)) * (0.5 + 0.5 * math.cos(t * 1.7 + i * 0.6));
      total += Offset(dx, dy);
    }

    // Reaction to dragging: nearby marbles are repelled from the dragged cluster (except filled/target marbles and dragged ones)
    if (c.isDragging.value && (i >= fills.length || fills[i] == null)) {
      final dragged = c.draggedMembers();
      if (dragged.isNotEmpty && !dragged.contains(i) && i < c.positions.length) {
        // Compute influence from closest dragged member
        Offset? closestDelta;
        double closestDist = double.infinity;
        for (final d in dragged) {
          if (d >= c.positions.length) continue;
          final a = c.positions[d] + const Offset(HomeController.marbleSize / 2, HomeController.marbleSize / 2);
          final b = c.positions[i] + const Offset(HomeController.marbleSize / 2, HomeController.marbleSize / 2);
          final delta = b - a;
          final dist = delta.distance;
          if (dist < closestDist) {
            closestDist = dist;
            closestDelta = delta;
          }
        }
        if (closestDelta != null && closestDist.isFinite && closestDist > 0) {
          // Influence radius and strength
          const influence = 160.0; // px
          if (closestDist < influence) {
            final dir = Offset(closestDelta.dx / closestDist, closestDelta.dy / closestDist);
            final falloff = 1.0 - (closestDist / influence);
            final push = 10.0 * falloff * falloff; // quadratic falloff
            total += dir * push;
          }
        }
      }
    }

    // Ripple on merge (stronger)
    final start = c.rippleStart;
    final center = c.rippleCenter;
    if (start != null && center != null && i < c.positions.length) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      const duration = 700; // ms
      if (elapsed < duration) {
        final posCenter = c.positions[i] + const Offset(HomeController.marbleSize / 2, HomeController.marbleSize / 2);
        final v = posCenter - center;
        final dist = v.distance + 0.0001;
        final dir = Offset(v.dx / dist, v.dy / dist);
        final progress = elapsed / duration;
        final radius = 30.0 + 170.0 * progress;
        final band = 48.0; // thickness of wave band
        final within = (dist - radius).abs() <= band;
        if (within && (i >= fills.length || fills[i] == null)) {
          final strength = (1.0 - progress) * (1.0 - ((dist - radius).abs() / band)).clamp(0.0, 1.0);
          total += dir * (9.0 * strength);
        }
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        c.ensureInitialized(Size(width, constraints.maxHeight == double.infinity ? 300.0 : constraints.maxHeight));

        WidgetsBinding.instance.addPostFrameCallback((_) {
          c.postUpdateAreaFromKey();
        });

        return Container(
          key: c.stackKey,
          width: width,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AnswerContainer(
                    backgroud: Color(0xffe5a882),
                    shadow: Color(0xffb3714d),
                  ),
                  AnswerContainer(
                    backgroud: Color(0xffdde487),
                    shadow: Color(0xffc7b845),
                  ),
                  AnswerContainer(
                    backgroud: Color(0xff82dae4),
                    shadow: Color(0xff4baab6),
                  ),
                ],
              ),
              Obx(() {
                final pos = c.positions;
                final fills = c.fills;
                final rects = c.rectFlags;
                return Stack(
                  children: List.generate(pos.length, (i) {
                    final p = pos[i];
                    final fill = (i < fills.length) ? fills[i] : null;
                    final isRect = (i < rects.length) ? rects[i] : false;
                    return AnimatedPositioned(
                      left: p.dx,
                      top: p.dy,
                      duration: c.isDragging.value ? Duration.zero : const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Transform.translate(
                        offset: _visualOffsetFor(i),
                        child: Draggable<int>(
                          data: i,
                          feedback: IgnorePointer(child: Marbel(fill: fill, isRectangle: isRect)),
                          childWhenDragging: const SizedBox(width: HomeController.marbleSize, height: HomeController.marbleSize),
                          child: GestureDetector(
                            onDoubleTap: () => c.onDoubleTapMarble(i),
                            child: Marbel(fill: fill, isRectangle: isRect),
                          ),
                          onDragStarted: () => c.onDragStarted(i),
                          onDragUpdate: (details) => c.onDragUpdate(details.globalPosition),
                          onDragEnd: (_) => c.onDragEnd(i),
                        ),
                      ),
                    );
                  }),
                );
              }),
              // Connection lines between marbles in the same cluster (drawn on TOP)
              Obx(() {
                final clusters = c.allClusters();
                final visualPositions = List<Offset>.generate(
                  c.positions.length,
                  (i) => c.positions[i] + _visualOffsetFor(i),
                );
                return Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true,
                    child: CustomPaint(
                      painter: _ConnectionsPainter(
                        positions: visualPositions,
                        clusters: clusters,
                        fills: c.fills.toList(),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _ConnectionsPainter extends CustomPainter {
  final List<Offset> positions;
  final List<List<int>> clusters;
  final List<Color?> fills;

  _ConnectionsPainter({required this.positions, required this.clusters, required this.fills});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final group in clusters) {
      if (group.length < 2) continue;
      // draw lines between all pairs in the group
      for (int i = 0; i < group.length; i++) {
        for (int j = i + 1; j < group.length; j++) {
          // Skip if either marble is inside an AnswerContainer (has fill color)
          if ((group[i] < fills.length && fills[group[i]] != null) ||
              (group[j] < fills.length && fills[group[j]] != null)) {
            continue;
          }
          final a = positions[group[i]] + const Offset(HomeController.marbleSize / 2, HomeController.marbleSize / 2);
          final b = positions[group[j]] + const Offset(HomeController.marbleSize / 2, HomeController.marbleSize / 2);
          canvas.drawLine(a, b, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionsPainter oldDelegate) {
    return !identical(oldDelegate.positions, positions) || oldDelegate.clusters != clusters;
  }
}
