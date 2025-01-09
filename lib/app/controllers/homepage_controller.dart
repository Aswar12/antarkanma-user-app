import 'dart:async';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/product_category_model.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
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
  final TextEditingController searchController = TextEditingController();

  // Pagination variables
  String? _currentCursor;
  String? _searchCursor;
  static const int _pageSize = 10;
  static const int _maxProducts = 300;
  bool _isInitialLoad = true;
  bool _isLoadingPopular = false;
  Completer<void>? _popularProductsCompleter;
  Timer? _scrollTimer;
  bool _noMoreData = false;
  Set<int> _loadedPages = {};
  int? _lastPage;
  int _currentPage = 1;

  // Getters
  List<ProductCategory> get categories => _categoryService.categories;
  bool get isCategoriesLoading => _categoryService.isLoading.value;
  List<ProductModel> get filteredProducts =>
      searchQuery.isEmpty ? allProducts : searchResults;
  bool get hasValidData => popularProducts.isNotEmpty && !isLoading.value;

  @override
  void onInit() {
    super.onInit();
    debugPrint('HomePageController: onInit');
    // Only load data if user is logged in and is a regular user
    if (_authService.isLoggedIn.value && _authService.currentUser.value?.role == 'USER') {
      loadInitialData();
    } else {
      isLoading.value = false;
    }
    _setupSearchListener();
  }

  @override
  void onClose() {
    searchController.dispose();
    _scrollTimer?.cancel();
    super.onClose();
  }

  void _setupSearchListener() {
    var debouncer = Debouncer(milliseconds: 500);
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      if (searchQuery.isNotEmpty) {
        debouncer.run(() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _searchCursor = null;
            hasMoreData.value = true;
            _noMoreData = false;
            _loadedPages.clear();
            _currentPage = 1;
            _lastPage = null;
            performSearch();
          });
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          searchResults.clear();
        });
      }
    });
  }

  Future<void> loadAllProducts() async {
    try {
      debugPrint('Loading all products...');
      final response = await productService.getAllProducts(
        pageSize: _pageSize,
        cursor: _currentCursor,
      );
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (response.data.isNotEmpty) {
          debugPrint('Loaded ${response.data.length} products');
          
          // Update last page information
          _lastPage = response.lastPage;
          debugPrint('Last page: $_lastPage');
          
          // For initial load or first page, use assignAll
          if (_currentPage == 1) {
            allProducts.assignAll(response.data);
          } else {
            // For subsequent pages, use addAll
            allProducts.addAll(response.data);
          }
          
          // Track this page as loaded
          _loadedPages.add(_currentPage);
          debugPrint('Added page $_currentPage to loaded pages');
          
          _currentCursor = response.nextCursor;
          _noMoreData = _currentPage >= _lastPage!;
          hasMoreData.value = !_noMoreData;
          
          debugPrint('Current page: $_currentPage of $_lastPage');
          debugPrint('Products loaded: ${allProducts.length}');
          debugPrint('Has more data: ${hasMoreData.value}');
          
          // Increment current page for next load if we haven't reached the last page
          if (!_noMoreData) {
            _currentPage++;
            // Automatically load next page if we haven't reached the last page
            if (_currentPage <= _lastPage!) {
              debugPrint('Automatically loading next page: $_currentPage');
              loadMoreProducts();
            }
          }
          
          if (_noMoreData) {
            debugPrint('No more data available: Reached last page $_lastPage');
          }
        } else {
          debugPrint('No products returned from service');
          _noMoreData = true;
          hasMoreData.value = false;
        }
      });
    } catch (e) {
      debugPrint('Error loading all products: $e');
      _noMoreData = true;
      hasMoreData.value = false;
    }
  }

  Future<void> loadMoreProducts() async {
    // Don't load more if we're already loading, have no more data, or reached the last page
    if (isLoadingMore.value || _noMoreData || (_lastPage != null && _currentPage > _lastPage!)) {
      debugPrint('Skip loading more: isLoadingMore=${isLoadingMore.value}, noMoreData=$_noMoreData, currentPage=$_currentPage, lastPage=$_lastPage');
      return;
    }

    // Check if we've already loaded this page
    if (_loadedPages.contains(_currentPage)) {
      debugPrint('Skip loading: Page $_currentPage already loaded');
      return;
    }

    // Cancel any existing timer
    _scrollTimer?.cancel();

    // Set a delay before loading more
    _scrollTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        debugPrint('Loading more products...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          isLoadingMore.value = true;
        });
        
        if (searchQuery.isEmpty) {
          await loadAllProducts();
        } else {
          await performSearch();
        }
      } catch (e) {
        debugPrint('Error loading more products: $e');
        _noMoreData = true;
        hasMoreData.value = false;
      } finally {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          isLoadingMore.value = false;
        });
      }
    });
  }

  Future<void> performSearch() async {
    if (searchQuery.isEmpty) return;

    try {
      if (_searchCursor == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          searchResults.clear();
          _loadedPages.clear();
        });
      }

      // Check if we've already loaded this page
      if (_loadedPages.contains(_currentPage)) {
        debugPrint('Skip loading: Page $_currentPage already loaded');
        return;
      }

      // Check if we've reached the last page
      if (_lastPage != null && _currentPage > _lastPage!) {
        debugPrint('Skip loading: Already at last page ($_lastPage)');
        _noMoreData = true;
        hasMoreData.value = false;
        return;
      }

      final apiResponse = await productService.getAllProducts(
        query: searchQuery.value,
        cursor: _searchCursor,
        pageSize: _pageSize,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (apiResponse.data.isNotEmpty) {
          // Update last page information
          _lastPage = apiResponse.lastPage;
          debugPrint('Last page updated: $_lastPage');

          final List<ProductModel> results = apiResponse.data;
          debugPrint('Search results: ${results.length} products found (Page $_currentPage of $_lastPage)');

          if (_searchCursor == null) {
            searchResults.assignAll(results);
          } else {
            searchResults.addAll(results);
          }

          // Track this page as loaded
          _loadedPages.add(_currentPage);

          _searchCursor = apiResponse.nextCursor;
          _currentPage++;
          
          // Check if we've reached the last page
          _noMoreData = _currentPage > _lastPage!;
          hasMoreData.value = !_noMoreData && searchResults.length < _maxProducts;
          
          // Automatically load next page if we haven't reached the last page
          if (!_noMoreData && _currentPage <= _lastPage!) {
            debugPrint('Automatically loading next page: $_currentPage');
            performSearch();
          }
          
          if (_noMoreData) {
            debugPrint('No more data available: Reached last page $_lastPage');
          }
        } else {
          debugPrint('No results found: Setting no more data');
          _noMoreData = true;
          hasMoreData.value = false;
        }
      });
    } catch (e) {
      debugPrint('Error performing search: $e');
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
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      });
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

  void updateCurrentIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (popularProducts.isNotEmpty) {
        currentIndex.value = index % popularProducts.length;
      } else {
        currentIndex.value = 0;
      }
    });
  }

  void updateSelectedCategory(String categoryName) async {
    if (categoryName == selectedCategory.value) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      selectedCategory.value = categoryName;
      searchController.clear();
      searchQuery.value = '';
      searchResults.clear();
      _currentCursor = null;
      _searchCursor = null;
      _noMoreData = false;
      hasMoreData.value = true;
      _loadedPages.clear();
      _currentPage = 1;
      _lastPage = null;
      await loadAllProducts();
    });
  }

  void checkAndPreloadNextPage() {
    // Only preload if:
    // 1. Not currently loading
    // 2. Has more data available
    // 3. Not marked as no more data
    // 4. Haven't loaded this page yet
    // 5. Haven't reached max products
    // 6. Haven't reached last page
    if (!isLoadingMore.value && 
        hasMoreData.value && 
        !_noMoreData && 
        !_loadedPages.contains(_currentPage) &&
        ((searchQuery.isEmpty && allProducts.length < _maxProducts) ||
         (searchQuery.isNotEmpty && searchResults.length < _maxProducts)) &&
        (_lastPage == null || _currentPage <= _lastPage!)) {
      debugPrint('Preloading next page...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadMoreProducts();
      });
    } else {
      debugPrint('Skip preloading: conditions not met');
    }
  }

  Future<void> refreshProducts({bool showMessage = true}) async {
    if (isRefreshing.value) return;

    try {
      debugPrint('Refreshing products...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isRefreshing(true);
      });
      
      // Clear all cached data
      await productService.clearLocalStorage();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _currentCursor = null;
        _searchCursor = null;
        _noMoreData = false;
        hasMoreData.value = true;
        popularProducts.clear();
        searchResults.clear();
        allProducts.clear();
        _categoryService.categories.clear();
        _isInitialLoad = true;
        _loadedPages.clear();
        _currentPage = 1;
        _lastPage = null;
      });

      // Load fresh data
      await Future.wait([
        loadPopularProducts(),
        loadAllProducts(),
        _categoryService.getCategories(),
      ]);

      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      });
    } catch (e) {
      debugPrint('Error refreshing products: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Error',
          'Gagal memperbarui data',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      });
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isRefreshing(false);
        isLoading(false);
      });
    }
  }

  Future<void> loadInitialData() async {
    try {
      debugPrint('Loading initial data...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading(true);
      });
      _isInitialLoad = true;
      _noMoreData = false;
      _loadedPages.clear();
      _currentPage = 1;
      _lastPage = null;
      
      await Future.wait([
        _categoryService.getCategories(),
        loadPopularProducts(),
        loadAllProducts(),
      ]);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        selectedCategory.value = "Semua";
        _isInitialLoad = false;
        debugPrint('Initial data loaded successfully');
      });
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isLoading(false);
      });
    }
  }
}
