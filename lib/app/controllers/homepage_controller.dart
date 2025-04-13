import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/models/product_category_model.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/location_service.dart';
import 'package:antarkanma/app/services/osrm_service.dart';

class HomePageController extends GetxController {
  final ProductService productService;
  final MerchantService merchantService;
  final CategoryService _categoryService;
  final AuthService _authService;
  final LocationService _locationService;
  final OSRMService _osrmService = Get.find<OSRMService>();

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
  final RxBool isSkeletonLoading = false.obs;
  final RxBool isCalculatingDistances = false.obs;

  // UI states with persistence
  final RxString selectedCategory = "Semua".obs;
  final RxInt currentIndex = 0.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;

  // Cache control
  static const Duration cacheExpiration = Duration(days: 2);
  DateTime? _lastPopularProductsUpdate;
  DateTime? _lastMerchantsUpdate;
  Timer? _cacheRefreshTimer;
  Timer? _debounceTimer;

  // Pagination control
  static const int _pageSize = 20;
  bool _isLoadingPopular = false;
  Completer<void>? _popularProductsCompleter;
  int _currentPage = 1;
  int _lastPage = 1;
  int _totalItems = 0;
  int _retryAttempts = 0;
  static const int maxRetries = 3;

  // Cache size control
  static const int maxCachedProducts = 200;
  static const int maxCachedMerchants = 100;

