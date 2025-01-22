import 'dart:async';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/product_category_model.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePageController extends GetxController {
  final ProductService productService = Get.find<ProductService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final AuthService _authService = Get.find<AuthService>();

  // Observable state variables
  final RxList<ProductModel> popularProducts = <ProductModel>[].obs;
  final RxList<ProductModel> searchResults = <ProductModel>[].obs;
  final RxList<ProductModel> allProducts = <ProductModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreData = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString selectedCategory = "Semua".obs;
  final RxInt currentIndex = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  // Pagination variables
  static const int _pageSize = 10;
  bool _isLoadingPopular = false;
  Completer<void>? _popularProductsCompleter;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;
  int _retryAttempts = 0;
  static const int maxRetries = 3;

  @override
  void onInit() {
    super.onInit();
    debugPrint('HomePageController: onInit');
    searchFocusNode.addListener(_onSearchFocusChange);
    scrollController.addListener(_scrollListener);
    _setupSearchListener();
  }

  @override
  void onClose() {
    searchController.dispose();
    searchFocusNode.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (!isLoadingMore.value && hasMoreData.value) {
      if (scrollController.hasClients) {
        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.position.pixels;
        final delta = maxScroll * 0.2; // Load more when 20% from bottom

        if (maxScroll - currentScroll <= delta && _currentPage < _lastPage) {
          debugPrint('Near bottom, loading more products');
          debugPrint('Current page: $_currentPage, Last page: $_lastPage');
          loadMoreProducts();
        }
      }
    }
  }

  void _onSearchFocusChange() {
    isSearching.value = searchFocusNode.hasFocus;
  }

  void _setupSearchListener() {
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      if (searchQuery.isNotEmpty) {
        _currentPage = 1;
        performSearch();
      } else {
        searchResults.clear();
      }
    });
  }

  Future<void> loadAllProducts() async {
    if (isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      debugPrint('Loading products for page $_currentPage...');

      final paginatedResponse = await productService.getAllProducts(
        pageSize: _pageSize,
        page: _currentPage,
      );

      if (_currentPage == 1) {
        allProducts.clear();
      }

      allProducts.addAll(paginatedResponse.data);
      _lastPage = paginatedResponse.lastPage;
      _totalItems = paginatedResponse.total;
      hasMoreData.value = _currentPage < _lastPage;
      _retryAttempts = 0; // Reset retry counter on success

      debugPrint('Loaded page $_currentPage of $_lastPage');
      debugPrint('Total products loaded: ${allProducts.length} of $_totalItems');
      debugPrint('Has more data: ${hasMoreData.value}');

    } catch (e) {
      debugPrint('Error loading products: $e');
      if (_retryAttempts < maxRetries) {
        _retryAttempts++;
        debugPrint('Retrying... Attempt $_retryAttempts of $maxRetries');
        await Future.delayed(Duration(seconds: _retryAttempts));
        return loadAllProducts();
      }
      rethrow;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreProducts() async {
    if (isLoadingMore.value || _currentPage >= _lastPage) {
      debugPrint(
          'Skip loading more: currentPage=$_currentPage, lastPage=$_lastPage');
      return;
    }

    _currentPage++;
    debugPrint('Loading more products, page: $_currentPage of $_lastPage');
    await loadAllProducts();
  }

  Future<void> performSearch() async {
    if (searchQuery.isEmpty) return;

    try {
      isLoadingMore.value = true;
      final paginatedResponse = await productService.getAllProducts(
        query: searchQuery.value,
        pageSize: _pageSize,
        page: _currentPage,
      );

      if (_currentPage == 1) {
        searchResults.clear();
      }

      searchResults.addAll(paginatedResponse.data);
      _lastPage = paginatedResponse.lastPage;
      _totalItems = paginatedResponse.total;
      hasMoreData.value = _currentPage < _lastPage;

      debugPrint('Search results loaded: ${searchResults.length} of $_totalItems');
      debugPrint('Current page: $_currentPage of $_lastPage');
      debugPrint('Has more data: ${hasMoreData.value}');

    } catch (e) {
      debugPrint('Error performing search: $e');
      rethrow;
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadPopularProducts() async {
    if (_isLoadingPopular && _popularProductsCompleter != null) {
      return _popularProductsCompleter!.future;
    }

    _isLoadingPopular = true;
    _popularProductsCompleter = Completer<void>();
    _retryAttempts = 0;

    try {
      final paginatedResponse = await productService.getAllProducts(
        pageSize: 10,
      );

      popularProducts.assignAll(paginatedResponse.data);
      _popularProductsCompleter?.complete();
      _retryAttempts = 0; // Reset retry counter on success
    } catch (e) {
      debugPrint('Error loading popular products: $e');
      if (_retryAttempts < maxRetries) {
        _retryAttempts++;
        debugPrint('Retrying popular products... Attempt $_retryAttempts of $maxRetries');
        await Future.delayed(Duration(seconds: _retryAttempts));
        _popularProductsCompleter?.completeError(e);
        _popularProductsCompleter = null;
        _isLoadingPopular = false;
        return loadPopularProducts();
      }
      _popularProductsCompleter?.completeError(e);
      rethrow;
    } finally {
      _isLoadingPopular = false;
      _popularProductsCompleter = null;
    }
  }

  void updateCurrentIndex(int index) {
    if (popularProducts.isNotEmpty) {
      currentIndex.value = index % popularProducts.length;
    } else {
      currentIndex.value = 0;
    }
  }

  void updateSelectedCategory(String categoryName) async {
    if (categoryName == selectedCategory.value) return;

    selectedCategory.value = categoryName;
    searchController.clear();
    searchQuery.value = '';
    searchResults.clear();
    _currentPage = 1;
    hasMoreData.value = true;
    await loadAllProducts();
  }

  Future<void> refreshProducts({bool showMessage = true}) async {
    if (isRefreshing.value) return;

    try {
      isRefreshing.value = true;
      _retryAttempts = 0;

      // Clear all cached data
      await productService.clearLocalStorage();
      popularProducts.clear();
      searchResults.clear();
      allProducts.clear();
      _categoryService.categories.clear();
      _currentPage = 1;
      _lastPage = 1;
      hasMoreData.value = true;

      // Load fresh data
      await Future.wait([
        loadPopularProducts(),
        loadAllProducts(),
        _categoryService.getCategories(),
      ]);

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
      debugPrint('Error refreshing products: $e');
      if (showMessage) {
        Get.snackbar(
          'Error',
          'Gagal memperbarui data',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
      rethrow;
    } finally {
      isRefreshing.value = false;
      isLoading.value = false;
    }
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      _currentPage = 1;
      _lastPage = 1;
      hasMoreData.value = true;
      _retryAttempts = 0;

      await Future.wait([
        _categoryService.getCategories(),
        loadPopularProducts(),
        loadAllProducts(),
      ]);

      selectedCategory.value = "Semua";
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (_retryAttempts < maxRetries) {
        _retryAttempts++;
        debugPrint('Retrying initial data load... Attempt $_retryAttempts of $maxRetries');
        await Future.delayed(Duration(seconds: _retryAttempts));
        return loadInitialData();
      }
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // Getters
  List<ProductCategory> get categories => _categoryService.categories;
  bool get isCategoriesLoading => _categoryService.isLoading.value;
  List<ProductModel> get filteredProducts =>
      searchQuery.isEmpty ? allProducts : searchResults;
  bool get hasValidData => popularProducts.isNotEmpty && !isLoading.value;
}
