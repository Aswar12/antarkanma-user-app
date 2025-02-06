import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/category_controller.dart';
import '../controllers/homepage_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/user_location_controller.dart';
import '../controllers/user_main_controller.dart';
import '../data/providers/category_provider.dart';
import '../data/providers/merchant_provider.dart';
import '../data/providers/notification_provider.dart';
import '../data/providers/product_provider.dart';
import '../data/providers/shipping_provider.dart';
import '../data/repositories/review_repository.dart';
import '../services/category_service.dart';
import '../services/fcm_token_service.dart';
import '../services/image_service.dart';
import '../services/location_service.dart';
import '../services/merchant_service.dart';
import '../services/notification_service.dart';
import '../services/order_item_service.dart';
import '../services/product_category_service.dart';
import '../services/product_service.dart';
import '../services/shipping_service.dart';
import '../services/transaction_cache_service.dart';
import '../services/transaction_service.dart';
import '../services/user_location_service.dart';
import '../services/user_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('Initializing App Services...');

    // Register all services as lazy load
    _registerCoreServices();
    _registerProviders();
    _registerFeatureServices();
    _registerControllers();
  }

  void _registerCoreServices() {
    // Core services that other services might depend on
    Get.lazyPut(() => TransactionCacheService(), fenix: true);
    Get.lazyPut(() => UserService(), fenix: true);
    Get.lazyPut(() => LocationService(), fenix: true);
    Get.lazyPut(() => UserLocationService(), fenix: true);
    Get.lazyPut(() => FCMTokenService(), fenix: true);
    Get.lazyPut(() => NotificationService(), fenix: true);
    Get.lazyPut(() => ImageService(), fenix: true);
  }

  void _registerProviders() {
    // Data providers
    Get.lazyPut(() => NotificationProvider(), fenix: true);
    Get.lazyPut(() => ProductProvider(), fenix: true);
    Get.lazyPut(() => MerchantProvider(), fenix: true);
    Get.lazyPut(() => ShippingProvider(), fenix: true);
    Get.lazyPut(() => CategoryProvider(), fenix: true);
    Get.lazyPut(() => ReviewRepository(provider: Get.find<ProductProvider>()), fenix: true);
  }

  void _registerFeatureServices() {
    // Feature-specific services
    Get.lazyPut(() => TransactionService(), fenix: true);
    Get.lazyPut(() => OrderItemService(), fenix: true);
    Get.lazyPut(() => CategoryService(), fenix: true);
    Get.lazyPut(() => ProductService(), fenix: true);
    Get.lazyPut(() => ProductCategoryService(), fenix: true);
    Get.lazyPut(() => MerchantService(), fenix: true);
    Get.lazyPut(() => ShippingService(), fenix: true);
  }

  void _registerControllers() {
    // Core controllers
    Get.lazyPut(() => AuthController(), fenix: true);
    Get.lazyPut(() => UserController(), fenix: true);
    Get.lazyPut(() => UserLocationController(locationService: Get.find()), fenix: true);
    
    // Feature controllers
    Get.lazyPut(() => CartController(), fenix: true);
    Get.lazyPut(() => OrderController(), fenix: true);
    Get.lazyPut(() => ProductController(), fenix: true);
    Get.lazyPut(() => CategoryController(), fenix: true);
    Get.lazyPut(() => HomePageController(), fenix: true);
    Get.lazyPut(() => UserMainController(), fenix: true);
  }
}
