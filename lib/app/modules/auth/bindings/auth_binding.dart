import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    print('Initializing AuthBinding...');

    // Ensure core services are available
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService.instance, permanent: true);
    }

    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService(), permanent: true);
    }

    // Ensure AuthController is available
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }

    print('AuthBinding initialization complete');
  }
}
