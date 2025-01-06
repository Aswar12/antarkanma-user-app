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
    print('Initializing dependencies...');
    
    // Services - Order matters due to dependencies
    print('Initializing AuthService...');
    Get.put(AuthService(), permanent: true);
    
    print('Initializing CategoryService...');
    Get.put(CategoryService(), permanent: true);
    
    print('Initializing ProductService...');
    final productService = ProductService();
    Get.put(productService, permanent: true);
    
    print('Initializing TransactionService...');
    Get.put(TransactionService(), permanent: true);

    // Controllers
    print('Initializing AuthController...');
    Get.put(AuthController(), permanent: true);
    
    print('Initializing UserController...');
    Get.lazyPut(() => UserController());
    
    print('Initializing UserMainController...');
    Get.put(UserMainController(), permanent: true);
    
    print('Initializing HomePageController...');
    final homeController = HomePageController();
    Get.put(homeController, permanent: true);
    
    // Force immediate initialization of popular products
    print('Loading initial data...');
    homeController.loadInitialData();
    
    print('Dependencies initialization complete');
  }
}
