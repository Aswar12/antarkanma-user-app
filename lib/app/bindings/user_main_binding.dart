import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/controllers/user_controller.dart';
import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/services/location_service.dart';
import 'package:antarkanma/app/services/user_location_service.dart';
import 'package:antarkanma/app/services/user_service.dart';
import 'package:antarkanma/app/services/image_service.dart';
import 'package:antarkanma/app/data/providers/merchant_provider.dart';
import 'package:antarkanma/app/data/providers/product_category_provider.dart';

class UserMainBinding implements Bindings {
  @override
  void dependencies() {
    // Initialize storage
    Get.put(GetStorage(), permanent: true);
    
    // Initialize providers first
    Get.put(MerchantProvider(), permanent: true);
    Get.put(ProductCategoryProvider(), permanent: true);
    
    // Initialize base services that don't depend on other services
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService.instance, permanent: true);
    }
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService(), permanent: true);
    }
    Get.put(UserService(), permanent: true);
    Get.lazyPut(() => ImageService(), fenix: true);
    
    // Initialize location services in correct order
    if (!Get.isRegistered<LocationService>()) {
      Get.put(LocationService(), permanent: true);
    }
    
    // Ensure UserLocationService dependencies are ready
    try {
      Get.find<StorageService>();
      Get.find<AuthService>();
      if (!Get.isRegistered<UserLocationService>()) {
        Get.put(UserLocationService(), permanent: true);
      }
    } catch (e) {
      debugPrint('Error initializing UserLocationService dependencies: $e');
      rethrow;
    }
    
    // Initialize services that depend on providers and base services
    Get.lazyPut(() => MerchantService(), fenix: true);
    Get.lazyPut(() => ProductService(), fenix: true);
    Get.lazyPut(() => CategoryService(), fenix: true);
    Get.lazyPut(() => TransactionService(), fenix: true);
    
    // Initialize controllers
    Get.put(AuthController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(UserLocationController(
      locationService: Get.find<UserLocationService>()
    ), permanent: true);
    Get.put(HomePageController(), permanent: true);
    Get.put(UserMainController(), permanent: true);
    Get.put(CartController(), permanent: true); // Added CartController
  }
}
