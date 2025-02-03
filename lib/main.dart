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

    // Initialize GetStorage before anything else
    await GetStorage.init();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize notifications
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

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

    // Configure GetX
    Get.config(
      enableLog: kDebugMode,
      defaultTransition: Transition.fadeIn,
      defaultPopGesture: false,
    );

    // Initialize system UI settings
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );

    // Run the app
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Error during initialization: $e');
    debugPrint('Stack trace: $stackTrace');
    rethrow;
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
      initialBinding: InitialBinding(), // Initialize core dependencies
      initialRoute: Routes.splash,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      popGesture: false,
      enableLog: kDebugMode,
      logWriterCallback: (String text, {bool isError = false}) {
        if (isError || kDebugMode) {
          debugPrint('${isError ? 'ERROR: ' : ''}$text');
        }
      },
      onInit: () {
        // Additional initialization after GetMaterialApp is created
        PerformanceConfig.initializeDebugMode();
        PerformanceConfig.startPeriodicCleanup();
      },
    );
  }
}
