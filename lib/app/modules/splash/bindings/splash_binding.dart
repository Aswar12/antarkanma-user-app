import 'package:get/get.dart';
import '../controllers/splash_controller.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';
import '../../../services/storage_service.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    print('Initializing SplashBinding...');

    // Ensure core services are available
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService.instance, permanent: true);
    }

    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService(), permanent: true);
    }

    if (!Get.isRegistered<UserService>()) {
      Get.put(UserService(), permanent: true);
    }

    // Initialize SplashController with required dependencies
    Get.put(SplashController());

    print('SplashBinding initialization complete');
  }
}
