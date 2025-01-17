import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../services/product_service.dart';
import '../../../services/category_service.dart';
import '../../../services/storage_service.dart';
import '../../../routes/app_pages.dart';
import '../../../controllers/homepage_controller.dart';
import '../../../data/models/user_model.dart';

class SplashController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ProductService _productService = Get.find<ProductService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final StorageService _storageService = StorageService.instance;
  
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
      await Future.delayed(const Duration(seconds: 1));

      _loadingText.value = 'Memeriksa status login...';
      
      // First check if remember me is enabled
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
            await _loadUserData();
            _isLoading.value = false;
            await Future.delayed(const Duration(seconds: 1));
            Get.offAllNamed(Routes.userMainPage);
            return;
          }
        }
      }

      // If auto-login failed or not enabled, check for valid token
      final token = _storageService.getToken();
      final userData = _storageService.getUser();
      
      if (token != null && userData != null) {
        // Try to verify token
        final isValid = await _authService.verifyToken(token);
        if (isValid) {
          _loadingText.value = 'Memuat data user...';
          _authService.currentUser.value = UserModel.fromJson(userData);
          _authService.isLoggedIn.value = true;
          await _loadUserData();
          _isLoading.value = false;
          await Future.delayed(const Duration(seconds: 1));
          Get.offAllNamed(Routes.userMainPage);
          return;
        }
      }

      // If we reach here, no valid auth was found
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed(Routes.login);
      
    } catch (e) {
      print('Error in splash controller: $e');
      Get.offAllNamed(Routes.login);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadUserData() async {
    _loadingText.value = 'Memuat data kategori...';
    await _categoryService.getCategories();

    _loadingText.value = 'Memuat data produk populer...';
    if (!Get.isRegistered<HomePageController>()) {
      final homeController = HomePageController();
      Get.put(homeController, permanent: true);
    }
    final homeController = Get.find<HomePageController>();

    await homeController.loadPopularProducts();

    if (homeController.popularProducts.isEmpty) {
      print('Warning: No popular products loaded');
      _loadingText.value = 'Mencoba memuat ulang data produk...';
      await homeController.refreshProducts(showMessage: false);
    }
  }
}
