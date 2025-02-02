import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
      
      // Disable system channel logging
      SystemChannels.lifecycle.setMessageHandler(null);
      
      // Keep debug prints enabled for development but filter out motion events
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null && 
            !message.contains('MotionEvent') && 
            !message.contains('ViewRootImpl') &&
            !message.contains('dispatchPointerEvent')) {
          print(message);
        }
      };
    }

    // Optimize image cache
    PaintingBinding.instance.imageCache.maximumSize = 50; // Reduce from default 1000
    PaintingBinding.instance.imageCache.maximumSizeBytes = 20 << 20; // 20 MB

    // Enable GetX logging in debug but filter out unnecessary logs
    Get.isLogEnable = true;
    Get.config(
      enableLog: true,
      logWriterCallback: (String text, {bool isError = false}) {
        if (!text.contains('MotionEvent') && 
            !text.contains('ViewRootImpl') &&
            !text.contains('dispatchPointerEvent')) {
          debugPrint(text);
        }
      },
    );
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
