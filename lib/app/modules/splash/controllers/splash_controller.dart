import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../../services/auth_service.dart';
import '../../../services/merchant_service.dart';
import '../../../services/category_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/location_service.dart';
import '../../../routes/app_pages.dart';
import '../../../controllers/homepage_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../utils/location_permission_handler.dart';

class SplashController extends GetxController {
  // State
  final RxBool _isLoading = true.obs;
  final RxString _loadingText = 'Mempersiapkan aplikasi...'.obs;

  bool get isLoading => _isLoading.value;
  String get loadingText => _loadingText.value;

  // Services
  late final AuthService _authService;
  late final CategoryService _categoryService;
  late final StorageService _storageService;
  late final LocationService _locationService;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _initializeApp();
  }

  void _initializeServices() {
    try {
      _authService = Get.find<AuthService>();
      _categoryService = Get.find<CategoryService>();
      _storageService = StorageService.instance;
      _locationService = Get.find<LocationService>();
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Load initial data first
      await _loadInitialData();

      // Then check authentication
      await _checkAuthentication();

      await Future.delayed(const Duration(seconds: 2));

      if (_authService.isLoggedIn.value) {
        Get.offAllNamed(Routes.userMainPage);
      } else {
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      debugPrint('Error in splash controller: $e');
      Get.offAllNamed(Routes.login);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadInitialData() async {
    try {
      _loadingText.value = 'Mendapatkan lokasi...';
      await _getCurrentLocation();

      _loadingText.value = 'Memuat data kategori...';
      await _categoryService.getCategories();

      _loadingText.value = 'Memuat data produk populer...';
      final homeController = Get.find<HomePageController>();
      await homeController.loadPopularProducts();

      _loadingText.value = 'Memuat daftar merchant...';
      await homeController.loadAllMerchants();
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  Future<void> _requestInitialPermissions() async {
    try {
      _loadingText.value = 'Memeriksa izin aplikasi...';
      await LocationPermissionHandler.handleLocationPermission();
      await _requestDataPermissions();
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  Future<void> _requestDataPermissions() async {
    if (await Permission.storage.status.isDenied) {
      _loadingText.value = 'Meminta izin akses penyimpanan...';
      await Permission.storage.request();
    }

    if (await Permission.photos.status.isDenied) {
      _loadingText.value = 'Meminta izin akses foto...';
      await Permission.photos.request();
    }

    if (await Permission.camera.status.isDenied) {
      _loadingText.value = 'Meminta izin akses kamera...';
      await Permission.camera.request();
    }

    if (await Permission.storage.isPermanentlyDenied ||
        await Permission.photos.isPermanentlyDenied ||
        await Permission.camera.isPermanentlyDenied) {
      final bool? openSettings = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Izin Diperlukan'),
          content: const Text(
              'Beberapa izin diperlukan untuk menggunakan fitur aplikasi ini. '
              'Buka pengaturan untuk mengaktifkan izin yang diperlukan?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('BATAL'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('PENGATURAN'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (openSettings == true) {
        await openAppSettings();
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool hasPermission =
          await LocationPermissionHandler.handleLocationPermission();
      if (!hasPermission) {
        debugPrint('Location permission not granted');
        return;
      }

      await _locationService.getCurrentLocation();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _checkAuthentication() async {
    try {
      _loadingText.value = 'Memeriksa status login...';

      // First try auto-login if remember me is enabled
      if (_storageService.getRememberMe()) {
        final credentials = _storageService.getSavedCredentials();
        if (credentials != null) {
          _loadingText.value = 'Melakukan auto login...';
          final success = await _authService.login(
            credentials['identifier']!,
            credentials['password']!,
            rememberMe: true,
            isAutoLogin: true,
            showError: false,
          );

          if (success) {
            debugPrint('Auto-login successful');
            return;
          }
        }
      }

      // If auto-login fails or not enabled, try token-based auth
      final token = _storageService.getToken();
      final userData = _storageService.getUser();

      if (token != null && userData != null) {
        final isValid = await _authService.verifyToken(token);
        if (isValid) {
          _loadingText.value = 'Memuat data user...';
          try {
            // Try to create UserModel from stored data first
            _authService.currentUser.value = UserModel.fromJson(userData);
            _authService.isLoggedIn.value = true;

            // Then silently update profile in background
            _authService.getProfile(showError: false).then((user) {
              if (user != null) {
                _authService.currentUser.value = user;
              }
            }).catchError((e) {
              debugPrint('Error updating profile in background: $e');
            });
          } catch (e) {
            debugPrint('Error loading stored user data: $e');
            await _storageService.clearAuth();
            _authService.isLoggedIn.value = false;
            _authService.currentUser.value = null;
          }
        } else {
          await _storageService.clearAuth();
        }
      }
    } catch (e) {
      debugPrint('Error checking authentication: $e');
      await _storageService.clearAuth();
    }
  }
}
