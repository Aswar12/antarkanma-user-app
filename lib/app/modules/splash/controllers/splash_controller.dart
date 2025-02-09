import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../services/storage_service.dart';
import '../../../services/auth_service.dart';

class SplashController extends GetxController {
  final StorageService _storageService = StorageService.instance;
  final AuthService _authService = Get.find<AuthService>();
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

      // Check if user is already logged in and attempt auto-login
      currentState.value = 'Checking authentication...';
      final autoLoginSuccess = await _authService.autoLogin();
      
      if (autoLoginSuccess) {
        currentState.value = 'Loading user data...';
        Get.offAllNamed(Routes.userMainPage);
        return;
      }

      // If auto-login fails, go to login page
      Get.offAllNamed(Routes.login);
    } finally {
      isLoading.value = false;
    }
  }

  String get status => currentState.value;
}
