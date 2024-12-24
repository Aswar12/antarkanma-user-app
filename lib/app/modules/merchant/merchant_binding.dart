import 'package:antarkanma/app/modules/merchant/controllers/merchant_controller.dart';
import 'package:antarkanma/app/modules/merchant/controllers/merchant_profile_controller.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/services/user_location_service.dart';
import 'package:antarkanma/app/services/merchant_service.dart'; // Import MerchantService

class MerchantBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(UserLocationService());
    Get.put(UserLocationController(
        locationService: Get.find<UserLocationService>()));
    Get.put(MerchantController());
    Get.lazyPut(() =>
        MerchantProfileController()); // Register the MerchantProfileController
    Get.put(MerchantService()); // Register the MerchantService
  }
}
