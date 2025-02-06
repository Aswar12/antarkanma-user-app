import 'package:antarkanma/app/data/providers/shipping_provider.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/product_detail_controller.dart';
import '../../data/providers/merchant_provider.dart';
import '../../data/providers/product_provider.dart';
import '../../data/repositories/review_repository.dart';
import '../../services/merchant_service.dart';
import '../../services/product_service.dart';
import '../../services/shipping_service.dart';
import '../../services/location_service.dart';
import '../../services/storage_service.dart';

class MerchantBinding extends Bindings {
  @override
  void dependencies() {
    // Core Services
    if (!Get.isRegistered<StorageService>()) {
      Get.put(StorageService.instance, permanent: true);
    }

    // Providers - Make them permanent to maintain state
    Get.put(MerchantProvider(), permanent: true);
    Get.put(ProductProvider(), permanent: true);
    Get.put(ShippingProvider(), permanent: true);

    // Services - Make them permanent to maintain state
    Get.put(MerchantService(), permanent: true);
    Get.put(ProductService(), permanent: true);
    Get.put(ShippingService(), permanent: true);
    Get.put(LocationService(), permanent: true);

    // Repositories
    Get.put(
      ReviewRepository(provider: Get.find<ProductProvider>()),
      permanent: true
    );

    // Controllers
    Get.put(ProductController(), permanent: true);
    Get.put(
      ProductDetailController(reviewRepository: Get.find<ReviewRepository>()),
      permanent: true,
    );
  }
}
