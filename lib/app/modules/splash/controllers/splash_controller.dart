import 'dart:async';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';
import '../../../routes/app_pages.dart';
import '../../../data/models/user_model.dart';
import '../../../utils/location_permission_handler.dart';
import '../../../services/location_service.dart';
import '../../../services/user_location_service.dart';
import '../../../data/providers/auth_provider.dart';

class SplashController extends GetxController {
  // State
  final RxBool _isLoading = true.obs;
  final RxString _currentState = 'Initializing...'.obs;
  bool get isLoading => _isLoading.value;
  String get currentState => _currentState.value;

  // Services
  late final StorageService _storageService;
  late final AuthService _authService;
  late final LocationService _locationService;
  late final UserLocationService _userLocationService;

  @override
  void onInit() {
    super.onInit();
    // Start initialization after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Get services that were initialized in bindings
      _currentState.value = 'Loading core services...';
      await _initializeServices();

      // Initialize storage and check first launch
      _currentState.value = 'Loading app data...';
      await _initializeStorage();

      // Request permissions if needed
      _currentState.value = 'Checking permissions...';
      await _requestInitialPermissions();

      // Initialize location services
      _currentState.value = 'Setting up location services...';
      await _initializeLocationServices();

      // Initialize notifications if permitted
      _currentState.value = 'Setting up notifications...';
      await _initializeNotifications();

      // Quick auth check
      _currentState.value = 'Checking authentication...';
      await _quickAuthCheck();

      // Show splash for minimum time
      await Future.delayed(const Duration(seconds: 2));

      // Navigate based on auth status
      await _handleNavigation();
    } catch (e) {
      debugPrint('Error in splash initialization: $e');
      _handleError(e);
    }
  }

  Future<void> _initializeServices() async {
    try {
      // Get StorageService
      _storageService = Get.find<StorageService>();

      // Initialize AuthProvider if not already initialized
      if (!Get.isRegistered<AuthProvider>()) {
        Get.put(AuthProvider(), permanent: true);
      }

      // Initialize AuthService if not already initialized
      if (!Get.isRegistered<AuthService>()) {
        Get.put(AuthService(), permanent: true);
      }
      _authService = Get.find<AuthService>();

      // Initialize LocationService if not already initialized
      if (!Get.isRegistered<LocationService>()) {
        Get.put(LocationService(), permanent: true);
      }
      _locationService = Get.find<LocationService>();

      // Initialize UserLocationService if not already initialized
      if (!Get.isRegistered<UserLocationService>()) {
        Get.put(UserLocationService(), permanent: true);
      }
      _userLocationService = Get.find<UserLocationService>();

      debugPrint('All services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing services: $e');
      rethrow;
    }
  }

  Future<void> _initializeStorage() async {
    try {
      // Initialize storage keys if first launch
      if (_storageService.getBool('first_launch') ?? true) {
        await _initializeFirstLaunch();
      }
    } catch (e) {
      debugPrint('Error initializing storage: $e');
      rethrow;
    }
  }

  Future<void> _initializeFirstLaunch() async {
    await _storageService.saveBool('first_launch', false);
    await _storageService.saveMap('permissions', {
      'location': false,
      'storage': false,
      'notification': false,
    });
    await _storageService.saveMap('app_state', {
      'last_launch': DateTime.now().millisecondsSinceEpoch,
      'version': '1.0.0',
      'initialized': true,
    });
  }

  Future<void> _initializeLocationServices() async {
    try {
      // Initialize location service
      await _locationService.init();

      // Initialize user location service if location permission granted
      if (await Permission.location.isGranted) {
        await _userLocationService.loadUserLocations();
      }
    } catch (e) {
      debugPrint('Location service initialization error: $e');
      // Don't rethrow as location services are not critical
    }
  }

  Future<void> _requestInitialPermissions() async {
    final permissions = <Permission>[
      Permission.location,
      Permission.storage,
      Permission.notification,
    ];

    for (final permission in permissions) {
      if (await permission.status.isDenied) {
        _currentState.value = 'Requesting ${permission.toString()} Permission...';
        await permission.request();
      }
    }

    // Save permission states
    await _storageService.saveMap('permissions', {
      'location': await Permission.location.isGranted,
      'storage': await Permission.storage.isGranted,
      'notification': await Permission.notification.isGranted,
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        if (!status.isGranted) return;
      }

      await _storageService.saveMap('permissions', {
        ..._storageService.getMap('permissions') ?? {},
        'notification': true,
      });
    } catch (e) {
      debugPrint('Notification initialization error: $e');
    }
  }

  Future<void> _quickAuthCheck() async {
    final token = _storageService.getToken();
    final userData = _storageService.getUser();
    
    if (token != null && userData != null) {
      try {
        _authService.currentUser.value = UserModel.fromJson(userData);
        _authService.isLoggedIn.value = true;
      } catch (e) {
        debugPrint('Error in quick auth check: $e');
        await _storageService.clearAuth();
      }
    }
  }

  Future<void> _handleNavigation() async {
    try {
      if (_authService.isLoggedIn.value) {
        // Try auto login if remember me is enabled
        if (_storageService.getRememberMe()) {
          _currentState.value = 'Logging in...';
          await _tryAutoLogin();
        }
        Get.offAllNamed(Routes.userMainPage);
      } else {
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
      Get.offAllNamed(Routes.login);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _tryAutoLogin() async {
    try {
      final credentials = _storageService.getSavedCredentials();
      if (credentials != null) {
        await _authService.login(
          credentials['identifier']!,
          credentials['password']!,
          rememberMe: true,
          isAutoLogin: true,
          showError: false,
        );
      }
    } catch (e) {
      debugPrint('Auto login error: $e');
    }
  }

  void _handleError(dynamic error) {
    showCustomSnackbar(
      title: 'Error',
      message: 'Failed to initialize app: $error',
      isError: true,
    );
    Get.offAllNamed(Routes.login);
  }
}
