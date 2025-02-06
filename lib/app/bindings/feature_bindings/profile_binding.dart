import 'package:get/get.dart';
import '../../controllers/user_controller.dart';
import '../../controllers/user_location_controller.dart';
import '../../services/user_service.dart';
import '../../services/user_location_service.dart';
import '../../services/location_service.dart';
import '../../services/image_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.lazyPut(() => UserService(), fenix: true);
    Get.lazyPut(() => UserLocationService(), fenix: true);
    Get.lazyPut(() => LocationService(), fenix: true);
    Get.lazyPut(() => ImageService(), fenix: true);

    // Controllers
    Get.lazyPut(() => UserController(), fenix: true);
    Get.lazyPut(() => UserLocationController(locationService: Get.find()), fenix: true);
  }
}
