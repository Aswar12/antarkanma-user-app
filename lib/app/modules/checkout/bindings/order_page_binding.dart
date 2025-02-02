import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';

class OrderPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<UserMainController>(
      UserMainController()..currentIndex.value = 2,
      permanent: true,
    );
  }
}
