import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/modules/user/controllers/edit_profile_controller.dart';
import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/data/providers/product_provider.dart';
import 'package:antarkanma/app/data/repositories/review_repository.dart';
import 'package:antarkanma/app/controllers/checkout_controller.dart';
import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/controllers/map_picker_controller.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/controllers/product_detail_controller.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:antarkanma/app/services/user_location_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/user_controller.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
    print('Initializing UserBinding dependencies...');

    // Initialize core services first
    if (!Get.isRegistered<AuthService>()) {
      print('Initializing AuthService...');
      Get.put(AuthService(), permanent: true);
    }

    // Initialize AuthController after AuthService
    if (!Get.isRegistered<AuthController>()) {
      print('Initializing AuthController...');
      Get.put(AuthController(), permanent: true);
    }

    if (!Get.isRegistered<CategoryService>()) {
      print('Initializing CategoryService...');
      Get.put(CategoryService(), permanent: true);
    }

    if (!Get.isRegistered<ProductService>()) {
      print('Initializing ProductService...');
      Get.put(ProductService(), permanent: true);
    }

    // Initialize location services
    print('Initializing Location Services...');
    Get.lazyPut<UserLocationService>(
      () => UserLocationService(),
      fenix: true,
    );

    Get.lazyPut<UserLocationController>(
      () => UserLocationController(
        locationService: Get.find<UserLocationService>(),
      ),
      fenix: true,
    );

    // Initialize CheckoutController with its dependencies
    Get.lazyPut<CheckoutController>(
      () => CheckoutController(
        userLocationController: Get.find<UserLocationController>(),
        authController: Get.find<AuthController>(),
      ),
      fenix: true,
    );

    // Main Controllers
    Get.lazyPut<UserController>(() => UserController());
    Get.lazyPut<UserMainController>(() => UserMainController());

    // Cart Controller (permanent instance)
    if (!Get.isRegistered<CartController>()) {
      print('Initializing CartController...');
      Get.put(CartController(), permanent: true);
    }

    // Providers and Repositories
    print('Initializing ProductProvider...');
    Get.lazyPut(() => ProductProvider(), fenix: true);
    print('Initializing ReviewRepository...');
    Get.lazyPut(() => ReviewRepository(provider: Get.find()), fenix: true);

    // Initialize HomePageController if not already initialized
    if (!Get.isRegistered<HomePageController>()) {
      print('Initializing HomePageController...');
      Get.put(HomePageController(), permanent: true);
    } else {
      print('HomePageController already initialized');
      // Ensure data is loaded
      final homeController = Get.find<HomePageController>();
      if (homeController.allProducts.isEmpty) {
        homeController.loadInitialData();
      }
    }

    // Product Detail Controller
    print('Initializing ProductDetailController...');
    Get.lazyPut<ProductDetailController>(
      () => ProductDetailController(reviewRepository: Get.find()),
      fenix: true,
    );

    // Ensure CartController is initialized
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController(), permanent: true);
    }

    // Initialize UserLocationController if not already initialized
    if (!Get.isRegistered<UserLocationController>()) {
      Get.put(
          UserLocationController(
            locationService: Get.find<UserLocationService>(),
          ),
          permanent: true);
    }

    // Ensure OrderController is initialized
    if (!Get.isRegistered<OrderController>()) {
      Get.put(OrderController(), permanent: true);
    }

    Get.lazyPut<MapPickerController>(() => MapPickerController());

    // Transaction and Order Related Dependencies
    print('Initializing Transaction Services...');
    Get.lazyPut(() => TransactionService(), fenix: true);

    // Additional Feature Controllers
    _initializeFeatureControllers();

    print('UserBinding dependencies initialization complete');
  }

  void _initializeFeatureControllers() {
    print('Initializing Feature Controllers...');
    Get.lazyPut(() => EditProfileController(), fenix: true);
  }
}
