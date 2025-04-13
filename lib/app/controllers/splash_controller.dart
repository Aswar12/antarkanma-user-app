import 'package:get/get.dart';
import '../routes/app_pages.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../services/merchant_service.dart';
import 'package:flutter/material.dart';

class SplashController extends GetxController {
  final StorageService _storageService;
  final AuthService _authService;
  final _isInitializing = true.obs;
  final _initialRoute = ''.obs;

  SplashController({
    required StorageService storageService,
    required AuthService authService,
  })  : _storageService = storageService,
        _authService = authService;

  bool get isInitializing => _isInitializing.value;
  String get initialRoute => _initialRoute.value;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Start preloading data in parallel with auth check
      final preloadFuture = _preloadData();
      
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
                await preloadFuture;
                _isInitializing.value = false;
                _initialRoute.value = Routes.userMainPage;
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
            // Wait for preload to complete before navigation
            await preloadFuture;
            _isInitializing.value = false;
            _initialRoute.value = Routes.userMainPage;
            return;
          }
        }
      }

      // If no valid auth or auto-login failed, go to login
      _isInitializing.value = false;
      _initialRoute.value = Routes.login;
    } catch (e) {
      debugPrint('Error in splash initialization: $e');
      // In case of error, default to login page
      _isInitializing.value = false;
      _initialRoute.value = Routes.login;
    }
  }

  Future<void> _preloadData() async {
    try {
      // Get required services
      final locationService = Get.find<LocationService>();
      final categoryService = Get.find<CategoryService>();
      final productService = Get.find<ProductService>();
      final merchantService = Get.find<MerchantService>();
      
      // Load categories and clear storage first
      await Future.wait([
        categoryService.getCategories(),
        productService.clearLocalStorage(),
        merchantService.clearLocalStorage(),
      ]);

      // Then try to get location with timeout
      try {
        await locationService.getCurrentLocation()
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('Location fetch timed out, continuing with default location');
      }
      
    } catch (e) {
      debugPrint('Error in preloading data: $e');
      // Don't throw - we want splash to continue even if preload fails
    }
  }

  @override
  void onClose() {
    _isInitializing.value = false;
    super.onClose();
  }
}
