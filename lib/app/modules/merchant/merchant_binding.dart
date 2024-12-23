import 'package:get/get.dart';
import 'controllers/merchant_controller.dart'; // Adjust the import based on your controller's location

class MerchantBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MerchantController>(() => MerchantController());
  }
}
