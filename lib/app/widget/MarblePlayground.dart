import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studyo_assigment01/app/widget/AnswerContainer.dart';
import 'package:studyo_assigment01/app/widget/marbel.dart';
import 'package:studyo_assigment01/app/modules/home/controllers/home_controller.dart';

class MarblePlayground extends GetView<HomeController> {
  const MarblePlayground({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
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
                    );
                  }),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
