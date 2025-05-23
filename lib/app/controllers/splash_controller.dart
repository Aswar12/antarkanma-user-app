import 'package:get/get.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'package:flutter/material.dart';

class SplashController extends GetxController {
  final StorageService _storageService;
  final AuthService _authService;
  final _isInitializing = true.obs;

  SplashController({
    required StorageService storageService,
    required AuthService authService,
  })  : _storageService = storageService,
        _authService = authService;

  bool get isInitializing => _isInitializing.value;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Add a small delay to show splash screen
      await Future.delayed(const Duration(seconds: 2));

      // Check authentication status
      final token = _storageService.getToken();
      final rememberMe = _storageService.getRememberMe();

      if (token != null && rememberMe) {
        // If token exists and remember me is enabled, verify token
        final isValid = await _authService.verifyToken(token);
        if (isValid) {
          // Get latest profile data with retry
          int attempts = 0;
          const maxAttempts = 3;
          while (attempts < maxAttempts) {
            try {
              final profile = await _authService.getProfile(showError: false)
                .timeout(
                  Duration(seconds: 30 + (attempts * 5)),
                  onTimeout: () {
                    debugPrint('Profile fetch timed out (Attempt ${attempts + 1}/$maxAttempts)');
                    return null;
                  },
                );
              
              if (profile != null) {
                _isInitializing.value = false;
                Get.offAllNamed(Routes.userMainPage);
                return;
              }
              
              // If profile is null but no exception, break the loop
              break;
            } catch (e) {
              attempts++;
              if (attempts >= maxAttempts) {
                debugPrint('Max attempts reached for profile fetch');
                break;
              }
              debugPrint('Retrying profile fetch... Attempt: $attempts');
              await Future.delayed(Duration(seconds: attempts));
            }
          }
        }
      }

      // If we have saved credentials and remember me is enabled, try auto-login
      if (rememberMe) {
        final credentials = _storageService.getSavedCredentials();
        if (credentials != null) {
          final success = await _authService.login(
            credentials['identifier']!,
            credentials['password']!,
            rememberMe: true,
            isAutoLogin: true,
            showError: false,
          );
          if (success) {
            _isInitializing.value = false;
            Get.offAllNamed(Routes.userMainPage);
            return;
          }
        }
      }

      // If no valid auth or auto-login failed, go to login
      _isInitializing.value = false;
      Get.offAllNamed(Routes.login);
    } catch (e) {
      debugPrint('Error in splash initialization: $e');
      // In case of error, default to login page
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
