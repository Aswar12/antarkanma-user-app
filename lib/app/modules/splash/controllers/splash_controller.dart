import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';
import '../../../routes/app_pages.dart';
import '../../../data/models/user_model.dart';
import '../../../utils/location_permission_handler.dart';
import '../../../services/location_service.dart';
import '../../../services/fcm_token_service.dart';
import '../../../services/user_location_service.dart';

class SplashController extends GetxController {
  // State
  final RxBool _isLoading = true.obs;
  final RxString _currentState = 'Initializing...'.obs;
  bool get isLoading => _isLoading.value;
  String get currentState => _currentState.value;

  // Services
  late final AuthService _authService;
  late final StorageService _storageService;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _initializeApp();
  }

  void _initializeServices() {
    try {
      _authService = Get.find<AuthService>();
      _storageService = StorageService.instance;
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Check if this is first launch
      final isFirstLaunch = _storageService.getBool('first_launch') ?? true;
      
      if (isFirstLaunch) {
        _currentState.value = 'Requesting Permissions...';
        // Request initial permissions on first launch
        await _requestInitialPermissions();
        // Mark first launch complete
        await _storageService.saveBool('first_launch', false);
      }

      // Step 2: Check stored auth data
      _currentState.value = 'Checking Authentication...';
      await _checkStoredAuthData();

      // Step 3: Try auto login if needed
      if (!_authService.isLoggedIn.value) {
        await _tryAutoLogin();
      }

      // Step 4: If authenticated, initialize required services
      if (_authService.isLoggedIn.value) {
        _currentState.value = 'Loading User Data...';
        await _initializeAuthenticatedServices();
        
        // Navigate to main page
        Get.offAllNamed(Routes.userMainPage);
      } else {
        // Navigate to login
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      debugPrint('Error in splash controller: $e');
      Get.offAllNamed(Routes.login);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _checkStoredAuthData() async {
    try {
      final token = _storageService.getToken();
      final userData = _storageService.getUser();

      if (token != null && userData != null) {
        final isValid = await _authService.verifyToken(token);
        if (isValid) {
          try {
            _authService.currentUser.value = UserModel.fromJson(userData);
            _authService.isLoggedIn.value = true;
          } catch (e) {
            debugPrint('Error loading stored user data: $e');
            await _storageService.clearAuth();
          }
        } else {
          await _storageService.clearAuth();
        }
      }
    } catch (e) {
      debugPrint('Error checking stored auth data: $e');
      await _storageService.clearAuth();
    }
  }

  Future<void> _tryAutoLogin() async {
    try {
      if (_storageService.getRememberMe()) {
        _currentState.value = 'Attempting Auto-login...';
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
      }
    } catch (e) {
      debugPrint('Error in auto login: $e');
    }
  }

  Future<void> _initializeAuthenticatedServices() async {
    try {
      // Step 1: Update user profile
      _currentState.value = 'Updating Profile...';
      await _authService.getProfile(showError: false);

      // Step 2: Check and initialize location services
      _currentState.value = 'Checking Location Services...';
      if (await LocationPermissionHandler.handleLocationPermission()) {
        final locationService = Get.find<LocationService>();
        final userLocationService = Get.find<UserLocationService>();
        await locationService.getCurrentLocation();
      }
      
      // Step 3: Initialize FCM token
      _currentState.value = 'Initializing Notifications...';
      final fcmService = Get.find<FCMTokenService>();
      await fcmService.init();

    } catch (e) {
      debugPrint('Error initializing authenticated services: $e');
      // Don't rethrow - we want to continue even if some services fail
    }
  }

  Future<void> _requestInitialPermissions() async {
    try {
      // Request location permission
      if (await Permission.location.status.isDenied) {
        _currentState.value = 'Requesting Location Permission...';
        await LocationPermissionHandler.handleLocationPermission();
      }

      // Request storage permission
      if (await Permission.storage.status.isDenied) {
        _currentState.value = 'Requesting Storage Permission...';
        await Permission.storage.request();
      }

      // Save permission states
      await _storageService.saveMap('permissions', {
        'location': await Permission.location.isGranted,
        'storage': await Permission.storage.isGranted,
        'camera': await Permission.camera.isGranted,
        'notification': await Permission.notification.isGranted,
      });

    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }
}
