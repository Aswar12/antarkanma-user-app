import 'package:get/get.dart';
import '../../../services/auth_service.dart';
import '../../../services/product_service.dart';
import '../../../services/category_service.dart';
import '../../../services/transaction_service.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final ProductService _productService = Get.find<ProductService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final TransactionService _transactionService = Get.find<TransactionService>();
  
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    initializeApp();
  }

  Future<void> initializeApp() async {
    try {
      // Check if user is logged in
      if (_authService.currentUser.value == null) {
        await Future.delayed(const Duration(seconds: 2)); // Show splash for 2 seconds
        Get.offAllNamed(Routes.login);
        return;
      }

      // Load data based on user role
      final userRole = _authService.userRole;
      final userId = _authService.userId;
      
      switch (userRole) {
        case 'USER':
          await Future.wait([
            _categoryService.getCategories(),
            _productService.getAllProducts(),
            _transactionService.getTransactions(), // Get user's transactions
          ]);
          Get.offAllNamed(Routes.userMainPage);
          break;
          
        case 'MERCHANT':
          if (userId != null) {
            await Future.wait([
              _productService.getAllProducts(), // Get all products, filter by merchant ID in UI
              _transactionService.getTransactionsByMerchant(userId.toString()), // Get merchant's orders
            ]);
          }
          Get.offAllNamed(Routes.merchantMainPage);
          break;
          
        case 'COURIER':
          await _transactionService.getTransactions(status: 'PENDING_DELIVERY');
          Get.offAllNamed(Routes.courierMainPage);
          break;
          
        default:
          Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      print('Error in splash controller: $e');
      Get.offAllNamed(Routes.login);
    } finally {
      isLoading.value = false;
    }
  }
}
