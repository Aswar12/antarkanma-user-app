import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';
import '../../../data/providers/auth_provider.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    print('Initializing AuthBinding...');

    // Initialize dependencies in correct order
    
    // 1. Core Storage Service
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService.instance, permanent: true);
    }

    // 2. Auth Provider
    if (!Get.isRegistered<AuthProvider>()) {
      Get.put(AuthProvider(), permanent: true);
    }

    // 3. Auth Service (depends on StorageService and AuthProvider)
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService(), permanent: true);
    }

    // 4. Auth Controller (depends on AuthService)
    Get.put(AuthController(), permanent: true);

    print('AuthBinding initialization complete');
  }
}
