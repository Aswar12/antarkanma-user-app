import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize performance optimizations for debug mode
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
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  await GetStorage.init();
  runApp(const MyApp());
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
