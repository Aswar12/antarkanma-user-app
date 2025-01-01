import 'dart:convert';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/data/providers/product_provider.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:dio/dio.dart' as dio;

class PageMetadata {
  final int page;
  final DateTime lastAccess;
  final int accessCount;
  final String category;

  PageMetadata({
    required this.page,
    required this.lastAccess,
    required this.accessCount,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'page': page,
        'lastAccess': lastAccess.toIso8601String(),
        'accessCount': accessCount,
        'category': category,
      };

  factory PageMetadata.fromJson(Map<String, dynamic> json) => PageMetadata(
        page: json['page'],
        lastAccess: DateTime.parse(json['lastAccess']),
        accessCount: json['accessCount'],
        category: json['category'],
      );
}

class ProductService extends GetxService {
  final ProductProvider _productProvider = ProductProvider();
  final _storage = GetStorage();
  
  // Storage keys
  static const String _productsKey = 'products_by_page';
  static const String _lastRefreshKey = 'last_refresh';
  static const String _popularProductsKey = 'popular_products';
  static const String _pageMetadataKey = 'page_metadata';
  static const String _categoryMetadataKey = 'category_metadata';
  
  // Constants for optimization
  static const int maxStoredPages = 50;
  static const Duration cacheExpiration = Duration(hours: 1);
  static const Duration requestThrottle = Duration(milliseconds: 500);
  static const int preloadThreshold = 8; // Preload when 8th item is visible
  
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  
  DateTime? _lastRequestTime;
  Map<String, Map<int, PageMetadata>> _pageMetadata = {};
  bool _prefetchInProgress = false;
  Map<String, int> _categoryLastPage = {};

  @override
  void onInit() {
    super.onInit();
    _initializeStorage();
    _loadMetadata();
  }

  void _initializeStorage() {
    _cleanExpiredCache();
  }

  void _loadMetadata() {
    try {
      final storedMetadata = _storage.read(_categoryMetadataKey);
      if (storedMetadata != null) {
        _categoryLastPage = Map<String, int>.from(storedMetadata);
      }
    } catch (e) {
      print('Error loading metadata: $e');
    }
  }

  Future<void> _cleanExpiredCache() async {
    try {
      final now = DateTime.now();
      bool needsUpdate = false;
      
      _pageMetadata.forEach((category, pages) {
        pages.removeWhere((page, metadata) {
          final expired = now.difference(metadata.lastAccess) > cacheExpiration;
          if (expired) needsUpdate = true;
          return expired;
        });
      });
      
      if (needsUpdate) {
        await _saveMetadata();
        _cleanupStoragePages();
      }
    } catch (e) {
      print('Error cleaning cache: $e');
    }
  }

  Future<void> _cleanupStoragePages() async {
    try {
      final Map<String, dynamic> allPages = _storage.read(_productsKey) ?? {};
      final validPages = _pageMetadata.values
          .expand((pages) => pages.keys)
          .map((page) => page.toString())
          .toSet();
      
      allPages.removeWhere((page, _) => !validPages.contains(page));
      await _storage.write(_productsKey, allPages);
    } catch (e) {
      print('Error cleaning storage pages: $e');
    }
  }

  Future<void> _prefetchNextPage(int currentPage, String category, int pageSize) async {
    if (_prefetchInProgress) return;

    try {
      _prefetchInProgress = true;
      final nextPage = currentPage + 1;
      
      // Check if we already have this page cached
      if (_getPageFromStorage(nextPage, category) != null) {
        return;
      }
      
      await _fetchFromBackend(nextPage, pageSize, category: category, isPrefetch: true);
    } catch (e) {
      print('Error prefetching next page: $e');
    } finally {
      _prefetchInProgress = false;
    }
  }

  Future<void> addProductToLocal(int page, List<ProductModel> products, {String category = 'all'}) async {
    try {
      await _savePageToStorage(page, products, category);
    } catch (e) {
      print('Error adding products to local storage: $e');
    }
  }

