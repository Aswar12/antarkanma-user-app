import 'package:dio/dio.dart';
import 'package:antarkanma/config.dart';

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

  Future<Response> getAllProducts({
    String? query,
    double? priceFrom,
    double? priceTo,
    int? categoryId,
    String? token,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'page_size': pageSize,
      };
      
      if (query != null && query.isNotEmpty) queryParams['name'] = query;
      if (priceFrom != null) queryParams['price_from'] = priceFrom;
      if (priceTo != null) queryParams['price_to'] = priceTo;
      if (categoryId != null) queryParams['categories'] = categoryId;

      return await _dio.get(
        '/products',
        queryParameters: queryParams,
        options: token != null ? _getAuthOptions(token) : null,
      );
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

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

  Future<Response> getProductsByCategory(
    int categoryId, {
    String? token,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      return await _dio.get(
        '/products',
        queryParameters: {
          'categories': categoryId,
          'page': page,
          'page_size': pageSize,
        },
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
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'page_size': pageSize,
      };
      
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

  Future<Response> getProductReviews(int productId,
      {String? token, int? rating}) async {
    try {
      Map<String, dynamic> queryParams = {};
      if (rating != null && rating > 0) {
        queryParams['rating'] = rating;
      }

      return await _dio.get(
        '/products/$productId/reviews',
        queryParameters: queryParams,
        options: token != null ? _getAuthOptions(token) : null,
      );
    } catch (e) {
      throw Exception('Failed to fetch product reviews: $e');
    }
  }

  Future<Response> submitProductReview(
      Map<String, dynamic> reviewData, String token) async {
    try {
      return await _dio.post(
        '/product-reviews',
        data: reviewData,
        options: _getAuthOptions(token),
      );
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  Future<Response> updateProductReview(
      int reviewId, Map<String, dynamic> reviewData, String token) async {
    try {
      return await _dio.put(
        '/product-reviews/$reviewId',
        data: reviewData,
        options: _getAuthOptions(token),
      );
    } catch (e) {
      throw Exception('Failed to update review: $e');
    }
  }

  Future<Response> deleteProductReview(int reviewId, String token) async {
    try {
      return await _dio.delete(
        '/product-reviews/$reviewId',
        options: _getAuthOptions(token),
      );
    } catch (e) {
      throw Exception('Failed to delete review: $e');
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