  HomePageController({
    required this.productService,
    required this.merchantService,
    required CategoryService categoryService,
    required AuthService authService,
    required LocationService locationService,
  })  : _categoryService = categoryService,
        _authService = authService,
        _locationService = locationService {
    scrollController.addListener(_scrollListener);
    searchFocusNode.addListener(_onSearchFocusChange);
    _setupSearchListener();
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
          _sortMerchantsByDistance(allMerchants);
          allMerchants.refresh();
        }
      }
    });
  }

  void _startCacheRefreshTimer() {
    _cacheRefreshTimer?.cancel();
    _cacheRefreshTimer = Timer.periodic(const Duration(hours: 12), (timer) {
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

  void _scrollListener() {
    if (!isLoadingMore.value &&
        hasMoreData.value &&
        scrollController.hasClients) {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      final delta = maxScroll * 0.2;

      if (maxScroll - currentScroll <= delta && _currentPage < _lastPage) {
        loadMoreMerchants();
      }
    }
  }

  Future<void> loadAllMerchants() async {
    if (isLoadingMore.value) return;

    try {
      isLoadingMerchants.value = true;

      final paginatedResponse = await merchantService.getAllMerchants(
        page: _currentPage,
        pageSize: _pageSize,
        category: selectedCategory.value == "Semua" ? null : selectedCategory.value,
      );

      if (_currentPage == 1) {
        allMerchants.clear();
      }

      final newMerchants = paginatedResponse.data;
      _lastPage = paginatedResponse.lastPage;
      _totalItems = paginatedResponse.total;
      hasMoreData.value = _currentPage < _lastPage;
      _lastMerchantsUpdate = DateTime.now();

      allMerchants.addAll(newMerchants);
      allMerchants.refresh();

      if (_currentPage == 1) {
        _calculateDistancesInBackground(newMerchants);
      }

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

  Future<void> _calculateDistancesInBackground(List<MerchantModel> merchants) async {
    try {
      isCalculatingDistances.value = true;

      final locationData = await _locationService.getCurrentLocation(forceUpdate: true)
          .timeout(const Duration(seconds: 15));
      
      if (locationData['isDefault'] == true) return;

      final userLat = locationData['latitude'] as double;
      final userLng = locationData['longitude'] as double;

      final visibleMerchants = merchants.take(_pageSize).toList();
      if (visibleMerchants.every((m) => m.distance != null)) return;

      final destinations = visibleMerchants
          .where((m) =>
              m.latitude != null && m.longitude != null && m.distance == null)
          .map((m) => {
                'id': m.id,
                'latitude': m.latitude!,
                'longitude': m.longitude!,
              })
          .toList();

      if (destinations.isEmpty) return;

      final results = await _osrmService.calculateBatchDistances(
        userLat,
        userLng,
        destinations,
      );

      for (var result in results) {
        final merchantId = result['merchant_id'];
        final distance = result['distance'];
        final duration = result['duration'];

        final index = allMerchants.indexWhere((m) => m.id == merchantId);
        if (index != -1) {
          final merchant = allMerchants[index];
          allMerchants[index] = MerchantModel(
            id: merchant.id,
            name: merchant.name,
            address: merchant.address,
            phoneNumber: merchant.phoneNumber,
            status: merchant.status,
            description: merchant.description,
            logo: merchant.logo,
            logoUrl: merchant.logoUrl,
            openingTime: merchant.openingTime,
            closingTime: merchant.closingTime,
            operatingDays: merchant.operatingDays,
            latitude: merchant.latitude,
            longitude: merchant.longitude,
            distance: distance,
            duration: duration.round(),
            stats: merchant.stats,
            totalProducts: merchant.totalProducts,
          );
        }
      }

      _sortVisibleMerchants();
      allMerchants.refresh();
    } catch (e) {
      debugPrint('Error calculating distances in background: $e');
    }
  }

  void _sortMerchantsByDistance(List<MerchantModel> merchants) {
    merchants.sort((a, b) {
      final distanceA = a.distance ?? double.infinity;
      final distanceB = b.distance ?? double.infinity;
      return distanceA.compareTo(distanceB);
    });
  }

  void _sortVisibleMerchants() {
    final visibleMerchants = allMerchants.take(_pageSize).toList();
    visibleMerchants.sort((a, b) {
      final distanceA = a.distance ?? double.infinity;
      final distanceB = b.distance ?? double.infinity;
      return distanceA.compareTo(distanceB);
    });

    for (var i = 0; i < visibleMerchants.length; i++) {
      if (i < allMerchants.length) {
        allMerchants[i] = visibleMerchants[i];
      }
    }
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      isSkeletonLoading.value = true;
      _currentPage = 1;
      _lastPage = 1;
      hasMoreData.value = true;
      _retryAttempts = 0;

      _locationService.init();

      await loadAllMerchants();

      await Future.wait([
        loadPopularProducts(),
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
      isSkeletonLoading.value = false;
    }
  }

  Future<void> loadMoreMerchants() async {
    if (isLoadingMore.value || _currentPage >= _lastPage) return;
    _currentPage++;
    await loadAllMerchants();
  }

  Future<void> loadPopularProducts() async {
    if (_isLoadingPopular && _popularProductsCompleter != null) {
      return _popularProductsCompleter!.future;
    }

    try {
      isLoadingPopularProducts.value = true;
      _isLoadingPopular = true;
      _popularProductsCompleter = Completer<void>();

      if (!_isCacheExpired() && popularProducts.isNotEmpty) {
        _popularProductsCompleter?.complete();
        return;
      }

      final paginatedResponse =
          await productService.getAllProducts(pageSize: maxCachedProducts);

      popularProducts
          .assignAll(paginatedResponse.data.take(maxCachedProducts).toList());
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
    searchResults.clear();
    _currentPage = 1;
    hasMoreData.value = true;
    await loadAllMerchants();
  }

  void _debounceSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      performSearch();
    });
  }

  Future<void> performSearch() async {
    if (searchQuery.isEmpty) return;

    try {
      isLoadingMore.value = true;

      // Search for merchants
      final merchantPaginatedResponse = await merchantService.getAllMerchants(
        query: searchQuery.value,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (_currentPage == 1) {
        merchantSearchResults.clear();
        searchResults.clear();
      }

      final newMerchantResults = merchantPaginatedResponse.data;
      final searchTerm = searchQuery.value.toLowerCase().trim();
      
      final filteredMerchantResults = newMerchantResults.where((merchant) {
        final name = merchant.name.toLowerCase();
        final address = (merchant.address ?? '').toLowerCase();
        return name.contains(searchTerm) || address.contains(searchTerm);
      }).toList();

      merchantSearchResults.addAll(filteredMerchantResults);
      _calculateDistancesInBackground(filteredMerchantResults);

      // Search for products
      final productPaginatedResponse = await productService.getAllProducts(
        query: searchQuery.value,
        page: _currentPage,
        pageSize: _pageSize,
      );

      final filteredProductResults = productPaginatedResponse.data.where((product) {
        final name = product.name.toLowerCase();
        final description = (product.description ?? '').toLowerCase();
        return name.contains(searchTerm) || description.contains(searchTerm);
      }).toList();

      searchResults.addAll(filteredProductResults);

      _lastPage = merchantPaginatedResponse.lastPage;
      _totalItems = merchantPaginatedResponse.total;
      hasMoreData.value = _currentPage < _lastPage;

    } catch (e) {
      debugPrint('Error performing search: $e');
    } finally {
      isLoadingMore.value = false;
    }
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

  Future<void> refreshProducts({bool showMessage = true}) async {
    if (isRefreshing.value) return;

    try {
      isRefreshing.value = true;
      isSkeletonLoading.value = true;
      _retryAttempts = 0;

      popularProducts.clear();
      allProducts.clear();
      searchResults.clear();
      allMerchants.clear();
      merchantSearchResults.clear();
      _categoryService.categories.clear();

      _currentPage = 1;
      _lastPage = 1;
      hasMoreData.value = true;
      selectedCategory.value = "Semua";
      searchController.clear();
      searchQuery.value = '';

      await Future.wait([
        productService.clearLocalStorage(),
        merchantService.clearLocalStorage(),
      ]);

      await Future.wait([
        loadPopularProducts(),
        loadAllMerchants(),
        _categoryService.getCategories(),
      ]);

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
      isSkeletonLoading.value = false;
    }
  }

  List<ProductCategory> get categories => _categoryService.categories;
  bool get isCategoriesLoading => _categoryService.isLoading.value;
  List<ProductModel> get filteredProducts =>
      searchQuery.isEmpty ? allProducts : searchResults;
  List<MerchantModel> get filteredMerchants =>
      searchQuery.isEmpty ? allMerchants : merchantSearchResults;
  bool get hasValidData => popularProducts.isNotEmpty && !isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _startCacheRefreshTimer();
    loadInitialData();
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
}
