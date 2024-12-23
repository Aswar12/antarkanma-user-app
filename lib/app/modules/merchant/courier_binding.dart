import 'package:get/get.dart';
import 'controllers/courier_controller.dart'; // Adjust the import based on your controller's location

class CourierBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CourierController>(() => CourierController());
  }
}
