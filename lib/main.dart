import 'dart:async';

import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app/constants/app_theme.dart';
import 'app/constants/app_strings.dart';
import 'app/bindings/initial_binding.dart';
import 'package:get_storage/get_storage.dart';
import 'app/utils/performance_config.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Filter out touch event logs
    if (kDebugMode) {
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message?.contains('ViewRootImpl') == true && 
            message?.contains('MotionEvent') == true) {
          return; // Skip logging touch events
        }
        print(message); // Use print instead of debugPrintSynchronously
      };
    }

    // Initialize performance optimizations for debug mode
    await runZonedGuarded(() async {
      PerformanceConfig.initializeDebugMode();
      
      // Start periodic memory cleanup
      PerformanceConfig.startPeriodicCleanup();

      // Optimize system UI overlays
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
        ),
      );

      // Initialize Firebase with performance settings
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize local notifications plugin with optimized settings
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      // Create the Android notification channel
      if (GetPlatform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'antarkanma_notification_channel',
          'Antarkanma Notifications',
          description: 'Notifications for Antarkanma app',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      await GetStorage.init();
      runApp(const MyApp());
    }, (error, stack) {
      debugPrint('Error caught by runZonedGuarded: $error');
      debugPrint('Stack trace: $stack');
      // You can add additional error reporting here if needed
    });
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow; // Rethrow the error after logging
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: Routes.splash,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      popGesture: false,
      enableLog: false, // Disable GetX logs in production
      logWriterCallback: (String text, {bool isError = false}) {
        // Only log errors in production
        if (isError) {
          debugPrint('ERROR: $text');
        }
      },
    );
  }
}
