// ignore_for_file: unrelated_type_equality_checks, avoid_print

import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'dart:async'; // Untuk Timer

class HomePageController extends GetxController {
  var products = <ProductModel>[].obs;
  var isLoading = true.obs;
  var isRefreshing = false.obs;
  Timer? _refreshTimer;
  final Rx<String> selectedCategory = "All".obs;
  final ProductService productService;
  var currentIndex = 0.obs;

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
    _startAutoRefresh();
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  // Load products pertama kali
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

  // Refresh products (untuk pull-to-refresh)
  Future<void> refreshProducts() async {
    if (isRefreshing.value) return; // Prevent multiple refreshes

    try {
      isRefreshing(true);
      await productService.refreshProducts();
      products.assignAll(productService.products);

      // Show success message
      Get.snackbar(
        'Success',
        'Products refreshed successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      _handleError('Failed to refresh products', e);
    } finally {
      isRefreshing(false);
    }
  }

  // Auto refresh setiap interval tertentu
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      refreshProducts();
    });
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
    return products.take(5).toList(); // Ambil 5 produk pertama sebagai contoh
  }

  // Method untuk mencari produk
  List<ProductModel> searchProducts(String query) {
    if (query.isEmpty) return products;
    return products
        .where((product) =>
            product.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Method untuk filter produk berdasarkan kategori
  // List<ProductModel> filterByCategory(String category) {
  //   if (category.isEmpty) return products;
  //   return products
  //       .where((product) =>
  //           product.category?.toLowerCase() == category.toLowerCase())
  //       .toList();
  // }

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
      // Tambahkan case sorting lainnya sesuai kebutuhan
    }
  }

  // Method untuk check jika data perlu di-refresh

  // Method untuk memvalidasi data
  bool get hasValidData {
    return products.isNotEmpty && !isLoading.value;
  }

  // Method untuk retry loading jika gagal
  Future<void> retryLoading() async {
    await loadProducts();
  }
}
