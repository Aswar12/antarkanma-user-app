import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/controllers/checkout_controller.dart';
import 'package:antarkanma/app/data/providers/shipping_provider.dart';
import 'package:antarkanma/app/services/image_service.dart';
import 'package:antarkanma/app/services/shipping_service.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/homepage_controller.dart';
import '../controllers/user_main_controller.dart';
import '../controllers/user_location_controller.dart';
import '../modules/splash/controllers/splash_controller.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/merchant_service.dart';
import '../services/category_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/user_location_service.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/merchant_provider.dart';
import '../data/providers/product_category_provider.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    // Image Service
    Get.put(ImageService(), permanent: true);
    Get.put(AuthProvider(), permanent: true);
    Get.put(MerchantProvider(), permanent: true);
    Get.put(ProductCategoryProvider(), permanent: true);

    // Core Storage Service (needed by Auth)
    Get.put(StorageService.instance, permanent: true);

    // Auth Service and its dependencies
    Get.put(AuthService(), permanent: true);

    // Core Controllers - Initialize first
    Get.put(AuthController(), permanent: true);
    
    // Basic Location Service (doesn't require auth)
    Get.put(LocationService(), permanent: true);
    
    // Auth-dependent services will be initialized by AuthController after successful auth
    Get.lazyPut(() => UserLocationService(), fenix: true);
    Get.lazyPut(() => ShippingProvider(), fenix: true);
    Get.lazyPut(() => ProductService(), fenix: true);
    Get.lazyPut(() => MerchantService(), fenix: true);
    Get.lazyPut(() => CategoryService(), fenix: true);
    Get.lazyPut(() => ShippingService(), fenix: true);
    Get.lazyPut(() => TransactionService(), fenix: true);
    Get.lazyPut(() => CartController(), fenix: true);
    
    // Other Controllers
    Get.put(SplashController(), permanent: true);
    Get.put(HomePageController(), permanent: true);
    Get.put(UserMainController(), permanent: true);
    Get.lazyPut(() => UserLocationController(), fenix: true);
    Get.lazyPut(() => CheckoutController(
      userLocationController: Get.find<UserLocationController>(),
      authController: Get.find<AuthController>(),
      cartController: Get.find<CartController>(),
      shippingService: Get.find<ShippingService>(),
      transactionService: Get.find<TransactionService>(),
    ), fenix: true);
  }
}
