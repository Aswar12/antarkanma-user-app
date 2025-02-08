import 'package:get/get.dart';
import '../../controllers/user_controller.dart';
import '../../services/user_service.dart';
import '../../services/image_service.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Services that are specific to profile features
    Get.lazyPut(() => UserService(), fenix: true);
    Get.lazyPut(() => ImageService(), fenix: true);

    // Controllers specific to profile features
    Get.lazyPut(() => UserController(), fenix: true);
    
    // Note: UserLocationController and its dependencies are now handled by UserMainBinding
  }
}
