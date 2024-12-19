// ignore_for_file: unrelated_type_equality_checks, avoid_print

import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/services/product_service.dart';

class HomePageController extends GetxController {
  final ProductService productService;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString selectedCategory = "All".obs;
  final RxInt currentIndex = 0.obs;

  HomePageController(this.productService);

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  List<ProductModel> get filteredProducts {
    if (selectedCategory.value == "All") {
      return products;
    } else {
      return products
          .where((product) => product.category == selectedCategory.value)
          .toList();
    }
  }

  Future<void> loadProducts() async {
    try {
      isLoading(true);
      await productService.fetchProducts();
      products.assignAll(productService.products);
    } catch (e) {
      _handleError('Failed to load products', e);
    } finally {
      isLoading(false);
    }
  }

  Future<void> refreshProducts({bool showMessage = true}) async {
    if (isRefreshing.value) return;

    try {
      isRefreshing(true);
      await productService.refreshProducts();
      products.assignAll(productService.products);

      if (showMessage) {
        Get.snackbar(
          'Success',
          'Products refreshed successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      _handleError('Failed to refresh products', e);
    } finally {
      isRefreshing(false);
      isLoading(false);
    }
  }

  void _handleError(String message, dynamic error) {
    print('Error: $message - $error');
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  List<ProductModel> get popularProducts => products.take(5).toList();

  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return products;
    return products
        .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void sortProducts({required String sortBy, bool ascending = true}) {
    switch (sortBy) {
      case 'name':
        products.sort((a, b) =>
            ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
        break;
      case 'price':
        products.sort((a, b) => ascending
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price));
        break;
    }
  }

  bool get hasValidData => products.isNotEmpty && !isLoading.value;

  Future<void> retryLoading() => loadProducts();

  void updateCurrentIndex(int index) => currentIndex.value = index;
}
