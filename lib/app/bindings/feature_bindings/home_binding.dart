import 'package:get/get.dart';
import '../../controllers/homepage_controller.dart';
import '../../controllers/user_main_controller.dart';
import '../../controllers/cart_controller.dart';
import '../../data/providers/merchant_provider.dart';
import '../../data/providers/product_provider.dart';
import '../../data/providers/category_provider.dart';
import '../../services/merchant_service.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../services/location_service.dart';
import '../../services/user_location_service.dart';
import '../../services/storage_service.dart';
import '../../services/image_service.dart';
import '../../services/auth_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Providers (Data Layer)
    Get.lazyPut(() => MerchantProvider(), fenix: true);
    Get.lazyPut(() => ProductProvider(), fenix: true);
    Get.lazyPut(() => CategoryProvider(), fenix: true);

    // Services (Business Logic Layer)
    Get.put(StorageService.instance, permanent: true);
    Get.lazyPut(() => LocationService(), fenix: true);
    Get.lazyPut(() => UserLocationService(), fenix: true);
    Get.lazyPut(() => MerchantService(), fenix: true);
    Get.lazyPut(() => ProductService(), fenix: true);
    Get.lazyPut(() => CategoryService(), fenix: true);
    Get.lazyPut(() => ImageService(), fenix: true);
    Get.lazyPut(() => AuthService(), fenix: true);

    // Controllers (UI Layer)
    Get.put(HomePageController(), permanent: true);
    Get.put(UserMainController(), permanent: true);
    Get.put(CartController(), permanent: true);
  }
}
