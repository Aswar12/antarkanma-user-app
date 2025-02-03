import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/controllers/checkout_controller.dart';
import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/controllers/map_picker_controller.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/controllers/product_detail_controller.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/controllers/user_controller.dart';
import 'package:antarkanma/app/controllers/category_controller.dart';
import 'package:antarkanma/app/controllers/product_controller.dart';
import 'package:antarkanma/app/data/providers/product_provider.dart';
import 'package:antarkanma/app/data/repositories/review_repository.dart';
import 'package:antarkanma/app/services/user_location_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:antarkanma/app/services/notification_service.dart';
import 'package:antarkanma/app/services/fcm_token_service.dart';
import 'package:antarkanma/app/services/image_service.dart';
import 'package:antarkanma/app/services/order_item_service.dart';
import 'package:antarkanma/app/services/product_category_service.dart';
import 'package:antarkanma/app/services/transaction_cache_service.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
    print('Initializing UserBinding dependencies...');

    // Step 1: Initialize Storage and Core Services
    _initializeStorageAndCoreServices();

    // Step 2: Initialize Providers and Repositories
    _initializeProvidersAndRepositories();

    // Step 3: Initialize Core Controllers
    _initializeCoreControllers();

    // Step 4: Initialize Feature Controllers
    _initializeFeatureControllers();

    print('UserBinding dependencies initialization complete');
  }

  void _initializeStorageAndCoreServices() {
    // Storage Service (needed by other services)
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService.instance, permanent: true);
    }

    // Core Services
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService(), permanent: true);
    }
    if (!Get.isRegistered<UserLocationService>()) {
      Get.put(UserLocationService(), permanent: true);
    }
    if (!Get.isRegistered<ProductService>()) {
      Get.put(ProductService(), permanent: true);
    }
    if (!Get.isRegistered<CategoryService>()) {
      Get.put(CategoryService(), permanent: true);
    }
    if (!Get.isRegistered<TransactionService>()) {
      Get.put(TransactionService(), permanent: true);
    }
    if (!Get.isRegistered<NotificationService>()) {
      Get.put(NotificationService(), permanent: true);
    }
    if (!Get.isRegistered<FCMTokenService>()) {
      Get.put(FCMTokenService(), permanent: true);
    }
    if (!Get.isRegistered<ImageService>()) {
      Get.put(ImageService(), permanent: true);
    }
    if (!Get.isRegistered<OrderItemService>()) {
      Get.put(OrderItemService(), permanent: true);
    }
    if (!Get.isRegistered<ProductCategoryService>()) {
      Get.put(ProductCategoryService(), permanent: true);
    }
    if (!Get.isRegistered<TransactionCacheService>()) {
      Get.put(TransactionCacheService(), permanent: true);
    }
  }

  void _initializeProvidersAndRepositories() {
    // Providers
    if (!Get.isRegistered<ProductProvider>()) {
      Get.put(ProductProvider(), permanent: true);
    }

    // Repositories
    if (!Get.isRegistered<ReviewRepository>()) {
      Get.put(
        ReviewRepository(provider: Get.find<ProductProvider>()),
        permanent: true,
      );
    }
  }

  void _initializeCoreControllers() {
    // Auth and User Controllers
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController(), permanent: true);
    }
    if (!Get.isRegistered<UserMainController>()) {
      Get.put(UserMainController(), permanent: true);
    }

    // Location Controller
    if (!Get.isRegistered<UserLocationController>()) {
      Get.put(
        UserLocationController(
          locationService: Get.find<UserLocationService>(),
        ),
        permanent: true,
      );
    }

    // Cart Controller - Must be initialized before CheckoutController
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController(), permanent: true);
    }
  }

  void _initializeFeatureControllers() {
    // Product Related Controllers
    if (!Get.isRegistered<ProductController>()) {
      Get.put(ProductController(), permanent: true);
    }
    if (!Get.isRegistered<CategoryController>()) {
      Get.put(CategoryController(), permanent: true);
    }
    if (!Get.isRegistered<ProductDetailController>()) {
      Get.put(
        ProductDetailController(
          reviewRepository: Get.find<ReviewRepository>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<HomePageController>()) {
      Get.put(HomePageController(), permanent: true);
    }

    // Order and Checkout Controllers
    if (!Get.isRegistered<OrderController>()) {
      Get.put(OrderController(), permanent: true);
    }

    // Important: Remove existing CheckoutController instance if it exists
    if (Get.isRegistered<CheckoutController>()) {
      Get.delete<CheckoutController>();
    }
    
    // Create new CheckoutController instance with lazy initialization
    Get.lazyPut<CheckoutController>(
      () => CheckoutController(
        userLocationController: Get.find<UserLocationController>(),
        authController: Get.find<AuthController>(),
      ),
      fenix: true, // This allows recreation when needed
    );

    // Map Controller
    if (!Get.isRegistered<MapPickerController>()) {
      Get.put(MapPickerController(), permanent: true);
    }
  }
}
