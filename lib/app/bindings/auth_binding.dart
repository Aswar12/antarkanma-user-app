import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/fcm_token_service.dart';
import '../services/location_service.dart';
import '../data/providers/auth_provider.dart';
import '../services/storage_service.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('Initializing Auth Services...');

    // Core services needed for auth
    final storageService = Get.find<StorageService>();

    // Auth-specific services
    Get.lazyPut(() => AuthProvider(), fenix: true);
    Get.lazyPut(() => AuthService(), fenix: true);
    Get.lazyPut(() => UserService(), fenix: true);
    Get.lazyPut(() => FCMTokenService(), fenix: true);
    Get.lazyPut(() => LocationService(), fenix: true);

    // Auth-related controllers
    Get.put(AuthController(), permanent: true);  // Make AuthController permanent
    Get.lazyPut(() => UserController(), fenix: true);
  }

  // Helper method to check if auth is initialized
  static bool isAuthInitialized() {
    try {
      final storageService = Get.find<StorageService>();
      final appState = storageService.getMap('app_state');
      return appState?['auth_initialized'] == true;
    } catch (e) {
      debugPrint('Error checking auth initialization: $e');
      return false;
    }
  }

  // Helper method to mark auth as initialized
  static Future<void> markAuthInitialized() async {
    try {
      final storageService = Get.find<StorageService>();
      final appState = storageService.getMap('app_state') ?? {};
      appState['auth_initialized'] = true;
      await storageService.saveMap('app_state', appState);
    } catch (e) {
      debugPrint('Error marking auth as initialized: $e');
    }
  }

  // Helper method to initialize authenticated services
  static Future<void> initializeAuthenticatedServices() async {
    try {
      debugPrint('Initializing authenticated services...');
      
      // Initialize FCM Token Service
      try {
        final fcmTokenService = Get.find<FCMTokenService>();
        await fcmTokenService.init();
      } catch (e) {
        debugPrint('Error handling FCM token: $e');
      }

      // Initialize Location Service
      try {
        final locationService = Get.find<LocationService>();
        await locationService.init();
      } catch (e) {
        debugPrint('Error initializing location service: $e');
      }

    } catch (e) {
      debugPrint('Error initializing authenticated services: $e');
    }
  }
}
