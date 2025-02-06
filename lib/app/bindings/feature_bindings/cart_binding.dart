import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/cart_controller.dart';

class CartBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CartController>(() => CartController());
  }
}
