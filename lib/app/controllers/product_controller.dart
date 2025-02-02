import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/product_model.dart';

class ProductController extends GetxController {
  final PageController pageController = PageController(viewportFraction: 0.8);
  final RxInt currentIndex = 0.obs;

  void setCurrentIndex(int index) {
    currentIndex.value = index;
  }

  void addToCart(ProductModel product) {
    // Implementasi logika untuk menambahkan ke keranjang
    Get.snackbar('Success', 'Product added to cart',
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
