import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';

class PerformanceConfig {
  // Singleton instance
  static final PerformanceConfig _instance = PerformanceConfig._internal();
  factory PerformanceConfig() => _instance;
  PerformanceConfig._internal();

  static void initializeDebugMode() {
    // Disable expensive debug mode features
    if (kDebugMode) {
      debugPrintRebuildDirtyWidgets = false;
      debugPrintLayouts = false;
      debugProfileBuildsEnabled = false;
      // Keep debug prints enabled for development
      debugPrint = (String? message, {int? wrapWidth}) {
        print(message);
      };
    }

    // Optimize image cache
    PaintingBinding.instance.imageCache.maximumSize = 50; // Reduce from default 1000
    PaintingBinding.instance.imageCache.maximumSizeBytes = 20 << 20; // 20 MB

    // Enable GetX logging in debug
    Get.isLogEnable = true;
  }

  static Future<void> clearMemory() async {
    // Clear image caches
    imageCache.clear();
    imageCache.clearLiveImages();
    
    // Clear network cache
    await DefaultCacheManager().emptyCache();
    
    // Clear GetX cache
    Get.reset();
  }

  // Schedule periodic memory cleanup
  static void startPeriodicCleanup() {
    Future.delayed(const Duration(minutes: 2), () {
      clearMemory();
      startPeriodicCleanup(); // Schedule next cleanup
    });
  }
}
