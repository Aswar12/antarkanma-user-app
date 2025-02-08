import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../data/providers/auth_provider.dart';
import '../modules/splash/controllers/splash_controller.dart';
import '../utils/location_permission_handler.dart';
import '../services/location_service.dart';
import '../services/user_location_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('Initializing Essential Services...');
    
    // Only initialize storage service
    // Everything else will be handled by SplashBinding
    final storageService = StorageService.instance;
    Get.put<StorageService>(storageService, permanent: true);
  }

  Future<void> _initializeStorageKeys(StorageService storageService) async {
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
