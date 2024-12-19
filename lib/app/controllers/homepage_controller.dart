// ignore_for_file: unrelated_type_equality_checks, avoid_print

import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'dart:async';
import 'package:get_storage/get_storage.dart';

class HomePageController extends GetxController {
  var products = <ProductModel>[].obs;
  var isLoading = true.obs;
  var isRefreshing = false.obs;
  Timer? _refreshTimer;
  final Rx<String> selectedCategory = "All".obs;
  final ProductService productService;
  var currentIndex = 0.obs;
  final storage = GetStorage();

  void updateCurrentIndex(int index) {
    currentIndex.value = index;
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

  HomePageController(this.productService);

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  // Load products from local storage first
  Future<void> loadProducts() async {
    try {
      isLoading(true);

      // Try to load from local storage first
      final storedProducts = storage.read('products');
      final lastRefresh = storage.read('last_refresh');
      final shouldRefresh = lastRefresh == null ||
          DateTime.now().difference(DateTime.parse(lastRefresh)).inHours > 1;

      if (storedProducts != null && !shouldRefresh) {
        // Use cached data
        final List<dynamic> productList = storedProducts;
        products.value =
            productList.map((json) => ProductModel.fromJson(json)).toList();
        isLoading(false);
      } else {
        // If no cached data or cache is old, fetch from server
        await refreshProducts(showMessage: false);
      }
    } catch (e) {
      _handleError('Failed to load products', e);
      isLoading(false);
    }
  }

  // Refresh products (untuk pull-to-refresh)
  Future<void> refreshProducts({bool showMessage = true}) async {
    if (isRefreshing.value) return; // Prevent multiple refreshes

    try {
      isRefreshing(true);
      await productService.refreshProducts();
      products.assignAll(productService.products);

      // Update last refresh time
      await storage.write('last_refresh', DateTime.now().toIso8601String());

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

  // Handle error dengan lebih terstruktur
  void _handleError(String message, dynamic error) {
    print('Error: $message - $error');

    String errorMessage = message;
    if (error is TimeoutException) {
      errorMessage = 'Connection timeout. Please try again.';
    } else if (error.toString().contains('No Internet')) {
      errorMessage = 'No internet connection. Please check your connection.';
    }

    Get.snackbar(
      'Error',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.error, color: Colors.white),
    );
  }

  // Method untuk mendapatkan produk populer
  List<ProductModel> get popularProducts {
    return products.take(5).toList();
  }

  // Method untuk mencari produk
  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return products;
    return products
        .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Method untuk sorting produk
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

  // Method untuk memvalidasi data
  bool get hasValidData {
    return products.isNotEmpty && !isLoading.value;
  }

  // Method untuk retry loading jika gagal
  Future<void> retryLoading() async {
    await loadProducts();
  }
}
