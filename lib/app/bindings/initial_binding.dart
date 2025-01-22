import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_controller.dart';
import '../controllers/user_main_controller.dart';
import '../controllers/homepage_controller.dart';
import '../modules/splash/controllers/splash_controller.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';
import '../services/notification_service.dart';
import '../services/fcm_token_service.dart';
import '../services/image_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    debugPrint('Initializing dependencies...');

    // Services - Order matters due to dependencies
    debugPrint('Initializing AuthService...');
    Get.put(AuthService(), permanent: true);

    debugPrint('Initializing TransactionService...');
    Get.put(TransactionService(), permanent: true);

    debugPrint('Initializing FCMTokenService...');
    Get.putAsync(() => FCMTokenService().init(), permanent: true);

    debugPrint('Initializing NotificationService...');
    Get.putAsync(() => NotificationService().init(), permanent: true);

    debugPrint('Initializing ImageService...');
    Get.putAsync(() => ImageService().init(), permanent: true);

    debugPrint('Initializing CategoryService...');
    Get.put(CategoryService(), permanent: true);

    debugPrint('Initializing ProductService...');
    Get.put(ProductService(), permanent: true);

    // Controllers - Initialize core controllers first
    debugPrint('Initializing AuthController...');
    Get.put(AuthController(), permanent: true);

    debugPrint('Initializing UserController...');
    Get.lazyPut(() => UserController());

    debugPrint('Initializing UserMainController...');
    Get.put(UserMainController(), permanent: true);

    // Initialize HomePageController after its dependencies
    debugPrint('Initializing HomePageController...');
    if (!Get.isRegistered<HomePageController>()) {
      Get.put(HomePageController(), permanent: true);
    }

    // Initialize SplashController last since it depends on other controllers
    debugPrint('Initializing SplashController...');
    Get.put(SplashController(), permanent: true);

    debugPrint('Dependencies initialization complete');
  }
}
