import 'dart:convert';
import 'package:antarkanma/app/data/providers/merchant_provider.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

class MerchantService {
  final MerchantProvider _merchantProvider = MerchantProvider();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService.instance;
  final ProductService _productService = Get.find<ProductService>();
  final _storage = GetStorage();

  // Storage keys
  static const String _merchantProductsKey = 'merchant_products_by_page';
  static const String _merchantProductsMetadataKey =
      'merchant_products_metadata';
  static const String _lastRefreshKey = 'merchant_last_refresh';

  // Optimization constants
  static const int maxStoredPages = 20;
  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration requestThrottle = Duration(milliseconds: 500);

  DateTime? _lastRequestTime;
  Map<int, DateTime> _pageLastAccess = {};
  bool _prefetchInProgress = false;

  get token => _authService.getToken();
  Map<String, dynamic>? get user => _storageService.getUser();
  int? get ownerId =>
      user != null ? int.tryParse(user!['id'].toString()) : null;

  MerchantModel? _currentMerchant;

  Future<MerchantModel?> getMerchant() async {
    try {
      if (ownerId == null) {
        throw Exception(
            "Owner ID is null. User must be logged in to fetch merchant.");
      }

      final response =
          await _merchantProvider.getMerchantsByOwnerId(token, ownerId!);

      if (response.data != null &&
          response.data['data'] is List &&
          response.data['data'].isNotEmpty) {
        _currentMerchant = MerchantModel.fromJson(response.data['data'][0]);
        return _currentMerchant;
      }
      return null;
    } catch (e) {
      print('Error fetching merchant: $e');
      return null;
    }
  }

  Future<List<ProductModel>> getMerchantProducts(
      {int page = 1, int pageSize = 10}) async {
    try {
      if (_currentMerchant?.id == null) {
        final merchant = await getMerchant();
        if (merchant == null) {
          throw Exception('Failed to get merchant information');
        }
      }

      // Check request throttling
      if (_lastRequestTime != null) {
        final timeSinceLastRequest =
            DateTime.now().difference(_lastRequestTime!);
        if (timeSinceLastRequest < requestThrottle) {
          await Future.delayed(requestThrottle - timeSinceLastRequest);
        }
      }

      // Try to get from cache first
      final cachedProducts = _getPageFromStorage(page);
      if (cachedProducts != null) {
        print('Loading merchant products page $page from cache');
        _prefetchNextPage(page, pageSize);
        return cachedProducts;
      }

      // If not in cache, fetch from backend
      final response = await _merchantProvider.getMerchantProducts(
        token,
        _currentMerchant!.id!,
        page: page,
        pageSize: pageSize,
      );

      if (response.data != null &&
          response.data['meta'] != null &&
          response.data['meta']['status'] == 'success' &&
          response.data['data'] != null &&
          response.data['data']['data'] is List) {
        final productsData = response.data['data']['data'] as List;
        final products =
            productsData.map((json) => ProductModel.fromJson(json)).toList();

        // Save to cache
        await _savePageToStorage(page, products);

        // Prefetch next page
        _prefetchNextPage(page, pageSize);

        return products;
      }

      print('Unexpected response structure: ${response.data}');
      return [];
    } catch (e) {
      print('Error fetching merchant products: $e');
      return [];
    } finally {
      _lastRequestTime = DateTime.now();
    }
  }

