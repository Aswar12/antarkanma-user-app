import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'app/routes/app_pages.dart';
import 'app/bindings/main_binding.dart';
import 'app/services/auth_service.dart';
import 'app/services/storage_service.dart';

class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) => true;
    client.idleTimeout = const Duration(seconds: 60);
    client.findProxy = (uri) {
      if (uri.host == 'is3.cloudhost.id') {
        debugPrint('🔄 Resolving S3 host: ${uri.host}');
      }
      return 'DIRECT';
    };
    return client;
  }
}

Future<void> initializeNetworking() async {
  HttpOverrides.global = CustomHttpOverrides();
  if (kDebugMode) {
    debugPrint('Custom networking initialized');
  }
}

Future<void> initializeStorage() async {
  try {
    await GetStorage.init();
    if (kDebugMode) {
      debugPrint('Storage initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error initializing storage: $e');
    }
  }
}

Future<void> initializeServices() async {
  try {
    // Initialize StorageService first
    final storageService = StorageService.instance;
    await storageService.ensureInitialized();
    Get.put(storageService, permanent: true);

    // Initialize AuthService
    final authService = AuthService();
    await authService.ensureInitialized();
    Get.put(authService, permanent: true);

    // Initialize MainBinding and wait for it to complete
    final mainBinding = MainBinding();
    await mainBinding.dependencies();

    if (kDebugMode) {
      debugPrint('Core services initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error initializing services: $e');
    }
    rethrow;
  }
}

Future<void> initializeApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize storage first
    await initializeStorage();

    // Initialize networking
    await initializeNetworking();

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize core services and wait for completion
    await initializeServices();

    if (kDebugMode) {
      debugPrint('App initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error initializing app: $e');
    }
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Antarkanma',
      theme: ThemeData(
        primarySwatch: primarySwatch,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: kDebugMode,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
      onInit: () {
        if (kDebugMode) {
          debugPrint('GetMaterialApp initialized');
        }
      },
      onReady: () {
        if (kDebugMode) {
          debugPrint('GetMaterialApp ready');
        }
      },
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: child!,
        );
      },
    );
  }
}

void main() async {
  try {
    await initializeApp();
    runApp(const MyApp());
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Fatal error during app startup: $e');
    }
    rethrow;
  }
}
