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
  final ProductService productService;
  final MerchantService merchantService;
  final CategoryService _categoryService;
  final AuthService _authService;
  final LocationService _locationService;

  // Initialize controllers immediately
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // Observable state variables with persistence
  final RxList<ProductModel> popularProducts = <ProductModel>[].obs;
  final RxList<ProductModel> allProducts = <ProductModel>[].obs;
  final RxList<ProductModel> searchResults = <ProductModel>[].obs;
  final RxList<MerchantModel> allMerchants = <MerchantModel>[].obs;
  final RxList<MerchantModel> merchantSearchResults = <MerchantModel>[].obs;

  // Loading states
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreData = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxBool isLoadingPopularProducts = false.obs;
  final RxBool isLoadingMerchants = false.obs;

  // UI states with persistence
  final RxString selectedCategory = "Semua".obs;
  final RxInt currentIndex = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;

  // Cache control with longer expiration (30 minutes)
  static const Duration cacheExpiration = Duration(minutes: 30);
  DateTime? _lastPopularProductsUpdate;
  DateTime? _lastMerchantsUpdate;
  Timer? _cacheRefreshTimer;
  Timer? _debounceTimer;

  // Pagination control
  static const int _pageSize = 10;
  bool _isLoadingPopular = false;
  Completer<void>? _popularProductsCompleter;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;
  int _retryAttempts = 0;
  static const int maxRetries = 3;

  HomePageController({
    required this.productService,
    required this.merchantService,
    required CategoryService categoryService,
    required AuthService authService,
    required LocationService locationService,
  })  : _categoryService = categoryService,
        _authService = authService,
        _locationService = locationService {
    // Initialize listeners in constructor
    scrollController.addListener(_scrollListener);
    searchFocusNode.addListener(_onSearchFocusChange);
    _setupSearchListener();
  }

  @override
  void onInit() {
    super.onInit();
    _startCacheRefreshTimer();
    
    // Improved data loading logic
    if (!_isCacheExpired() && popularProducts.isNotEmpty && allMerchants.isNotEmpty) {
      // Use existing data if cache is valid
      isLoading.value = false;
      return;
    }
    
    // Load data only if cache expired or data is empty
    loadInitialData();
  }

  void _scrollListener() {
    if (!isLoadingMore.value && hasMoreData.value && scrollController.hasClients) {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      final delta = maxScroll * 0.2;

      if (maxScroll - currentScroll <= delta && _currentPage < _lastPage) {
        loadMoreMerchants();
      }
    }
  }

  void _onSearchFocusChange() {
    isSearching.value = searchFocusNode.hasFocus;
  }

  void _setupSearchListener() {
    searchController.addListener(() {
      if (searchController.text != searchQuery.value) {
        searchQuery.value = searchController.text;
        if (searchQuery.isNotEmpty) {
          _currentPage = 1;
          _debounceSearch();
        } else {
          searchResults.clear();
          merchantSearchResults.clear();
        }
      }
    });
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      performSearch();
    });
  }

  void _startCacheRefreshTimer() {
    _cacheRefreshTimer?.cancel();
    _cacheRefreshTimer = Timer.periodic(cacheExpiration, (timer) {
      if (!isRefreshing.value) {
        _refreshCachedData();
      }
    });
  }

  bool _isCacheExpired() {
    if (_lastPopularProductsUpdate == null || _lastMerchantsUpdate == null) {
      return true;
    }
    final now = DateTime.now();
    return now.difference(_lastPopularProductsUpdate!) > cacheExpiration ||
           now.difference(_lastMerchantsUpdate!) > cacheExpiration;
  }

  Future<void> _refreshCachedData() async {
    try {
      if (_isCacheExpired()) {
        await refreshProducts(showMessage: false);
      }
    } catch (e) {
      debugPrint('Background cache refresh error: $e');
    }
  }

  Future<void> loadAllMerchants() async {
    if (isLoadingMore.value) return;

    try {
      isLoadingMerchants.value = true;
      final locationData = await _locationService.getCurrentLocation();
      
      final paginatedResponse = await merchantService.getAllMerchants(
        page: _currentPage,
        pageSize: _pageSize,
        category: selectedCategory.value == "Semua" ? null : selectedCategory.value,
        latitude: locationData['latitude'],
        longitude: locationData['longitude'],
      );

      if (_currentPage == 1) {
        allMerchants.clear();
      }

      allMerchants.addAll(paginatedResponse.data);
      _lastPage = paginatedResponse.lastPage;
      _totalItems = paginatedResponse.total;
      hasMoreData.value = _currentPage < _lastPage;
      _lastMerchantsUpdate = DateTime.now();
      _retryAttempts = 0;
    } catch (e) {
      debugPrint('Error loading merchants: $e');
      if (_retryAttempts < maxRetries) {
        _retryAttempts++;
        await Future.delayed(Duration(seconds: _retryAttempts));
        return loadAllMerchants();
      }
    } finally {
      isLoadingMerchants.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreMerchants() async {
    if (isLoadingMore.value || _currentPage >= _lastPage) return;
    _currentPage++;
    await loadAllMerchants();
  }

  Future<void> performSearch() async {
    if (searchQuery.isEmpty) return;

    try {
      isLoadingMore.value = true;
      final locationData = await _locationService.getCurrentLocation();

      final merchantResponse = await merchantService.getAllMerchants(
        query: searchQuery.value,
        page: _currentPage,
        pageSize: _pageSize,
        latitude: locationData['latitude'],
        longitude: locationData['longitude'],
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
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> loadPopularProducts() async {
    if (_isLoadingPopular && _popularProductsCompleter != null) {
      return _popularProductsCompleter!.future;
    }

    try {
      isLoadingPopularProducts.value = true;
      _isLoadingPopular = true;
      _popularProductsCompleter = Completer<void>();

      // Check if we have valid cached data
      if (!_isCacheExpired() && popularProducts.isNotEmpty) {
        _popularProductsCompleter?.complete();
        return;
      }

      final paginatedResponse = await productService.getAllProducts(pageSize: 10);
      popularProducts.assignAll(paginatedResponse.data);
      _lastPopularProductsUpdate = DateTime.now();
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
    } finally {
      isLoadingPopularProducts.value = false;
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

      // Start location update in background
      _locationService.getCurrentLocation();

      // Clear cached data
      await Future.wait([
        productService.clearLocalStorage(),
        merchantService.clearLocalStorage(),
      ]);

      popularProducts.clear();
      allProducts.clear();
      searchResults.clear();
      merchantSearchResults.clear();
      allMerchants.clear();
      _categoryService.categories.clear();
      _currentPage = 1;
      _lastPage = 1;
      hasMoreData.value = true;

      // Load fresh data concurrently
      await Future.wait([
        loadPopularProducts(),
        loadAllMerchants(),
        _categoryService.getCategories(),
      ]);

      selectedCategory.value = "Semua";
      _lastPopularProductsUpdate = DateTime.now();
      _lastMerchantsUpdate = DateTime.now();

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

      // Start location update in background
      final locationFuture = _locationService.getCurrentLocation();

      // Load cached data first if available
      if (!_isCacheExpired() && popularProducts.isNotEmpty && allMerchants.isNotEmpty) {
        isLoading.value = false;
        return;
      }

      // Wait for location before loading merchants
      await locationFuture;
      
      // Load fresh data concurrently
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
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    _cacheRefreshTimer?.cancel();
    _debounceTimer?.cancel();
    super.onClose();
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
