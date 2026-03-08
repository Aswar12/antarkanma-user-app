import 'package:dio/dio.dart';
import 'package:antarkanma/config.dart';
import 'package:flutter/foundation.dart';

class WishlistProvider {
  final Dio _dio = Dio();
  final String baseUrl = Config.baseUrl;

  WishlistProvider() {
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
        onError: (DioException error, handler) {
          debugPrint('Wishlist API Error: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  Options _getAuthOptions(String token) {
    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  /// Fetch full wishlist
  Future<Response> getWishlist(String token) async {
    try {
      return await _dio.get(
        '/wishlist',
        options: _getAuthOptions(token),
      );
    } catch (e) {
      debugPrint('❌ Error fetching wishlist: $e');
      rethrow;
    }
  }

  /// Toggle a product in/out of wishlist
  Future<Response> toggleWishlist(int productId, String token) async {
    try {
      return await _dio.post(
        '/wishlist/toggle',
        data: {'product_id': productId},
        options: _getAuthOptions(token),
      );
    } catch (e) {
      debugPrint('❌ Error toggling wishlist: $e');
      rethrow;
    }
  }

  /// Batch check which product IDs are wishlisted
  Future<Response> checkWishlist(List<int> productIds, String token) async {
    try {
      return await _dio.post(
        '/wishlist/check',
        data: {'product_ids': productIds},
        options: _getAuthOptions(token),
      );
    } catch (e) {
      debugPrint('❌ Error checking wishlist: $e');
      rethrow;
    }
  }
}
