import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/providers/product_provider.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ProductService extends GetxService {
  final ProductProvider _productProvider = ProductProvider();
  final _storage = GetStorage();
  static const String _productsKey = 'products';
  static const String _lastRefreshKey = 'last_refresh';

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final storedProducts = _storage.read(_productsKey);
      final lastRefresh = _storage.read(_lastRefreshKey);

      final shouldRefresh = lastRefresh == null ||
          DateTime.now().difference(DateTime.parse(lastRefresh)).inHours > 1;

      if (storedProducts != null && !shouldRefresh) {
        try {
          final List<dynamic> productList = storedProducts;
          products.value = productList
              .map(
                  (json) => ProductModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          print('Error parsing stored products: $e');
          await refreshProducts();
        }
      } else {
        await refreshProducts();
      }
    } catch (e) {
      print('Error in fetchProducts: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to load products: ${e.toString()}',
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProducts() async {
    try {
      final response = await _productProvider.getAllProducts();

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        // Convert to List<ProductModel>
        products.value = productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Save to local storage
        await _storage.write(_productsKey, productList);
        await _storage.write(_lastRefreshKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Error in refreshProducts: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to refresh products: ${e.toString()}',
        isError: true,
      );
    }
  }

  List<ProductModel> get productsList => products;

  Future<void> getProductsByCategory(int categoryId) async {
    try {
      isLoading.value = true;
      final response = await _productProvider.getProductsByCategory(categoryId);

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        // Only update the current products list, don't save to storage
        products.value = productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error in getProductsByCategory: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to load products by category: ${e.toString()}',
        isError: true,
      );

      // If API call fails, try to use filtered products from local storage
      final storedProducts = _storage.read(_productsKey);
      if (storedProducts != null) {
        try {
          final List<dynamic> allProducts = storedProducts;
          final allProductsList = allProducts
              .map(
                  (json) => ProductModel.fromJson(json as Map<String, dynamic>))
              .toList();

          // Filter stored products by category
          products.value = allProductsList
              .where((product) => product.category?.id == categoryId)
              .toList();
        } catch (e) {
          print('Error parsing stored products: $e');
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Get all products from local storage
  List<ProductModel> getAllProductsFromStorage() {
    try {
      final storedProducts = _storage.read(_productsKey);
      if (storedProducts != null) {
        final List<dynamic> productList = storedProducts;
        return productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error getting products from storage: $e');
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

        // Save to local storage before converting to models
        await _storage.write('popular_products', productList);

        return productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return _getPopularProductsFromStorage();
    } catch (e) {
      print('Error in getPopularProducts: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to load popular products: ${e.toString()}',
        isError: true,
      );
      return _getPopularProductsFromStorage();
    }
  }

  List<ProductModel> _getPopularProductsFromStorage() {
    try {
      final storedProducts = _storage.read('popular_products');
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

  bool hasLocalData() {
    return _storage.hasData(_productsKey);
  }

  Future<void> clearLocalStorage() async {
    await _storage.remove(_productsKey);
    await _storage.remove(_lastRefreshKey);
    products.clear();
  }
}
