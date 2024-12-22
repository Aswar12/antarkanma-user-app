import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/category_model.dart';
import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/services/product_service.dart';

class HomePageController extends GetxController {
  final ProductService productService = Get.find<ProductService>();
  final CategoryService _categoryService = Get.find<CategoryService>();

  // Observable state variables
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<ProductModel> popularProducts = <ProductModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString selectedCategory = "Semua".obs;
  final RxInt currentIndex = 0.obs;

  // Getters
  List<CategoryModel> get categories => _categoryService.categories;
  bool get isCategoriesLoading => _categoryService.isLoading.value;
  List<ProductModel> get filteredProducts => products;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    try {
      isLoading(true);
      // Load all data in parallel
      await Future.wait([
        loadProducts(),
        _categoryService.loadCategories(),
        loadPopularProducts(),
      ]);
      selectedCategory.value = "Semua";
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadPopularProducts() async {
    try {
      final products = await productService.getPopularProducts(
        limit: 12,
        minRating: 4.0,
        minReviews: 5,
      );
      popularProducts.assignAll(products);
    } catch (e) {
      _handleError('Failed to load popular products', e);
      // Try to get from storage if API fails
      final storedProducts = productService.getAllProductsFromStorage();
      if (storedProducts.isNotEmpty) {
        // Filter for products with high ratings
        final highRatedProducts = storedProducts
            .where((p) => (p.averageRating ?? 0) >= 4.0)
            .take(12)
            .toList();
        popularProducts.assignAll(highRatedProducts);
      }
    }
  }

  void updateSelectedCategory(String categoryName) async {
    try {
      isLoading(true);
      selectedCategory.value = categoryName;

      if (categoryName == "Semua") {
        // For "Semua", always use products from local storage
        final storedProducts = productService.getAllProductsFromStorage();
        products.assignAll(storedProducts);
      } else {
        // For specific category, fetch from API
        final category = _categoryService.categories
            .firstWhere((cat) => cat.name == categoryName);
        await productService.getProductsByCategory(category.id);
        products.assignAll(productService.products);
      }
    } catch (e) {
      _handleError('Failed to load products for category', e);
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadProducts() async {
    try {
      isLoading(true);
      await productService.fetchProducts();

      // Ensure each product has rating info
      final List<ProductModel> productsWithRatings = [];
      for (var product in productService.products) {
        if (product.id != null) {
          if (product.ratingInfo == null) {
            // If no rating info, fetch it
            final reviewData =
                await productService.getProductWithReviews(product.id!);
            final updatedProduct = product.copyWith(
              averageRatingRaw:
                  reviewData['rating_info']['average_rating'].toString(),
              totalReviewsRaw:
                  reviewData['rating_info']['total_reviews'] as int,
              ratingInfo: reviewData['rating_info'] as Map<String, dynamic>,
              reviews:
                  (reviewData['reviews'] as List).cast<ProductReviewModel>(),
            );
            productsWithRatings.add(updatedProduct);
          } else {
            productsWithRatings.add(product);
          }
        }
      }
      products.assignAll(productsWithRatings);
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

      // Clear existing data first
      products.clear();
      popularProducts.clear();
      _categoryService.categories.clear();

      // Refresh all data
      await Future.wait([
        productService.refreshProducts(),
        _categoryService.loadCategories(),
        loadPopularProducts(),
      ]);

      // Update products list
      products.assignAll(productService.products);

      // Reset category filter to "Semua"
      selectedCategory.value = "Semua";

      if (showMessage) {
        Get.snackbar(
          'Berhasil',
          'Data berhasil diperbarui dari server',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      _handleError('Gagal memperbarui data', e);

      // If refresh fails, try to load from local storage
      try {
        await productService.fetchProducts();
        await _categoryService.loadCategories();
        await loadPopularProducts();
        products.assignAll(productService.products);
      } catch (localError) {
        _handleError('Gagal memuat data lokal', localError);
      }
    } finally {
      isRefreshing(false);
      isLoading(false);
    }
  }

  // Method to force refresh from server
  Future<void> forceRefreshFromServer() async {
    try {
      isLoading(true);

      // Clear local storage for products and categories
      await productService.clearLocalStorage();
      await _categoryService.clearLocalStorage();

      // Fetch fresh data from server
      await refreshProducts(showMessage: true);
    } catch (e) {
      _handleError('Gagal memperbarui data dari server', e);
    } finally {
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

  Future<void> retryLoading() => loadProducts();

  void updateCurrentIndex(int index) {
    if (popularProducts.isNotEmpty) {
      currentIndex.value = index % popularProducts.length;
    } else {
      currentIndex.value = 0;
    }
  }

  bool get hasValidData => products.isNotEmpty && !isLoading.value;
}
