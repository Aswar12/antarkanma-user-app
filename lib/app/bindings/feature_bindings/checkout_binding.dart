import 'package:get/get.dart';
import '../../controllers/checkout_controller.dart';
import '../../controllers/user_location_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/order_controller.dart';
import '../../controllers/user_main_controller.dart';
import '../../services/shipping_service.dart';
import '../../services/location_service.dart';
import '../../services/merchant_service.dart';
import '../../services/transaction_service.dart';
import '../../services/user_location_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/shipping_provider.dart';

class CheckoutBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure core services are available
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService.instance, permanent: true);
    }

    // Initialize Auth dependencies if not already initialized
    if (!Get.isRegistered<AuthProvider>()) {
      Get.put(AuthProvider(), permanent: true);
    }
    if (!Get.isRegistered<AuthService>()) {
      Get.put(AuthService(), permanent: true);
    }
    if (!Get.isRegistered<UserService>()) {
      Get.put(UserService(), permanent: true);
    }
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }

    // Put all required services if not already registered
    if (!Get.isRegistered<ShippingProvider>()) {
      Get.put(ShippingProvider(), permanent: true);
    }
    if (!Get.isRegistered<LocationService>()) {
      Get.put(LocationService(), permanent: true);
    }
    if (!Get.isRegistered<UserLocationService>()) {
      Get.put(UserLocationService(), permanent: true);
    }
    if (!Get.isRegistered<ShippingService>()) {
      Get.put(ShippingService(), permanent: true);
    }
    if (!Get.isRegistered<MerchantService>()) {
      Get.put(MerchantService(), permanent: true);
    }
    if (!Get.isRegistered<TransactionService>()) {
      Get.put(TransactionService(), permanent: true);
    }

    // Put all required controllers if not already registered
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController(), permanent: true);
    }
    if (!Get.isRegistered<OrderController>()) {
      Get.put(OrderController(), permanent: true);
    }
    if (!Get.isRegistered<UserLocationController>()) {
      Get.put(
        UserLocationController(
          locationService: Get.find<UserLocationService>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<UserMainController>()) {
      Get.put(UserMainController(), permanent: true);
    }

    // Finally, put the CheckoutController
    Get.put(
      CheckoutController(
        userLocationController: Get.find<UserLocationController>(),
        authController: Get.find<AuthController>(),
        cartController: Get.find<CartController>(),
        shippingService: Get.find<ShippingService>(),
        transactionService: Get.find<TransactionService>(),
      ),
    );
  }
}
