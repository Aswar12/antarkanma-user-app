import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/controllers/user_controller.dart';
import 'package:antarkanma/app/services/auth_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Services - Order matters due to dependencies
    Get.put(AuthService(), permanent: true); // AuthService must be first
    Get.put(CategoryService(), permanent: true);
    Get.put(ProductService(),
        permanent: true); // ProductService depends on AuthService
    Get.put(TransactionService(), permanent: true);

    // Controllers
    Get.put(AuthController(), permanent: true);
    Get.lazyPut(() => UserController());
    Get.put(UserMainController(), permanent: true);
    Get.put(HomePageController(),
        permanent:
            true); // HomePageController depends on ProductService and CategoryService
  }
}
