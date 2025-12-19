import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:studyo_assigment01/app/widget/AppContainer.dart';
import 'package:studyo_assigment01/app/widget/Appbar.dart';
import 'package:studyo_assigment01/app/widget/AssigmentContainer.dart';
import 'package:studyo_assigment01/app/widget/CheckButton.dart';
import 'package:studyo_assigment01/app/widget/MarblePlayground.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            AppContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Appbar(),
                  Obx(() => Assigment(text: controller.currentAssignment.value)),
                  Expanded(child: MarblePlayground()),
                ],
              ),
            ),
            Obx(() => Checkbutton(assignmentText: controller.currentAssignment.value)),
          ],
        ),
      ),
    );
  }
}