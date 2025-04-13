import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../services/storage_service.dart';
import '../../../services/auth_service.dart';

class SplashController extends GetxController {
  final StorageService storageService;
  final AuthService authService;
  final _isInitializing = true.obs;

  SplashController({
    required this.storageService,
    required this.authService,
  });

  bool get isInitializing => _isInitializing.value;

  @override
  void onInit() {
    super.onInit();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    try {
      // Show splash for minimum time
      await Future.delayed(const Duration(milliseconds: 1500));

      // Quick memory access first
      final token = storageService.getToken();
      final userData = storageService.getUser();
      final rememberMe = storageService.getRememberMe();

      debugPrint('Splash navigation check - Token: ${token != null}, User: ${userData != null}, RememberMe: $rememberMe');

      // If no credentials, go to login
      if (token == null || userData == null || !rememberMe) {
        _isInitializing.value = false;
        Get.offAllNamed(Routes.login);
        return;
      }

      // Try to verify token
      final isValid = await authService.verifyToken(token);
      
      _isInitializing.value = false;
      if (isValid) {
        debugPrint('Token verified, navigating to main page');
        Get.offAllNamed(Routes.userMainPage);
      } else {
        debugPrint('Token invalid, navigating to login');
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      debugPrint('Error in splash navigation: $e');
      _isInitializing.value = false;
      Get.offAllNamed(Routes.login);
    }
  }

  @override
  void onClose() {
    _isInitializing.value = false;
    super.onClose();
  }
}
