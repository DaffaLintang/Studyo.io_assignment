import 'package:get/get.dart';
import 'package:studyo_assigment01/core/domain/usecases/check_answer_usecase.dart';

import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CheckAnswerUseCase>(() => CheckAnswerUseCase());
    Get.lazyPut<HomeController>(() => HomeController(
          checkAnswerUseCase: Get.find<CheckAnswerUseCase>(),
        ));
  }
}
