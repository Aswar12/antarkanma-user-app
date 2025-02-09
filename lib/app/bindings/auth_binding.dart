import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthService());
    Get.put(AuthController());
  }

  static Future<void> initializeAuthenticatedServices() async {
    // Initialize any services that require authentication
    try {
      // Add any additional authenticated service initialization here
      // For example:
      // await Get.putAsync(() => UserService().init());
      // await Get.putAsync(() => CartService().init());
    } catch (e) {
      print('Error initializing authenticated services: $e');
      rethrow;
    }
  }
}
