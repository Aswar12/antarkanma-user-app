import 'package:antarkanma/app/data/providers/auth_provider.dart';
import 'package:get/get.dart';
import '../../modules/splash/controllers/splash_controller.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/location_service.dart';
import '../../services/user_location_service.dart';
import '../../services/user_service.dart';
import '../../utils/location_permission_handler.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize auth provider first
    if (!Get.isRegistered<AuthProvider>()) {
      Get.put(AuthProvider(), permanent: true);
    }

    // Then initialize auth service
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService(), permanent: true);
    }
    
    // Initialize location-related services
    if (!Get.isRegistered<LocationPermissionHandler>()) {
      Get.put(LocationPermissionHandler(), permanent: true);
    }
    
    if (!Get.isRegistered<LocationService>()) {
      Get.put(LocationService(), permanent: true);
    }
    
    // Initialize user-related services
    if (!Get.isRegistered<UserService>()) {
      Get.put(UserService(), permanent: true);
    }
    
    if (!Get.isRegistered<UserLocationService>()) {
      Get.put(UserLocationService(), permanent: true);
    }
    
    // Initialize the splash controller last
    if (!Get.isRegistered<SplashController>()) {
      Get.put(SplashController(), permanent: true);
    }
  }
}
