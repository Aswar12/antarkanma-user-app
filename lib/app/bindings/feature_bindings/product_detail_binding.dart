import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/product_detail_controller.dart';
import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/data/repositories/review_repository.dart';
import 'package:antarkanma/app/data/providers/product_provider.dart';

class ProductDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Register ProductProvider immediately
    Get.put<ProductProvider>(ProductProvider(), permanent: true);
    
    // Register ReviewRepository with its required ProductProvider
    Get.put<ReviewRepository>(
      ReviewRepository(provider: Get.find<ProductProvider>()),
      permanent: true,
    );
    
    // Register ProductDetailController with its required ReviewRepository
    Get.put<ProductDetailController>(
      ProductDetailController(
        reviewRepository: Get.find<ReviewRepository>(),
      ),
      permanent: true,
    );

    // Register CartController if not already registered
    if (!Get.isRegistered<CartController>()) {
      Get.put<CartController>(CartController(), permanent: true);
    }

    // Register UserMainController if not already registered
    if (!Get.isRegistered<UserMainController>()) {
      Get.put<UserMainController>(UserMainController(), permanent: true);
    }
  }
}
