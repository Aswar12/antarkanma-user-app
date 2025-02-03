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
import '../data/providers/product_provider.dart';
import '../data/repositories/review_repository.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    print('Initializing core dependencies...');

    // Step 1: Initialize Storage Service (needed by other services)
    print('Initializing Storage Services...');
    Get.put(StorageService.instance, permanent: true);
    Get.put(TransactionCacheService(), permanent: true);

    // Step 2: Initialize Core Services in dependency order
    print('Initializing Core Services...');
    Get.put(AuthService(), permanent: true);
    Get.put(UserService(), permanent: true);
    Get.put(ProductService(), permanent: true);
    Get.put(CategoryService(), permanent: true);
    Get.put(TransactionService(), permanent: true);
    Get.put(UserLocationService(), permanent: true);
    Get.put(FCMTokenService(), permanent: true);
    Get.put(ImageService(), permanent: true);
    Get.put(NotificationService(), permanent: true);
    Get.put(OrderItemService(), permanent: true);
    Get.put(ProductCategoryService(), permanent: true);

    // Step 3: Initialize Core Providers and Repositories
    print('Initializing Providers and Repositories...');
    Get.put(ProductProvider(), permanent: true);
    Get.put(
      ReviewRepository(provider: Get.find<ProductProvider>()),
      permanent: true,
    );

    // Step 4: Initialize Core Controllers in dependency order
    print('Initializing Core Controllers...');
    
    // Auth and User controllers first
    Get.put(AuthController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(UserMainController(), permanent: true);
    
    // Location related controllers
    Get.put(
      UserLocationController(
        locationService: Get.find<UserLocationService>(),
      ),
      permanent: true,
    );
    Get.put(MapPickerController(), permanent: true);
    
    // Product related controllers
    Get.put(ProductController(), permanent: true);
    Get.put(CategoryController(), permanent: true);
    Get.put(ProductDetailController(
      reviewRepository: Get.find<ReviewRepository>(),
    ), permanent: true);
    
    // Cart and Order controllers
    Get.put(CartController(), permanent: true);
    Get.put(OrderController(), permanent: true);
    Get.put(
      CheckoutController(
        userLocationController: Get.find<UserLocationController>(),
        authController: Get.find<AuthController>(),
      ),
      permanent: true,
    );
    
    // Homepage controller last as it might depend on other controllers
    Get.put(HomePageController(), permanent: true);

    print('Core dependencies initialization complete');
  }
}
