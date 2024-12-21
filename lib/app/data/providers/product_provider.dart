import 'package:antarkanma/config.dart';
import 'package:dio/dio.dart';

class ProductProvider {
  final Dio _dio = Dio();
  final String baseUrl = Config.baseUrl;

  ProductProvider() {
    _setupBaseOptions();
    _setupInterceptors();
  }

  void _setupBaseOptions() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status! < 500,
    );
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          });
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          _handleError(error);
          return handler.next(error);
        },
      ),
    );
  }

  // Get all products
  Future<Response> getAllProducts({String? token}) async {
    try {
      return await _dio.get(
        '/products',
        options: token != null ? _getAuthOptions(token) : null,
      );
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  // Get product by ID
  Future<Response> getProductById(int id, {String? token}) async {
    try {
      return await _dio.get(
        '/products/$id',
        options: token != null ? _getAuthOptions(token) : null,
      );
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  // Create product
  Future<Response> createProduct(
      Map<String, dynamic> productData, String token) async {
    try {
      return await _dio.post(
        '/products',
        data: productData,
        options: _getAuthOptions(token),
      );
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // Update product
  Future<Response> updateProduct(
    int id,
    Map<String, dynamic> productData,
    String token,
  ) async {
    try {
      return await _dio.put(
        '/products/$id',
        data: productData,
        options: _getAuthOptions(token),
      );
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product
  Future<Response> deleteProduct(int id, String token) async {
    try {
      return await _dio.delete(
        '/products/$id',
        options: _getAuthOptions(token),
      );
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Get products by category
  Future<Response> getProductsByCategory(int categoryId,
      {String? token}) async {
    try {
      return await _dio.get(
        '/products/category/$categoryId',
        options: token != null ? _getAuthOptions(token) : null,
      );
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  Future<Response> getPopularProducts({
    int? limit,
    int? categoryId,
    double? minRating,
    int? minReviews,
    String? token,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (limit != null) queryParams['limit'] = limit;
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (minRating != null) queryParams['min_rating'] = minRating;
      if (minReviews != null) queryParams['min_reviews'] = minReviews;

      return await _dio.get(
        '/products/popular',
        queryParameters: queryParams,
        options: token != null ? _getAuthOptions(token) : null,
      );
    } catch (e) {
      throw Exception('Failed to fetch popular products: $e');
    }
  }

  // Get products by merchant
  Future<Response> getProductsByMerchant(int merchantId,
      {String? token}) async {
    try {
      return await _dio.get(
        '/products/merchant/$merchantId',
        options: token != null ? _getAuthOptions(token) : null,
      );
    } catch (e) {
      throw Exception('Failed to fetch products by merchant: $e');
    }
  }

  // Search products
  Future<Response> searchProducts(String query, {String? token}) async {
    try {
      return await _dio.get(
        '/products/search',
        queryParameters: {'q': query},
        options: token != null ? _getAuthOptions(token) : null,
      );
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // Upload product image
  Future<Response> uploadProductImage(
    int productId,
    FormData imageData,
    String token,
  ) async {
    try {
      return await _dio.post(
        '/products/$productId/images',
        data: imageData,
        options: _getAuthOptions(token),
      );
    } catch (e) {
      throw Exception('Failed to upload product image: $e');
    }
  }

  // Delete product image
  Future<Response> deleteProductImage(
    int productId,
    int imageId,
    String token,
  ) async {
    try {
      return await _dio.delete(
        '/products/$productId/images/$imageId',
        options: _getAuthOptions(token),
      );
    } catch (e) {
      throw Exception('Failed to delete product image: $e');
    }
  }

  void _handleError(DioException error) {
    String message;
    switch (error.response?.statusCode) {
      case 401:
        message = 'Unauthorized access. Please log in again.';
        break;
      case 403:
        message = 'You don\'t have permission to perform this action.';
        break;
      case 404:
        message = 'Product not found.';
        break;
      case 422:
        final errors = error.response?.data['errors'];
        message = errors.toString();
        break;
      default:
        message = error.response?.data['message'] ?? 'An error occurred';
    }
    throw Exception(message);
  }

  Options _getAuthOptions(String token) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }
}
