import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../services/transaction_service.dart';
import '../services/user_location_service.dart';
import '../services/storage_service.dart';
import '../services/fcm_token_service.dart';
import '../services/image_service.dart';
import '../services/notification_service.dart';
import '../services/order_item_service.dart';
import '../services/product_category_service.dart';
import '../services/merchant_service.dart';
import '../services/location_service.dart';
import '../services/transaction_cache_service.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/homepage_controller.dart';
import '../controllers/map_picker_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/product_detail_controller.dart';
import '../controllers/user_location_controller.dart';
import '../controllers/user_main_controller.dart';
import '../modules/splash/controllers/splash_controller.dart';
import '../data/providers/product_provider.dart';
import '../data/providers/merchant_provider.dart';
import '../data/repositories/review_repository.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    _initializeStorageServices();
    _initializeProviders();
    _initializeTransactionServices();
    _initializeCoreServices();
    _initializeUserServices();
    _initializeControllers();
  }

  void _initializeStorageServices() {
    debugPrint('Initializing Storage Services...');
    // Core storage services
    Get.put(StorageService.instance, permanent: true);
    Get.put(TransactionCacheService(), permanent: true);
  }

  void _initializeProviders() {
    debugPrint('Initializing Providers...');
    // Data providers
    Get.put(ProductProvider(), permanent: true);
    Get.put(MerchantProvider(), permanent: true);
    Get.put(ReviewRepository(provider: Get.find<ProductProvider>()), permanent: true);
  }

  void _initializeTransactionServices() {
    debugPrint('Initializing Transaction Services...');
    // Initialize TransactionService before NotificationService
    Get.put(TransactionService(), permanent: true);
    Get.put(OrderItemService(), permanent: true);
  }

  void _initializeCoreServices() {
    debugPrint('Initializing Core Services...');
    // Authentication & User Management
    Get.put(AuthService(), permanent: true);
    Get.put(UserService(), permanent: true);
    
    // Location Services
    Get.put(LocationService(), permanent: true);
    Get.put(UserLocationService(), permanent: true);
    
    // Communication Services
    Get.put(FCMTokenService(), permanent: true);
    Get.put(ImageService(), permanent: true);
    
    // Initialize NotificationService after TransactionService
    Get.put(NotificationService(), permanent: true);

    // Category Service needed by SplashController
    Get.put(CategoryService(), permanent: true);
  }

  void _initializeUserServices() {
    debugPrint('Initializing User Services...');
    // Product & Category Services
    Get.put(ProductService(), permanent: true);
    Get.put(ProductCategoryService(), permanent: true);
    Get.put(MerchantService(), permanent: true);
  }

  void _initializeControllers() {
    debugPrint('Initializing Controllers...');
    // Initialize HomePage controller first since SplashController depends on it
    Get.put(HomePageController(), permanent: true);
    
    // Initialize SplashController
    Get.put(SplashController(), permanent: true);
    
    // User Profile Controllers
    Get.put(AuthController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(UserMainController(), permanent: true);
    
    // Location Controllers
    Get.put(
      UserLocationController(locationService: Get.find<UserLocationService>()),
      permanent: true,
    );
    Get.put(MapPickerController(), permanent: true);
    
    // Shopping Controllers
    Get.put(ProductController(), permanent: true);
    Get.put(CategoryController(), permanent: true);
    // ProductDetailController will be initialized per-use instead of permanent
    Get.lazyPut(
      () => ProductDetailController(reviewRepository: Get.find<ReviewRepository>()),
      fenix: true,
    );
    
    // Cart & Checkout Controllers
    Get.put(CartController(), permanent: true);
    Get.put(OrderController(), permanent: true);
    Get.put(
      CheckoutController(
        userLocationController: Get.find<UserLocationController>(),
        authController: Get.find<AuthController>(),
      ),
      permanent: true,
    );

    debugPrint('All dependencies initialized successfully');
  }
}
