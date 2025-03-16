import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../services/storage_service.dart';

class SplashController extends GetxController {
  final StorageService storageService;

  SplashController({required this.storageService});

  @override
  void onInit() {
    super.onInit();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    try {
      // Initialize storage in parallel with minimal splash display
      final initFuture = storageService.ensureInitialized();

      // Remove artificial delay and use minimal time for branding visibility
      await Future.wait([
        initFuture,
        Future.delayed(
            const Duration(milliseconds: 800)), // Reduced from 2s to 800ms
      ]);

      // Quick memory access after initialization
      final token = storageService.getToken();
      final userData = storageService.getUser();
      final rememberMe = storageService.getRememberMe();

      // Immediate navigation based on auth state
      if (token != null && userData != null && rememberMe) {
        Get.offAllNamed(Routes.userMainPage);
      } else {
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      debugPrint('Error in splash initialization: $e');
      Get.offAllNamed(Routes.login);
    }
  }
}
