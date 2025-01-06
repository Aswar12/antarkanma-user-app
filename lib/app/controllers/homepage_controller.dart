import 'dart:async';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/product_category_model.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:flutter/foundation.dart';
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
  final TextEditingController searchController = TextEditingController();

  // Pagination variables
  String? _currentCursor;
  String? _searchCursor;
  static const int _pageSize = 10;
  bool _isInitialLoad = true;
  bool _isLoadingPopular = false;
  Completer<void>? _popularProductsCompleter;

  // Getters
  List<ProductCategory> get categories => _categoryService.categories;
  bool get isCategoriesLoading => _categoryService.isLoading.value;
  List<ProductModel> get filteredProducts =>
      searchQuery.isEmpty ? allProducts : searchResults;

  @override
  void onInit() {
    super.onInit();
    debugPrint('HomePageController: onInit');
    loadInitialData();
    _setupSearchListener();
  }

  void _setupSearchListener() {
    var debouncer = Debouncer(milliseconds: 500);
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      if (searchQuery.isNotEmpty) {
        debouncer.run(() {
          _searchCursor = null;
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
      if (_searchCursor == null) {
        searchResults.clear();
      }

      final apiResponse = await productService.getAllProducts(
        query: searchQuery.value,
        cursor: _searchCursor,
        pageSize: _pageSize,
      );

      if (apiResponse.data.isNotEmpty) {
        final List<ProductModel> results = apiResponse.data;
        debugPrint('Search results: ${results.length} products found');

        if (_searchCursor == null) {
          searchResults.assignAll(results);
        } else {
          searchResults.addAll(results);
        }

        _searchCursor = apiResponse.nextCursor;
        hasMoreData.value = apiResponse.hasMore;
        debugPrint('Next search cursor: $_searchCursor');
      } else {
        hasMoreData.value = false;
      }
    } catch (e) {
      debugPrint('Error performing search: $e');
    }
  }

  Future<void> loadMoreProducts() async {
    if (isLoadingMore.value || !hasMoreData.value) {
      debugPrint('Skip loading more: isLoadingMore=${isLoadingMore.value}, hasMoreData=${hasMoreData.value}');
      return;
    }

    try {
      debugPrint('Loading more products...');
      isLoadingMore.value = true;
      
      if (searchQuery.isEmpty) {
        debugPrint('Loading more all products with cursor: $_currentCursor');
        final response = await productService.getAllProducts(
          cursor: _currentCursor,
          pageSize: _pageSize,
        );
        
        if (response.data.isNotEmpty) {
          debugPrint('Loaded ${response.data.length} more products');
          allProducts.addAll(response.data);
          _currentCursor = response.nextCursor;
          hasMoreData.value = response.hasMore;
          debugPrint('Next cursor: $_currentCursor, hasMore: ${hasMoreData.value}');
        } else {
          debugPrint('No more products to load');
          hasMoreData.value = false;
        }
      } else {
        debugPrint('Loading more search results with cursor: $_searchCursor');
        await performSearch();
      }
    } catch (e) {
      debugPrint('Error loading more products: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void checkAndPreloadNextPage() {
    if (!isLoadingMore.value && hasMoreData.value) {
      debugPrint('Preloading next page...');
      loadMoreProducts();
    }
  }

  void updateSelectedCategory(String categoryName) async {
    if (categoryName == selectedCategory.value) return;
    
    selectedCategory.value = categoryName;
    searchController.clear();
    searchQuery.value = '';
    searchResults.clear();
    _currentCursor = null;
    _searchCursor = null;
    hasMoreData.value = true;
    await loadAllProducts();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> loadInitialData() async {
    try {
      debugPrint('Loading initial data...');
      isLoading(true);
      _isInitialLoad = true;
      
      await Future.wait([
        _categoryService.getCategories(),
        loadPopularProducts(),
        loadAllProducts(),
      ]);
      
      selectedCategory.value = "Semua";
      _isInitialLoad = false;
      debugPrint('Initial data loaded successfully');
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadAllProducts() async {
    try {
      debugPrint('Loading all products...');
      final response = await productService.getAllProducts(
        pageSize: _pageSize,
      );
      
      if (response.data.isNotEmpty) {
        debugPrint('Loaded ${response.data.length} products');
        allProducts.assignAll(response.data);
        _currentCursor = response.nextCursor;
        hasMoreData.value = response.hasMore;
        debugPrint('Initial cursor: $_currentCursor, hasMore: ${hasMoreData.value}');
      } else {
        debugPrint('No products returned from service');
        hasMoreData.value = false;
      }
    } catch (e) {
      debugPrint('Error loading all products: $e');
    }
  }

  Future<void> loadPopularProducts() async {
    if (_isLoadingPopular && _popularProductsCompleter != null) {
      debugPrint('Already loading popular products, returning existing completer');
      return _popularProductsCompleter!.future;
    }

    _isLoadingPopular = true;
    _popularProductsCompleter = Completer<void>();

    try {
      debugPrint('Loading popular products...');
      final response = await productService.getAllProducts(
        pageSize: 10,
      );
      
      if (response.data.isNotEmpty) {
        debugPrint('Loaded ${response.data.length} popular products');
        popularProducts.assignAll(response.data);
        debugPrint('Popular products assigned to state');
        
        if (response.data.isNotEmpty) {
          final firstProduct = response.data.first;
          debugPrint('First product: ${firstProduct.name}');
          debugPrint('First product images: ${firstProduct.imageUrls}');
          debugPrint('First product price: ${firstProduct.price}');
        }
      } else {
        debugPrint('No popular products returned from service');
      }
      _popularProductsCompleter?.complete();
    } catch (e, stackTrace) {
      debugPrint('Error loading popular products: $e');
      debugPrint('Stack trace: $stackTrace');
      _popularProductsCompleter?.completeError(e);
    } finally {
      _isLoadingPopular = false;
      _popularProductsCompleter = null;
    }
  }

  Future<void> refreshProducts({bool showMessage = true}) async {
    if (isRefreshing.value) return;

    try {
      debugPrint('Refreshing products...');
      isRefreshing(true);
      
      // Clear all cached data
      await productService.clearLocalStorage();
      _currentCursor = null;
      _searchCursor = null;
      hasMoreData.value = true;
      popularProducts.clear();
      searchResults.clear();
      allProducts.clear();
      _categoryService.categories.clear();
      _isInitialLoad = true;

      // Load fresh data
      await Future.wait([
        loadPopularProducts(),
        loadAllProducts(),
        _categoryService.getCategories(),
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
      debugPrint('Error refreshing products: $e');
      Get.snackbar(
        'Error',
        'Gagal memperbarui data',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isRefreshing(false);
      isLoading(false);
    }
  }

  void updateCurrentIndex(int index) {
    if (popularProducts.isNotEmpty) {
      currentIndex.value = index % popularProducts.length;
    } else {
      currentIndex.value = 0;
    }
  }

  bool get hasValidData => popularProducts.isNotEmpty && !isLoading.value;
}
