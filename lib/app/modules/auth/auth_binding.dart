import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize AuthService first and make it permanent
    if (!Get.isRegistered<AuthService>()) {
      print('AuthBinding: Initializing AuthService...');
      Get.put(AuthService(), permanent: true);
    }

    // Initialize AuthController and make it permanent since it's needed throughout the app
    if (!Get.isRegistered<AuthController>()) {
      print('AuthBinding: Initializing AuthController...');
      Get.put(AuthController(), permanent: true);
    }
  }
}
