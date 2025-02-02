import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/auth_service.dart';
import '../../../services/product_service.dart';
import '../../../services/category_service.dart';
import '../../../services/storage_service.dart';
import '../../../routes/app_pages.dart';
import '../../../controllers/homepage_controller.dart';
import '../../../data/models/user_model.dart';
import '../../../utils/location_permission_handler.dart';

class SplashController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ProductService _productService = Get.find<ProductService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final StorageService _storageService = StorageService.instance;
  final HomePageController _homeController = Get.find<HomePageController>();
  
  final RxBool _isLoading = true.obs;
  final RxString _loadingText = 'Mempersiapkan aplikasi...'.obs;

  bool get isLoading => _isLoading.value;
  String get loadingText => _loadingText.value;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Request permissions first
      await _requestInitialPermissions();

      // Start loading data and checking auth in parallel
      await Future.wait([
        _loadInitialData(),
        _checkAuthentication(),
      ], eagerError: false); // Set to false to continue even if one fails

      // Wait a minimum of 2 seconds for splash screen
      await Future.delayed(const Duration(seconds: 2));
      
      if (_authService.isLoggedIn.value) {
        Get.offAllNamed(Routes.userMainPage);
      } else {
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      print('Error in splash controller: $e');
      // Even if there's an error, proceed to login
      Get.offAllNamed(Routes.login);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _requestInitialPermissions() async {
    try {
      _loadingText.value = 'Memeriksa izin aplikasi...';

      // Request location permission
      await LocationPermissionHandler.handleLocationPermission();
      
      // Request other permissions
      await _requestDataPermissions();

    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }

  Future<void> _requestDataPermissions() async {
    // Request storage permission
    if (await Permission.storage.status.isDenied) {
      _loadingText.value = 'Meminta izin akses penyimpanan...';
      await Permission.storage.request();
    }

    // Request photos permission (for profile picture, etc)
    if (await Permission.photos.status.isDenied) {
      _loadingText.value = 'Meminta izin akses foto...';
      await Permission.photos.request();
    }

    // Request camera permission
    if (await Permission.camera.status.isDenied) {
      _loadingText.value = 'Meminta izin akses kamera...';
      await Permission.camera.request();
    }

    // If any permission is permanently denied, show settings dialog
    if (await Permission.storage.isPermanentlyDenied ||
        await Permission.photos.isPermanentlyDenied ||
        await Permission.camera.isPermanentlyDenied) {
      final bool? openSettings = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Izin Diperlukan'),
          content: const Text(
            'Beberapa izin diperlukan untuk menggunakan fitur aplikasi ini. '
            'Buka pengaturan untuk mengaktifkan izin yang diperlukan?'
          ),
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

  Future<void> _loadInitialData() async {
    try {
      _loadingText.value = 'Memuat data kategori...';
      await _categoryService.getCategories();

      _loadingText.value = 'Memuat data produk...';
      await _homeController.loadInitialData();

      if (_homeController.popularProducts.isEmpty) {
        _loadingText.value = 'Mencoba memuat ulang data produk...';
        await _homeController.refreshProducts(showMessage: false);
      }
    } catch (e) {
      print('Error loading initial data: $e');
      // Continue execution even if data loading fails
      // The user can refresh later if needed
    }
  }

  Future<void> _checkAuthentication() async {
    try {
      _loadingText.value = 'Memeriksa status login...';
      
      // Check remember me first
      if (_storageService.getRememberMe()) {
        final credentials = _storageService.getSavedCredentials();
        if (credentials != null) {
          _loadingText.value = 'Melakukan auto login...';
          final success = await _authService.login(
            credentials['identifier']!,
            credentials['password']!,
            rememberMe: true,
            isAutoLogin: true,
          );
          
          if (success) {
            print('Auto-login successful');
            return;
          }
        }
      }

      // If auto-login failed, check token
      final token = _storageService.getToken();
      final userData = _storageService.getUser();
      
      if (token != null && userData != null) {
        final isValid = await _authService.verifyToken(token);
        if (isValid) {
          _loadingText.value = 'Memuat data user...';
          _authService.currentUser.value = UserModel.fromJson(userData);
          _authService.isLoggedIn.value = true;
        }
      }
    } catch (e) {
      print('Error checking authentication: $e');
      // Continue execution even if auth check fails
      // User will be redirected to login
    }
  }
}
