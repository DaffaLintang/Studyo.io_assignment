import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:studyo_assigment01/app/modules/home/controllers/home_controller.dart';

class AnswerContainer extends StatelessWidget {
  const AnswerContainer({super.key, required this.backgroud, required this.shadow});

  final Color backgroud; 
  final Color shadow; 

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        final index = details.data;
        // Use unified handler to support both single and merged marbles
        c.onAcceptedByTarget(index, details.offset, targetColor: backgroud);
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return Container(
          margin: const EdgeInsets.only(top: 30.0),
          height: 100,
          width: 50,
          decoration: BoxDecoration(
            color: backgroud.withValues(alpha: isActive ? 0.9 : 1.0),
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: [
              BoxShadow(color: shadow, offset: const Offset(5, 5)),
            ],
          ),
        );
      },
    );
  }
}
