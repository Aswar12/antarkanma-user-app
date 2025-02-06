import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../data/providers/auth_provider.dart';
import '../modules/splash/controllers/splash_controller.dart';
import '../utils/location_permission_handler.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('Initializing Essential Services...');
    
    // Core Storage - needed for checking first launch and permissions
    final storageService = StorageService.instance;
    Get.put<StorageService>(storageService, permanent: true);

    // Add first launch and permissions keys
    _initializeStorageKeys(storageService);
    
    // Permission Handler - needed for initial permission requests
    Get.put(LocationPermissionHandler(), permanent: true);
    
    // Minimal Auth Services - needed for checking auth state
    Get.put(AuthProvider(), permanent: true);
    Get.put(AuthService(), permanent: true);
    
    // Splash Controller - handles initialization flow
    Get.put(SplashController(), permanent: true);
  }

  void _initializeStorageKeys(StorageService storageService) async {
    // Add new keys if they don't exist
    if (!storageService.hasKey('first_launch')) {
      await storageService.saveBool('first_launch', true);
    }

    if (!storageService.hasKey('permissions')) {
      await storageService.saveMap('permissions', {
        'location': false,
        'storage': false,
        'camera': false,
        'notification': false,
      });
    }

    if (!storageService.hasKey('app_state')) {
      await storageService.saveMap('app_state', {
        'last_launch': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0.0',
        'initialized': false,
      });
    }
  }
}
