// lib/app/bindings/initial_binding.dart

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
    // Services
    Get.put(ProductService(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.put(TransactionService(), permanent: true);
    Get.put(CategoryService(), permanent: true);
    // Controllers
    Get.put(AuthController(), permanent: true);
    Get.lazyPut(() => UserController());
    Get.put(UserMainController(), permanent: true);
    Get.put(HomePageController(), permanent: true);
  }
}
