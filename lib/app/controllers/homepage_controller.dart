import 'dart:async';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/product_category_model.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class HomePageController extends GetxController {
  final ProductService productService = Get.find<ProductService>();
  final CategoryService _categoryService = Get.find<CategoryService>();

  // Observable state variables
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<ProductModel> popularProducts = <ProductModel>[].obs;
  final RxList<ProductModel> searchResults = <ProductModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreData = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString selectedCategory = "Semua".obs;
  final RxInt currentIndex = 0.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  // Pagination variables
  int _currentPage = 1;
  static const int _pageSize = 10;
  static const int _preloadThreshold = 8;
  bool _isPreloading = false;
  bool _isInitialLoad = true;

  // Getters
  List<ProductCategory> get categories => _categoryService.categories;
  bool get isCategoriesLoading => _categoryService.isLoading.value;
  List<ProductModel> get filteredProducts =>
      searchQuery.isEmpty ? products : searchResults;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
    _setupSearchListener();
    
    // Listen to products list changes to trigger preloading
    ever(products, (_) {
      if (products.length >= _preloadThreshold && !_isInitialLoad) {
        checkAndPreloadNextPage();
      }
    });
  }

  void checkAndPreloadNextPage() {
    if (!_isPreloading && hasMoreData.value && searchQuery.isEmpty) {
      preloadNextPage();
    }
  }

  void _setupSearchListener() {
    var debouncer = Debouncer(milliseconds: 500);
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      if (searchQuery.isNotEmpty) {
        debouncer.run(() {
          _currentPage = 1;
          hasMoreData.value = true;
          performSearch();
        });
      } else {
        searchResults.clear();
      }
    });
  }

  Future<void> performSearch() async {
    if (searchQuery.isEmpty) return;

    try {
      if (_currentPage == 1) {
        searchResults.clear();
      }

      final response = await productService.getAllProducts(
        query: searchQuery.value,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        if (productList.isEmpty) {
          hasMoreData.value = false;
          return;
        }

        final List<ProductModel> results = productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (_currentPage == 1) {
          searchResults.assignAll(results);
        } else {
          searchResults.addAll(results);
        }

        _currentPage++;
      }
    } catch (e) {
      _handleError('Search API error', e);
    }
  }

  Future<void> preloadNextPage() async {
    if (_isPreloading || !hasMoreData.value || searchQuery.isNotEmpty) return;

    try {
      _isPreloading = true;
      
      if (selectedCategory.value == "Semua") {
        await productService.fetchProducts(
          page: _currentPage + 1,
          pageSize: _pageSize,
        );
      } else {
        final category = _categoryService.categories
            .firstWhere((cat) => cat.name == selectedCategory.value);
            
        await productService.getProductsByCategory(
          category.id,
          page: _currentPage + 1,
          pageSize: _pageSize,
        );
      }
    } catch (e) {
      print('Error preloading next page: $e');
    } finally {
      _isPreloading = false;
    }
  }

  Future<void> loadMoreProducts() async {
    if (isLoadingMore.value || !hasMoreData.value || searchQuery.isNotEmpty) return;

    try {
      isLoadingMore.value = true;
      
      if (selectedCategory.value == "Semua") {
        final response = await productService.fetchProducts(
          page: _currentPage,
          pageSize: _pageSize,
        );
        
        if (response.statusCode == 200) {
          final data = response.data['data'];
          final List<dynamic> productList =
              data is Map ? data['data'] as List : data as List;

          if (productList.isEmpty) {
            hasMoreData.value = false;
            return;
          }

          final List<ProductModel> newProducts = productList
              .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
              .toList();

          products.addAll(newProducts);
          _currentPage++;
        }
      } else {
        final category = _categoryService.categories
            .firstWhere((cat) => cat.name == selectedCategory.value);
            
        final categoryProducts = await productService.getProductsByCategory(
          category.id,
          page: _currentPage,
          pageSize: _pageSize,
        );
        
        if (categoryProducts.isEmpty) {
          hasMoreData.value = false;
          return;
        }
        
        products.addAll(categoryProducts);
        _currentPage++;
      }
    } catch (e) {
      _handleError('Failed to load more products', e);
    } finally {
      isLoadingMore.value = false;
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
      _currentPage = 1;
      hasMoreData.value = true;
      _isInitialLoad = true;
      
      await Future.wait([
        loadProducts(),
        _categoryService.getCategories(),
        loadPopularProducts(),
      ]);
      
      selectedCategory.value = "Semua";
      _isInitialLoad = false;
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadProducts() async {
    try {
      isLoading(true);
      _currentPage = 1;
      hasMoreData.value = true;
      
      final response = await productService.fetchProducts(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        final List<ProductModel> newProducts = productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();

        products.assignAll(newProducts);
        _currentPage++;
      }
    } catch (e) {
      _handleError('Failed to load products', e);
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadPopularProducts() async {
    try {
      final popularProds = await productService.getPopularProducts(
        limit: 12,
        minRating: 4.0,
        minReviews: 5,
      );
      popularProducts.assignAll(popularProds);
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
      if (categoryName == selectedCategory.value) return;
      
      selectedCategory.value = categoryName;
      _currentPage = 1;
      hasMoreData.value = true;
      products.clear();
      _isInitialLoad = true;

      if (categoryName == "Semua") {
        await loadProducts();
      } else {
        final category = _categoryService.categories
            .firstWhere((cat) => cat.name == categoryName);
        final categoryProducts = await productService.getProductsByCategory(
          category.id,
          page: _currentPage,
          pageSize: _pageSize,
        );
        products.assignAll(categoryProducts);
        _currentPage++;
      }
      
      _isInitialLoad = false;
    } catch (e) {
      _handleError('Failed to load products for category', e);
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
      await productService.clearLocalStorage();
      _currentPage = 1;
      hasMoreData.value = true;
      products.clear();
      popularProducts.clear();
      searchResults.clear();
      _categoryService.categories.clear();
      _isInitialLoad = true;

      await Future.wait([
        loadProducts(),
        _categoryService.getCategories(),
        loadPopularProducts(),
      ]);

      selectedCategory.value = "Semua";
      _isInitialLoad = false;

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
        await _categoryService.getCategories();
        await loadPopularProducts();
      } catch (localError) {
        _handleError('Gagal memuat data lokal', localError);
      }
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

  void updateCurrentIndex(int index) {
    if (popularProducts.isNotEmpty) {
      currentIndex.value = index % popularProducts.length;
    } else {
      currentIndex.value = 0;
    }
  }

  bool get hasValidData => products.isNotEmpty && !isLoading.value;
}