  Future<bool> createProduct(
      Map<String, dynamic> productData, List<XFile> images) async {
    try {
      if (_currentMerchant?.id == null) {
        final merchant = await getMerchant();
        if (merchant == null) {
          throw Exception('Failed to get merchant information');
        }
      }

      final productResponse = await _merchantProvider.createProduct(
        token,
        _currentMerchant!.id!,
        productData,
      );

      if (productResponse.data == null ||
          productResponse.data['meta'] == null ||
          productResponse.data['meta']['status'] != 'success') {
        throw Exception(productResponse.data?['meta']?['message'] ??
            'Failed to create product');
      }

      final createdProductData = productResponse.data['data'];
      final productId = createdProductData['id'];

      if (images.isNotEmpty) {
        final imagePaths = images.map((image) => image.path).toList();
        final galleryResponse = await _merchantProvider.uploadProductGallery(
          token,
          productId,
          imagePaths,
        );

        if (galleryResponse.data == null ||
            galleryResponse.data['meta'] == null ||
            galleryResponse.data['meta']['status'] != 'success') {
          throw Exception(galleryResponse.data?['meta']?['message'] ??
              'Failed to upload gallery');
        }

        if (galleryResponse.data['data'] != null) {
          createdProductData['gallery'] = galleryResponse.data['data'];
        }
      }

      final product = ProductModel.fromJson(createdProductData);
      await _productService.addProductToLocal(1, [product]); // Add to first page
      await clearCache(); // Clear cache to force refresh of merchant products
      return true;
    } catch (e) {
      print('Error creating product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(int productId, Map<String, dynamic> productData,
      List<XFile> newImages) async {
    try {
      if (_currentMerchant?.id == null) {
        final merchant = await getMerchant();
        if (merchant == null) {
          throw Exception('Failed to get merchant information');
        }
      }

      final productResponse = await _merchantProvider.updateProduct(
        token,
        productId,
        productData,
      );

      if (productResponse.data == null ||
          productResponse.data['meta'] == null ||
          productResponse.data['meta']['status'] != 'success') {
        throw Exception(productResponse.data?['meta']?['message'] ??
            'Failed to update product');
      }

      if (newImages.isNotEmpty) {
        final imagePaths = newImages.map((image) => image.path).toList();
        final galleryResponse = await _merchantProvider.uploadProductGallery(
          token,
          productId,
          imagePaths,
        );

        if (galleryResponse.data == null ||
            galleryResponse.data['meta'] == null ||
            galleryResponse.data['meta']['status'] != 'success') {
          throw Exception(galleryResponse.data?['meta']?['message'] ??
              'Failed to upload gallery');
        }
      }

      await clearCache(); // Clear cache to force refresh of merchant products
      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> updateProductGallery(
      int productId, int galleryId, String imagePath) async {
    try {
      final response = await _merchantProvider.updateProductGallery(
        token,
        productId,
        galleryId,
        imagePath,
      );

      if (response.data != null &&
          response.data['meta'] != null &&
          response.data['meta']['status'] == 'success') {
        await clearCache(); // Clear cache to force refresh
        return {
          'success': true,
          'message': response.data['meta']['message'] ??
              'Gallery image updated successfully',
          'data': response.data['data']
        };
      } else {
        return {
          'success': false,
          'message': response.data?['meta']?['message'] ??
              'Failed to update gallery image'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error updating gallery image: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteProductGallery(
      int productId, int galleryId) async {
    try {
      final response = await _merchantProvider.deleteProductGallery(
        token,
        productId,
        galleryId,
      );

      if (response.data != null &&
          response.data['meta'] != null &&
          response.data['meta']['status'] == 'success') {
        await clearCache(); // Clear cache to force refresh
        return {
          'success': true,
          'message': response.data['meta']['message'] ??
              'Gallery image deleted successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data?['meta']?['message'] ??
              'Failed to delete gallery image'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error deleting gallery image: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      final response = await _merchantProvider.deleteProduct(token, productId);

      if (response.data != null &&
          response.data['meta'] != null &&
          response.data['meta']['status'] == 'success') {
        await clearCache(); // Clear cache to force refresh
        return {
          'success': true,
          'message':
              response.data['meta']['message'] ?? 'Product deleted successfully'
        };
      } else {
        return {
          'success': false,
          'message':
              response.data?['meta']?['message'] ?? 'Failed to delete product'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error deleting product: $e'};
    }
  }

  Future<bool> updateOperationalHours(String openingTime, String closingTime,
      List<String> operatingDays) async {
    try {
      if (openingTime.isEmpty || closingTime.isEmpty || operatingDays.isEmpty) {
        print('Validation error: All fields must be filled');
        return false;
      }

      final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
      if (!timeRegex.hasMatch(openingTime) ||
          !timeRegex.hasMatch(closingTime)) {
        print('Validation error: Invalid time format. Use HH:mm');
        return false;
      }

      if (_currentMerchant?.id == null) {
        print('Error: Merchant ID not found');
        return false;
      }

      final payload = {
        'opening_time': openingTime,
        'closing_time': closingTime,
        'operating_days': operatingDays,
      };

      final response = await _merchantProvider.updateMerchant(
          token, _currentMerchant!.id!, payload);

      if (response.data != null &&
          response.data['meta'] != null &&
          response.data['meta']['status'] == 'success') {
        print('Operational hours updated successfully');
        return true;
      } else {
        print(
            'Failed to update operational hours: ${response.data?['meta']?['message']}');
        return false;
      }
    } catch (e) {
      print('Error updating operational hours: $e');
      return false;
    }
  }

  Future<bool> updateMerchantDetails({
    String? name,
    String? address,
    String? phoneNumber,
    String? description,
  }) async {
    try {
      if (_currentMerchant?.id == null) {
        print('Error: Merchant ID not found');
        return false;
      }

      final payload = {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (description != null) 'description': description,
      };

      if (payload.isEmpty) {
        print('No data to update');
        return false;
      }

      final response = await _merchantProvider.updateMerchant(
          token, _currentMerchant!.id!, payload);

      if (response.data != null &&
          response.data['meta'] != null &&
          response.data['meta']['status'] == 'success') {
        print('Merchant details updated successfully');
        return true;
      } else {
        print(
            'Failed to update merchant details: ${response.data?['meta']?['message']}');
        return false;
      }
    } catch (e) {
      print('Error updating merchant details: $e');
      return false;
    }
  }

  // Cache management methods
  Future<void> _prefetchNextPage(int currentPage, int pageSize) async {
    if (_prefetchInProgress) return;

    try {
      _prefetchInProgress = true;
      final nextPage = currentPage + 1;

      if (_getPageFromStorage(nextPage) != null) return;

      await getMerchantProducts(page: nextPage, pageSize: pageSize);
    } finally {
      _prefetchInProgress = false;
    }
  }

  List<ProductModel>? _getPageFromStorage(int page) {
    try {
      final Map<String, dynamic>? allPages =
          _storage.read(_merchantProductsKey);
      if (allPages != null && allPages.containsKey(page.toString())) {
        final String compressedData = allPages[page.toString()];
        final List<dynamic> pageProducts = jsonDecode(compressedData);

        _updatePageMetadata(page);

        return pageProducts
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error getting page $page from storage: $e');
    }
    return null;
  }

  Future<void> _savePageToStorage(int page, List<ProductModel> products) async {
    try {
      final Map<String, dynamic> allPages =
          _storage.read(_merchantProductsKey) ?? {};

      final String compressedData =
          jsonEncode(products.map((p) => p.toJson()).toList());
      allPages[page.toString()] = compressedData;

      if (allPages.length > maxStoredPages) {
        _removeOldestPage(allPages);
      }

      await _storage.write(_merchantProductsKey, allPages);
      await _updatePageMetadata(page);
    } catch (e) {
      print('Error saving page $page to storage: $e');
    }
  }

  Future<void> _updatePageMetadata(int page) async {
    try {
      final Map<String, dynamic> metadata =
          _storage.read(_merchantProductsMetadataKey) ?? {};
      metadata[page.toString()] = {
        'lastAccess': DateTime.now().toIso8601String(),
        'accessCount': (metadata[page.toString()]?['accessCount'] ?? 0) + 1,
      };
      await _storage.write(_merchantProductsMetadataKey, metadata);
      _pageLastAccess[page] = DateTime.now();
    } catch (e) {
      print('Error updating page metadata: $e');
    }
  }

  void _removeOldestPage(Map<String, dynamic> allPages) {
    if (_pageLastAccess.isEmpty) return;

    final oldestPage = _pageLastAccess.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key
        .toString();

    allPages.remove(oldestPage);
    _pageLastAccess.remove(int.parse(oldestPage));
  }

  Future<void> clearCache() async {
    await _storage.remove(_merchantProductsKey);
    await _storage.remove(_merchantProductsMetadataKey);
    await _storage.remove(_lastRefreshKey);
    _pageLastAccess.clear();
  }
}
