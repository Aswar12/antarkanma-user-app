import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../controllers/auth_controller.dart';

class SplashController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final isLoading = true.obs;
  final currentState = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  void _initializeApp() async {
    try {
      // Show splash screen for at least 2 seconds
      currentState.value = 'Initializing...';
      await Future.delayed(const Duration(seconds: 2));

      // Let AuthController handle the auth check and navigation
      // The InitialAuthGuard will have already checked if we have valid credentials
      await _authController.checkAuthStatus();
      
      isLoading.value = false;
    } catch (e) {
      print('Error in splash initialization: $e');
      // If there's any error, go to login
      Get.offAllNamed(Routes.login);
      isLoading.value = false;
    }
  }

  String get status => currentState.value;
}
