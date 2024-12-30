import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/services/user_location_service.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/product_category_service.dart';
import 'package:antarkanma/app/modules/merchant/controllers/merchant_controller.dart';
import 'package:antarkanma/app/modules/merchant/controllers/merchant_profile_controller.dart';
import 'package:antarkanma/app/modules/merchant/controllers/merchant_product_controller.dart';
import 'package:antarkanma/app/modules/merchant/controllers/merchant_product_form_controller.dart';

class MerchantBinding extends Bindings {
  @override
  void dependencies() {
    // Services first
    Get.put(UserLocationService());
    Get.put(MerchantService(), permanent: true);
    
    // Initialize ProductCategoryService first and ensure it loads categories
    final categoryService = Get.put(ProductCategoryService(), permanent: true);
    categoryService.init(); // This will load categories immediately
    
    // Controllers
    Get.put(UserLocationController(locationService: Get.find<UserLocationService>()));
    
    // Initialize merchant controllers as permanent to maintain state
    Get.put(MerchantController(), permanent: true);
    Get.put(MerchantProfileController(), permanent: true);
    Get.put(MerchantProductController(merchantService: Get.find<MerchantService>()), permanent: true);
    
    // Initialize product form controller with fenix to recreate when needed
    Get.lazyPut<MerchantProductFormController>(
      () => MerchantProductFormController(
        merchantService: Get.find<MerchantService>()
      ),
      fenix: true
    );
  }
}
