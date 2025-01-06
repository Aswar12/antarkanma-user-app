import 'dart:convert';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/paginated_response.dart';
import 'package:antarkanma/app/data/providers/product_provider.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ProductService extends GetxService {
  final ProductProvider _productProvider = ProductProvider();
  final _storage = GetStorage();
  
  static const String _productsKey = 'products_by_page';
  static const String _lastRefreshKey = 'last_refresh';
  static const String _popularProductsKey = 'popular_products';
  static const String _pageMetadataKey = 'page_metadata';
  static const String _categoryMetadataKey = 'category_metadata';
  
  static const int maxStoredPages = 50;
  static const Duration cacheExpiration = Duration(minutes: 30);
  static const Duration requestThrottle = Duration(milliseconds: 500);
  
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;
  
  DateTime? _lastRequestTime;
  Map<String, DateTime> _lastCacheTime = {};
  bool _prefetchInProgress = false;

  @override
  void onInit() {
    super.onInit();
    debugPrint('ProductService: Initializing...');
    _initializeStorage();
  }

  void _initializeStorage() {
    _cleanExpiredCache();
  }

  Future<void> _cleanExpiredCache() async {
    try {
      final now = DateTime.now();
      final Map<String, dynamic> allPages = _storage.read(_productsKey) ?? {};
      
      allPages.removeWhere((key, _) {
        final lastAccess = _lastCacheTime[key];
        return lastAccess != null && now.difference(lastAccess) > cacheExpiration;
      });
      
      await _storage.write(_productsKey, allPages);
    } catch (e) {
      debugPrint('Error cleaning cache: $e');
    }
  }

  Future<PaginatedResponse<ProductModel>> getAllProducts({
    String? query,
    double? priceFrom,
    double? priceTo,
    int? categoryId,
    String? token,
    String? cursor,
    int pageSize = 10,
  }) async {
    try {
      debugPrint('Getting all products...');
      debugPrint('Parameters: query=$query, categoryId=$categoryId, cursor=$cursor');
      
      final response = await _productProvider.getAllProducts(
        query: query,
        priceFrom: priceFrom,
        priceTo: priceTo,
        categoryId: categoryId,
        token: token,
        cursor: cursor,
        pageSize: pageSize,
      );

      if (response.statusCode == 200) {
        debugPrint('Response received successfully');
        final paginatedResponse = PaginatedResponse<ProductModel>.fromJson(
          response.data,
          (json) => ProductModel.fromJson(json as Map<String, dynamic>),
        );

        if (paginatedResponse.data.isNotEmpty) {
          debugPrint('Parsed ${paginatedResponse.data.length} products');
          await addProductToLocal(cursor ?? 'initial', paginatedResponse.data);
        } else {
          debugPrint('No products found in response');
        }

        return paginatedResponse;
      } else {
        debugPrint('Response status code: ${response.statusCode}');
        throw Exception('Failed to fetch products');
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting all products: $e');
      debugPrint('Stack trace: $stackTrace');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to load products',
        isError: true,
      );
      rethrow;
    }
  }

  Future<void> addProductToLocal(dynamic key, List<ProductModel> products) async {
    try {
      debugPrint('Adding ${products.length} products to local storage');
      final storageKey = key.toString();
      final Map<String, dynamic> allPages = _storage.read(_productsKey) ?? {};
      
      final String compressedData = jsonEncode(products.map((p) => p.toJson()).toList());
      allPages[storageKey] = compressedData;
      
      if (allPages.length > maxStoredPages) {
        _removeOldestPages(allPages);
      }
      
      await _storage.write(_productsKey, allPages);
      _lastCacheTime[storageKey] = DateTime.now();
      debugPrint('Successfully added products to local storage');
    } catch (e) {
      debugPrint('Error adding products to local storage: $e');
    }
  }

  void _removeOldestPages(Map<String, dynamic> allPages) {
    final sortedEntries = _lastCacheTime.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    while (allPages.length > maxStoredPages && sortedEntries.isNotEmpty) {
      final oldestKey = sortedEntries.removeAt(0).key;
      allPages.remove(oldestKey);
      _lastCacheTime.remove(oldestKey);
    }
  }

  List<ProductModel> getAllProductsFromStorage() {
    try {
      debugPrint('Getting all products from storage');
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
        
        debugPrint('Found ${uniqueProducts.length} products in storage');
        return uniqueProducts.toList();
      }
    } catch (e) {
      debugPrint('Error getting products from storage: $e');
    }
    return [];
  }

  Future<void> clearLocalStorage() async {
    try {
      debugPrint('Clearing local storage');
      await _storage.remove(_productsKey);
      await _storage.remove(_lastRefreshKey);
      await _storage.remove(_popularProductsKey);
      await _storage.remove(_pageMetadataKey);
      await _storage.remove(_categoryMetadataKey);
      _lastCacheTime.clear();
      products.clear();
      debugPrint('Local storage cleared successfully');
    } catch (e) {
      debugPrint('Error clearing local storage: $e');
    }
  }
}
