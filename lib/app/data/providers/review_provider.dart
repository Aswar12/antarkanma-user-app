import 'package:dio/dio.dart' as dio;
import 'package:antarkanma/config.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:flutter/foundation.dart';

class ReviewProvider {
  final dio.Dio _dio = dio.Dio();
  final String baseUrl = Config.baseUrl;
  final StorageService _storageService = StorageService.instance;

  ReviewProvider() {
    _dio.options = dio.BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      validateStatus: (status) => true,
    );

    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _storageService.getToken();
          if (token != null) {
            options.headers.addAll({
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            });
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Submit unified reviews for a completed transaction
  Future<dio.Response> submitReview(
      int transactionId, Map<String, dynamic> reviewData) async {
    try {
      debugPrint('\n=== Submitting Review ===');
      debugPrint('Transaction ID: $transactionId');
      debugPrint('Review Data: $reviewData');

      final response = await _dio.post(
        '/transactions/$transactionId/review',
        data: reviewData,
      );

      debugPrint('Review Response: ${response.statusCode} ${response.data}');
      return response;
    } on dio.DioException catch (e) {
      debugPrint('Review submission error: ${e.message}');
      rethrow;
    }
  }

  /// Check which reviews have been submitted for a transaction
  Future<dio.Response> getReviewStatus(int transactionId) async {
    try {
      final response =
          await _dio.get('/transactions/$transactionId/review-status');
      return response;
    } on dio.DioException catch (e) {
      debugPrint('Review status error: ${e.message}');
      rethrow;
    }
  }

  /// Get merchant reviews
  Future<dio.Response> getMerchantReviews(int merchantId,
      {int? rating, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/merchants/$merchantId/reviews',
        queryParameters: {
          'limit': limit,
          if (rating != null) 'rating': rating,
        },
      );
      return response;
    } on dio.DioException catch (e) {
      debugPrint('Merchant reviews error: ${e.message}');
      rethrow;
    }
  }

  /// Get courier reviews
  Future<dio.Response> getCourierReviews(int courierId,
      {int limit = 10}) async {
    try {
      final response = await _dio.get(
        '/couriers/$courierId/reviews',
        queryParameters: {'limit': limit},
      );
      return response;
    } on dio.DioException catch (e) {
      debugPrint('Courier reviews error: ${e.message}');
      rethrow;
    }
  }
}
