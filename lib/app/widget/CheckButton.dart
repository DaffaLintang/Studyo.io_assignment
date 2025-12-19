import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:studyo_assigment01/app/modules/home/controllers/home_controller.dart';

class Checkbutton extends StatelessWidget {
  const Checkbutton({super.key, required this.assignmentText});

  final String assignmentText;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HomeController>();
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: () => c.onCheckAnswer(assignmentText),
          child: Container(
            height: 50,
            width: 300,
            decoration: BoxDecoration(
              color: Color(0xFF83e4b7),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(color: Color(0xFF65af62), offset: const Offset(5, 5)),
              ],
            ),
            child: Center(
              child: Text(
                "Check Answer",
                style: TextStyle(
                  color: Color(0xFF65af62),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
