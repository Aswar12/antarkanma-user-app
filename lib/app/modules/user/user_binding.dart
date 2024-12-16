import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/controllers/checkout_controller.dart';
import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/controllers/map_picker_controller.dart';
import 'package:antarkanma/app/controllers/product_detail_controller.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:antarkanma/app/services/user_location_service.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/user_controller.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
    // Main Controllers
    Get.lazyPut<UserController>(() => UserController());
    Get.lazyPut<UserMainController>(() => UserMainController());

    // Cart Controller (permanent instance)
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController(), permanent: true);
    }

    // Home and Product Controllers
    Get.lazyPut<HomePageController>(() => HomePageController(Get.find()));
    Get.lazyPut<ProductDetailController>(() => ProductDetailController());

    // Location Related Dependencies
    Get.lazyPut<UserLocationService>(
      () => UserLocationService(),
      fenix: true,
    );
    Get.lazyPut<MapPickerController>(() => MapPickerController());
    Get.lazyPut<UserLocationController>(
      () => UserLocationController(
        locationService: Get.find<UserLocationService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<CheckoutController>(
      () => CheckoutController(
        userLocationController: Get.find<UserLocationController>(),
        authController: Get.find<AuthController>(),
      ),
    );
    Get.lazyPut(() => TransactionService());
    // Additional Feature Controllers
    _initializeFeatureControllers();
  }

  void _initializeFeatureControllers() {
    // Uncomment and add these as needed
    // Get.lazyPut<ProfileController>(() => ProfileController());
    // Get.lazyPut<ChatController>(() => ChatController());
    // Get.lazyPut<OrderController>(() => OrderController());
  }
}
