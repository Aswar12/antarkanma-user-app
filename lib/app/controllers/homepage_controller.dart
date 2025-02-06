import 'dart:async';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/models/product_category_model.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomePageController extends GetxController {
  final ProductService productService = Get.find<ProductService>();
  final MerchantService merchantService = Get.find<MerchantService>();
  final CategoryService _categoryService = Get.find<CategoryService>();
  final AuthService _authService = Get.find<AuthService>();
  final LocationService _locationService = Get.find<LocationService>();

  // Observable state variables for products
  final RxList<ProductModel> popularProducts = <ProductModel>[].obs;
  final RxList<ProductModel> allProducts = <ProductModel>[].obs;
  final RxList<ProductModel> searchResults = <ProductModel>[].obs;

  // Observable state variables for merchants
  final RxList<MerchantModel> allMerchants = <MerchantModel>[].obs;
  final RxList<MerchantModel> merchantSearchResults = <MerchantModel>[].obs;

  // Common state variables
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
    // Load initial data when controller is initialized
    loadInitialData();
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('HomePageController: onReady');
    // Refresh data when the page becomes ready
    refreshProducts(showMessage: false);
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
        final delta = maxScroll * 0.2;

        if (maxScroll - currentScroll <= delta && _currentPage < _lastPage) {
          debugPrint('Near bottom, loading more merchants');
          loadMoreMerchants();
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
        merchantSearchResults.clear();
      }
    });
  }

  Future<void> loadAllMerchants() async {
    if (isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      debugPrint('Loading merchants for page $_currentPage...');

      final coordinates = _locationService.getCurrentCoordinates();
      debugPrint('Using coordinates for merchant request: $coordinates');

      final paginatedResponse = await merchantService.getAllMerchants(
        page: _currentPage,
        pageSize: _pageSize,
        category: selectedCategory.value == "Semua" ? null : selectedCategory.value,
        latitude: coordinates?['latitude'],
        longitude: coordinates?['longitude'],
      );

      if (_currentPage == 1) {
        allMerchants.clear();
      }

      allMerchants.addAll(paginatedResponse.data);
      debugPrint('Loaded ${paginatedResponse.data.length} merchants');

      _lastPage = paginatedResponse.lastPage;
      _totalItems = paginatedResponse.total;
      hasMoreData.value = _currentPage < _lastPage;
      _retryAttempts = 0;
    } catch (e) {
      debugPrint('Error loading merchants: $e');
      if (_retryAttempts < maxRetries) {
        _retryAttempts++;
        await Future.delayed(Duration(seconds: _retryAttempts));
        return loadAllMerchants();
      }
    } finally {
      isLoadingMore.value = false;
      isLoading.value = false; // Ensure loading state is updated
    }
  }

  Future<void> loadMoreMerchants() async {
    if (isLoadingMore.value || _currentPage >= _lastPage) return;

    _currentPage++;
    debugPrint('Loading more merchants, page: $_currentPage');
    await loadAllMerchants();
  }

  Future<void> performSearch() async {
    if (searchQuery.isEmpty) return;

    try {
      isLoadingMore.value = true;
      final coordinates = _locationService.getCurrentCoordinates();

      // Search merchants
      final merchantResponse = await merchantService.getAllMerchants(
        query: searchQuery.value,
        page: _currentPage,
        pageSize: _pageSize,
        latitude: coordinates?['latitude'],
        longitude: coordinates?['longitude'],
      );

      if (_currentPage == 1) {
        merchantSearchResults.clear();
      }

      merchantSearchResults.addAll(merchantResponse.data);
      _lastPage = merchantResponse.lastPage;
      _totalItems = merchantResponse.total;
      hasMoreData.value = _currentPage < _lastPage;
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
      _retryAttempts = 0;
    } catch (e) {
      debugPrint('Error loading popular products: $e');
      if (_retryAttempts < maxRetries) {
        _retryAttempts++;
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
    merchantSearchResults.clear();
    _currentPage = 1;
    hasMoreData.value = true;
    await loadAllMerchants();
  }

  Future<void> refreshProducts({bool showMessage = true}) async {
    if (isRefreshing.value) return;

    try {
      isRefreshing.value = true;
      _retryAttempts = 0;

      // Refresh location first
      await _locationService.getCurrentLocation();

      // Clear all cached data
      await productService.clearLocalStorage();
      await merchantService.clearLocalStorage();
      popularProducts.clear();
      allProducts.clear();
      searchResults.clear();
      merchantSearchResults.clear();
      allMerchants.clear();
      _categoryService.categories.clear();
      _currentPage = 1;
      _lastPage = 1;
      hasMoreData.value = true;

      // Load fresh data
      await Future.wait([
        loadPopularProducts(),
        loadAllMerchants(),
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
      debugPrint('Error refreshing data: $e');
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

      // Get location first
      await _locationService.getCurrentLocation();

      await Future.wait([
        loadPopularProducts(),
        loadAllMerchants(),
      ]);

      selectedCategory.value = "Semua";
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      if (_retryAttempts < maxRetries) {
        _retryAttempts++;
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
  List<MerchantModel> get filteredMerchants =>
      searchQuery.isEmpty ? allMerchants : merchantSearchResults;
  bool get hasValidData => popularProducts.isNotEmpty && !isLoading.value;
}