  Future<dio.Response<dynamic>> getAllProducts({
    String? query,
    double? priceFrom,
    double? priceTo,
    int? categoryId,
    String? token,
    int page = 1,
    int pageSize = 10,
  }) async {
    if (query?.isNotEmpty == true) {
      // For search, try local first if query length > 2
      if (query!.length > 2) {
        final localResults = _searchLocalProducts(query);
        if (localResults.isNotEmpty) {
          return dio.Response(
            data: {'data': localResults.map((p) => p.toJson()).toList()},
            statusCode: 200,
            requestOptions: dio.RequestOptions(path: ''),
          );
        }
      }
    }

    return await _productProvider.getAllProducts(
      query: query,
      priceFrom: priceFrom,
      priceTo: priceTo,
      categoryId: categoryId,
      token: token,
      page: page,
      pageSize: pageSize,
    );
  }

  List<ProductModel> _searchLocalProducts(String query) {
    final allProducts = getAllProductsFromStorage();
    final lowercaseQuery = query.toLowerCase();
    return allProducts.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
             product.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Future<dio.Response<dynamic>> fetchProducts({
    int page = 1,
    int pageSize = 10,
    String category = 'all'
  }) async {
    try {
      if (_lastRequestTime != null) {
        final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
        if (timeSinceLastRequest < requestThrottle) {
          await Future.delayed(requestThrottle - timeSinceLastRequest);
        }
      }

      isLoading.value = true;
      
      // Try to get from cache first
      final cachedProducts = _getPageFromStorage(page, category);
      if (cachedProducts != null) {
        print('Loading page $page from cache for category $category');
        products.value = cachedProducts;
        
        // Start prefetching next page if we're at the threshold
        if (cachedProducts.length >= preloadThreshold) {
          _prefetchNextPage(page, category, pageSize);
        }
        
        isLoading.value = false;
        return await _productProvider.getAllProducts(page: page, pageSize: pageSize);
      }

      return await _fetchFromBackend(page, pageSize, category: category);
      
    } catch (e) {
      print('Error in fetchProducts: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to load products: ${e.toString()}',
        isError: true,
      );
      rethrow;
    } finally {
      isLoading.value = false;
      _lastRequestTime = DateTime.now();
    }
  }

  Future<dio.Response<dynamic>> _fetchFromBackend(
    int page,
    int pageSize, {
    String category = 'all',
    bool isPrefetch = false
  }) async {
    try {
      final response = await _productProvider.getAllProducts(
        page: page,
        pageSize: pageSize,
        categoryId: category == 'all' ? null : int.tryParse(category),
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        final List<ProductModel> pageProducts = productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();

        await _savePageToStorage(page, pageProducts, category);
        _updateCategoryLastPage(category, page);

        if (!isPrefetch) {
          products.value = pageProducts;
        }
      }
      return response;
    } catch (e) {
      print('Error fetching from backend: $e');
      if (!isPrefetch) {
        showCustomSnackbar(
          title: 'Error',
          message: 'Failed to load products: ${e.toString()}',
          isError: true,
        );
      }
      rethrow;
    }
  }

  void _updateCategoryLastPage(String category, int page) {
    _categoryLastPage[category] = page;
    _storage.write(_categoryMetadataKey, _categoryLastPage);
  }

  List<ProductModel>? _getPageFromStorage(int page, String category) {
    try {
      final Map<String, dynamic>? allPages = _storage.read(_productsKey);
      final String pageKey = '${category}_$page';
      
      if (allPages != null && allPages.containsKey(pageKey)) {
        final String compressedData = allPages[pageKey];
        final List<dynamic> pageProducts = jsonDecode(compressedData);
        
        _updatePageMetadata(page, category);
        
        return pageProducts
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error getting page $page from storage: $e');
    }
    return null;
  }

  Future<void> _updatePageMetadata(int page, String category) async {
    try {
      if (!_pageMetadata.containsKey(category)) {
        _pageMetadata[category] = {};
      }
      
      _pageMetadata[category]![page] = PageMetadata(
        page: page,
        lastAccess: DateTime.now(),
        accessCount: (_pageMetadata[category]?[page]?.accessCount ?? 0) + 1,
        category: category,
      );
      
      await _saveMetadata();
    } catch (e) {
      print('Error updating page metadata: $e');
    }
  }

  Future<void> _saveMetadata() async {
    try {
      final Map<String, dynamic> serializedMetadata = {};
      _pageMetadata.forEach((category, pages) {
        serializedMetadata[category] = pages.map(
          (page, metadata) => MapEntry(page.toString(), metadata.toJson())
        );
      });
      await _storage.write(_pageMetadataKey, serializedMetadata);
    } catch (e) {
      print('Error saving metadata: $e');
    }
  }

  Future<void> _savePageToStorage(int page, List<ProductModel> pageProducts, String category) async {
    try {
      final Map<String, dynamic> allPages = _storage.read(_productsKey) ?? {};
      final String pageKey = '${category}_$page';
      
      final String compressedData = jsonEncode(pageProducts.map((p) => p.toJson()).toList());
      allPages[pageKey] = compressedData;
      
      if (allPages.length > maxStoredPages) {
        _removeOldestPages(allPages);
      }
      
      await _storage.write(_productsKey, allPages);
      await _updatePageMetadata(page, category);
    } catch (e) {
      print('Error saving page $page to storage: $e');
    }
  }

  void _removeOldestPages(Map<String, dynamic> allPages) {
    // Find pages with oldest access times across all categories
    final allMetadata = _pageMetadata.values
        .expand((pages) => pages.entries)
        .toList()
      ..sort((a, b) => a.value.lastAccess.compareTo(b.value.lastAccess));
    
    while (allPages.length > maxStoredPages && allMetadata.isNotEmpty) {
      final oldestEntry = allMetadata.removeAt(0);
      final pageKey = '${oldestEntry.value.category}_${oldestEntry.key}';
      allPages.remove(pageKey);
      _pageMetadata[oldestEntry.value.category]?.remove(oldestEntry.key);
    }
  }

  Future<List<ProductModel>> getProductsByCategory(int categoryId, {required int pageSize, required int page}) async {
    final category = categoryId.toString();
    try {
      // Check cache first
      final cachedProducts = _getPageFromStorage(page, category);
      if (cachedProducts != null) {
        if (cachedProducts.length >= preloadThreshold) {
          _prefetchNextPage(page, category, pageSize);
        }
        return cachedProducts;
      }

      final response = await _productProvider.getProductsByCategory(
        categoryId,
        page: page,
        pageSize: pageSize,
      );
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        final products = productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
            
        await addProductToLocal(page, products, category: category);
        return products;
      }
    } catch (e) {
      print('Error getting products by category: $e');
    }
    return [];
  }

  Future<List<ProductModel>> getPopularProducts({
    int? limit,
    int? categoryId,
    double minRating = 4.0,
    int minReviews = 5,
  }) async {
    try {
      final response = await _productProvider.getPopularProducts(
        limit: limit,
        categoryId: categoryId,
        minRating: minRating,
        minReviews: minReviews,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        final List<ProductModel> popularProducts = productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();

        await _storage.write(
            _popularProductsKey, popularProducts.map((p) => p.toJson()).toList());

        return popularProducts;
      }
      return _getPopularProductsFromStorage();
    } catch (e) {
      print('Error in getPopularProducts: $e');
      return _getPopularProductsFromStorage();
    }
  }

  List<ProductModel> getAllProductsFromStorage() {
    try {
      final Map<String, dynamic>? allPages = _storage.read(_productsKey);
      if (allPages != null) {
        final Set<ProductModel> uniqueProducts = {};
        
        allPages.forEach((pageKey, compressedData) {
          final List<dynamic> pageProducts = jsonDecode(compressedData);
          uniqueProducts.addAll(
            pageProducts
                .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
                .toList()
          );
        });
        
        return uniqueProducts.toList();
      }
    } catch (e) {
      print('Error getting all products from storage: $e');
    }
    return [];
  }

  List<ProductModel> _getPopularProductsFromStorage() {
    try {
      final storedProducts = _storage.read(_popularProductsKey);
      if (storedProducts != null) {
        final List<dynamic> productList = storedProducts;
        return productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error getting popular products from storage: $e');
    }
    return [];
  }

  Future<void> clearLocalStorage() async {
    await _storage.remove(_productsKey);
    await _storage.remove(_lastRefreshKey);
    await _storage.remove(_popularProductsKey);
    await _storage.remove(_pageMetadataKey);
    await _storage.remove(_categoryMetadataKey);
    _pageMetadata.clear();
    _categoryLastPage.clear();
    products.clear();
  }
}
