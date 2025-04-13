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
import 'app/services/fcm_token_service.dart';

// Ignore specific socket errors in debug mode
bool _shouldIgnoreSocketError(dynamic error) {
  if (!kDebugMode) return false;
  
  final errorString = error.toString();
  return errorString.contains('socket_patch.dart:520') || 
         errorString.contains('socket_patch.dart:633') ||
         errorString.contains('NativeSocket.lookup') ||
         errorString.contains('staggeredLookup');
}

class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) => true;
    client.idleTimeout = const Duration(seconds: 60);
    client.connectionTimeout = const Duration(seconds: 10);
    client.maxConnectionsPerHost = 5;
    
    client.findProxy = (uri) {
      try {
        if (uri.host == 'is3.cloudhost.id') {
          debugPrint('🔄 Resolving S3 host: ${uri.host}');
        }
      } catch (e) {
        if (!_shouldIgnoreSocketError(e)) {
          debugPrint('DNS lookup error: $e');
        }
      }
      return 'DIRECT';
    };

    return client;
  }

  @override
  Future<List<InternetAddress>> lookup(String host, {InternetAddress? sourceAddress}) async {
    try {
      return await InternetAddress.lookup(host);
    } catch (e) {
      if (!_shouldIgnoreSocketError(e)) {
        debugPrint('DNS lookup error: $e');
      }
      // Return fallback IP if lookup fails
      return [InternetAddress('0.0.0.0')];
    }
  }
}

Future<void> initializeNetworking() async {
  HttpOverrides.global = CustomHttpOverrides();
  if (kDebugMode) {
    debugPrint('Custom networking initialized with error handling');
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
    rethrow;
  }
}

Future<void> initializeServices() async {
  try {
    // Initialize StorageService first and verify it's working
    final storageService = StorageService.instance;
    await storageService.ensureInitialized();
    
    // Test storage functionality without clearing existing data
    await storageService.saveString('test_key', 'test_value');
    final testValue = storageService.getString('test_key');
    if (testValue != 'test_value') {
      throw Exception('Storage verification failed');
    }
    await storageService.remove('test_key');
    
    Get.put(storageService, permanent: true);
    debugPrint('Storage service verified and working');

    // Print current storage state
    if (kDebugMode) {
      debugPrint('Current storage state:');
      storageService.printStorageState();
    }

    // Initialize AuthService
    final authService = AuthService();
    await authService.ensureInitialized();
    Get.put(authService, permanent: true);
    debugPrint('Auth service initialized');

    // Initialize MainBinding with retry mechanism and error handling
    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      try {
        final mainBinding = MainBinding();
        await mainBinding.dependencies();
        debugPrint('MainBinding initialized successfully');
        break;
      } catch (e) {
        attempts++;
        debugPrint('MainBinding initialization attempt $attempts failed: $e');
        if (attempts >= maxAttempts) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    if (kDebugMode) {
      debugPrint('Core services initialized successfully');
      storageService.printStorageState();
    }
  } catch (e) {
    debugPrint('Error initializing services: $e');
    rethrow;
  }
}

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (kDebugMode) {
      await Get.put(FCMTokenService().init());
    } else {
      Get.put(FCMTokenService().init()).catchError((e) {
        debugPrint('Non-critical FCM initialization error: $e');
      });
    }
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    if (kDebugMode) {
      rethrow;
    }
  }
}

Future<void> initializeApp() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize storage first
    await initializeStorage();

    // Initialize networking with error handling
    await initializeNetworking();

    // Initialize Firebase in parallel
    final firebaseFuture = initializeFirebase();

    // Initialize core services with retry mechanism
    int attempts = 0;
    const maxAttempts = 3;
    Exception? lastError;

    while (attempts < maxAttempts) {
      try {
        await initializeServices();
        debugPrint('Services initialized successfully');
        break;
      } catch (e) {
        attempts++;
        lastError = e as Exception;
        debugPrint('Service initialization attempt $attempts failed: $e');
        if (attempts >= maxAttempts) {
          throw lastError!;
        }
        await Future.delayed(Duration(seconds: attempts));
      }
    }

    // Wait for Firebase in debug mode only
    if (kDebugMode) {
      await firebaseFuture;
    }

    if (kDebugMode) {
      debugPrint('App initialized successfully');
      final storageService = Get.find<StorageService>();
      storageService.printStorageState();
    }
  } catch (e) {
    debugPrint('Error initializing app: $e');
    if (kDebugMode) {
      rethrow;
    }
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
      onReady: () async {
        if (kDebugMode) {
          debugPrint('GetMaterialApp ready');
          // Print storage state when app is ready
          final storageService = Get.find<StorageService>();
          storageService.printStorageState();
        }

        // Ensure proper navigation after initialization
        final storageService = Get.find<StorageService>();
        final token = storageService.getToken();
        final userData = storageService.getUser();
        final rememberMe = storageService.getRememberMe();

        if (token != null && userData != null && rememberMe) {
          debugPrint('Valid session found, navigating to main page');
          await Future.delayed(const Duration(seconds: 2)); // Allow splash to show
          Get.offAllNamed(Routes.userMainPage);
        } else {
          debugPrint('No valid session found, navigating to login');
          await Future.delayed(const Duration(seconds: 2)); // Allow splash to show
          Get.offAllNamed(Routes.login);
        }
      },
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
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
    debugPrint('Fatal error during app startup: $e');
    if (kDebugMode) {
      rethrow;
    }
    runApp(const MyApp());
  }
}
