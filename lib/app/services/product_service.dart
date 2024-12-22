import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/data/providers/product_provider.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ProductService extends GetxService {
  final ProductProvider _productProvider = ProductProvider();
  final _storage = GetStorage();
  static const String _productsKey = 'products';
  static const String _lastRefreshKey = 'last_refresh';
  static const String _popularProductsKey = 'popular_products';

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

        // Convert to List<ProductModel> and ensure rating info is included
        final List<ProductModel> updatedProducts = [];
        for (var json in productList) {
          // Make sure rating info is properly parsed from the API response
          if (json['rating_info'] == null) {
            if (json['average_rating'] != null) {
              json['rating_info'] = {
                'average_rating':
                    double.tryParse(json['average_rating'].toString()) ?? 0.0,
                'total_reviews': json['total_reviews'] ?? 0,
              };
            }
          }

          final product = ProductModel.fromJson(json as Map<String, dynamic>);
          updatedProducts.add(product);
        }

        products.value = updatedProducts;

        // Save to local storage with rating info
        await _storage.write(
            _productsKey, updatedProducts.map((p) => p.toJson()).toList());
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

        // Convert to models and ensure rating info is included
        final List<ProductModel> products = [];
        for (var json in productList) {
          // Make sure rating info is properly parsed from the API response
          if (json['rating_info'] == null && json['average_rating'] != null) {
            json['rating_info'] = {
              'average_rating':
                  double.tryParse(json['average_rating'].toString()) ?? 0.0,
              'total_reviews': json['total_reviews'] ?? 0,
            };
          }
          final product = ProductModel.fromJson(json as Map<String, dynamic>);
          products.add(product);
        }

        // Save popular products to local storage
        await _storage.write(
            _popularProductsKey, products.map((p) => p.toJson()).toList());

        return products;
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

  Future<Map<String, dynamic>> getProductWithReviews(int productId) async {
    try {
      final response = await _productProvider.getProductReviews(productId);
      if (response.statusCode == 200) {
        return response.data;
      }
    } catch (e) {
      print('Error getting product reviews: $e');
    }
    return {};
  }

  Future<void> clearLocalStorage() async {
    await _storage.remove(_productsKey);
    await _storage.remove(_lastRefreshKey);
    products.clear();
  }

  // Add the getProductsByCategory method
  Future<List<ProductModel>> getProductsByCategory(int categoryId) async {
    try {
      final response = await _productProvider.getProductsByCategory(categoryId);
      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        final List<ProductModel> products = [];
        for (var json in productList) {
          final product = ProductModel.fromJson(json as Map<String, dynamic>);
          if (product.id != null && product.ratingInfo == null) {
            final reviewData = await getProductWithReviews(product.id!);
            final updatedProduct = product.copyWith(
              averageRatingRaw:
                  reviewData['rating_info']['average_rating'].toString(),
              totalReviewsRaw:
                  reviewData['rating_info']['total_reviews'] as int,
              ratingInfo: reviewData['rating_info'] as Map<String, dynamic>,
              reviews:
                  (reviewData['reviews'] as List).cast<ProductReviewModel>(),
            );
            products.add(updatedProduct);
          } else {
            products.add(product);
          }
        }
        return products;
      }
    } catch (e) {
      print('Error getting products by category: $e');
    }
    return [];
  }
}
