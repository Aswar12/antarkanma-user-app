import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/category_model.dart';
import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/data/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/services/product_service.dart';

class HomePageController extends GetxController {
  final ProductService productService = Get.find<ProductService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final ProductProvider _productProvider = ProductProvider();

  // Observable state variables
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<ProductModel> popularProducts = <ProductModel>[].obs;
  final RxList<ProductModel> searchResults = <ProductModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString selectedCategory = "Semua".obs;
  final RxInt currentIndex = 0.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // Getters
  List<CategoryModel> get categories => _categoryService.categories;
  bool get isCategoriesLoading => _categoryService.isLoading.value;
  List<ProductModel> get filteredProducts =>
      searchQuery.isEmpty ? products : searchResults;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
    _setupSearchListener();
  }

  void _setupSearchListener() {
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      if (searchQuery.isNotEmpty) {
        performSearch();
      } else {
        searchResults.clear();
      }
    });
  }

  Future<void> performSearch() async {
    // Show local results first without loading state
    List<ProductModel> localResults = productService
        .getAllProductsFromStorage()
        .where((product) =>
            product.name
                .toLowerCase()
                .contains(searchQuery.value.toLowerCase()) ||
            (product.merchant?.name ?? '')
                .toLowerCase()
                .contains(searchQuery.value.toLowerCase()))
        .toList();
    searchResults.assignAll(localResults);

    // Then fetch from API in background without showing loading indicator
    try {
      final response = await _productProvider.getAllProducts(
        query: searchQuery.value,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        final List<ProductModel> results = [];
        for (var json in productList) {
          final product = ProductModel.fromJson(json as Map<String, dynamic>);
          if (product.id != null && product.ratingInfo == null) {
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
            results.add(updatedProduct);
          } else {
            results.add(product);
          }
        }
        // Update results if we got new data
        if (results.isNotEmpty) {
          searchResults.assignAll(results);
        }
      }
    } catch (e) {
      // Silent error handling - keep showing local results
      print('Search API error: $e');
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadInitialData() async {
    try {
      isLoading(true);
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
      final storedProducts = productService.getAllProductsFromStorage();
      if (storedProducts.isNotEmpty) {
        final highRatedProducts =
            storedProducts.where((p) => (p.averageRating) >= 4.0).toList();
        popularProducts.assignAll(highRatedProducts);
      }
    }
  }

  void updateSelectedCategory(String categoryName) async {
    try {
      selectedCategory.value = categoryName;

      if (categoryName == "Semua") {
        await productService.fetchProducts();
        products.assignAll(productService.products);
      } else {
        final category = _categoryService.categories
            .firstWhere((cat) => cat.name == categoryName);
        final categoryProducts =
            await productService.getProductsByCategory(category.id);
        products.assignAll(categoryProducts);
      }
    } catch (e) {
      _handleError('Failed to load products for category', e);
      // Fallback to stored products if API fails
      final storedProducts = productService.getAllProductsFromStorage();
      if (categoryName == "Semua") {
        products.assignAll(storedProducts);
      } else {
        final category = _categoryService.categories
            .firstWhere((cat) => cat.name == categoryName);
        final filteredProducts = storedProducts
            .where((product) => product.category?.id == category.id)
            .toList();
        products.assignAll(filteredProducts);
      }
    }
  }

  Future<void> refreshProducts({bool showMessage = true}) async {
    if (isRefreshing.value) return;

    try {
      isRefreshing(true);
      products.clear();
      popularProducts.clear();
      searchResults.clear();
      _categoryService.categories.clear();

      await Future.wait([
        productService.refreshProducts(),
        _categoryService.loadCategories(),
        loadPopularProducts(),
      ]);

      products.assignAll(productService.products);
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
      try {
        await loadProducts();
        await _categoryService.loadCategories();
        await loadPopularProducts();
      } catch (localError) {
        _handleError('Gagal memuat data lokal', localError);
      }
    } finally {
      isRefreshing(false);
      isLoading(false);
    }
  }

  Future<void> forceRefreshFromServer() async {
    try {
      isLoading(true);
      await productService.clearLocalStorage();
      await _categoryService.clearLocalStorage();
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

  void updateCurrentIndex(int index) {
    if (popularProducts.isNotEmpty) {
      currentIndex.value = index % popularProducts.length;
    } else {
      currentIndex.value = 0;
    }
  }

  bool get hasValidData => products.isNotEmpty && !isLoading.value;
}
