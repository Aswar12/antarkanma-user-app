import 'package:antarkanma/app/modules/courier/controllers/courier_controller.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/services/user_location_service.dart';
// Import the MerchantController

class CourierBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(UserLocationService());
    Get.put(UserLocationController(
        locationService: Get.find<UserLocationService>()));
    Get.put(CourierController()); // Register the MerchantController
  }
}
