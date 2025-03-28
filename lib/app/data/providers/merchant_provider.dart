import 'dart:async';

import 'package:dio/dio.dart';
import 'package:antarkanma/config.dart';
import 'package:flutter/foundation.dart';

class MerchantProvider {
  final Dio _dio = Dio();
  final String baseUrl = Config.baseUrl;

  MerchantProvider() {
    _setupBaseOptions();
    _setupInterceptors();
  }

  void _setupBaseOptions() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      validateStatus: (status) => status! < 500,
    );
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('🌐 Request URL: ${options.uri}');
          debugPrint('📝 Request Query Parameters: ${options.queryParameters}');

          options.headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          });
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ Response Status Code: ${response.statusCode}');
          debugPrint('✅ Response Data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          _handleError(error);
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> getAllMerchants({
    String? query,
    String? category,
    String? token,
    int page = 1,
    int pageSize = 10,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'per_page': pageSize,
      };

      if (query != null && query.isNotEmpty) queryParams['search'] = query;
      if (category != null) queryParams['category'] = category;
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;

      // Create CancelToken for timeout handling
      final cancelToken = CancelToken();

      // Set up timeout
      Timer? timeoutTimer = Timer(const Duration(seconds: 60), () {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Request timed out');
        }
      });

      try {
        final response = await _dio.get(
          '/merchants',
          queryParameters: queryParams,
          options: token != null ? _getAuthOptions(token) : null,
          cancelToken: cancelToken,
        );

        debugPrint('API Response Status: ${response.statusCode}');
        debugPrint('API Response Data: ${response.data}');

        return response;
      } finally {
        timeoutTimer.cancel();
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        throw TimeoutException('Request timed out');
      }
      debugPrint('Error fetching merchants: $e');
      rethrow;
    }
  }

  Future<Response> getMerchantById(int id, {String? token}) async {
    final cancelToken = CancelToken();
    Timer? timeoutTimer;

    try {
      timeoutTimer = Timer(const Duration(seconds: 60), () {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Request timed out');
        }
      });

      final response = await _dio.get(
        '/merchants/$id',
        options: token != null ? _getAuthOptions(token) : null,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        throw TimeoutException('Request timed out');
      }
      debugPrint('Error fetching merchant: $e');
      rethrow;
    } finally {
      timeoutTimer?.cancel();
    }
  }

  Future<Response> getMerchantProducts(
    int merchantId, {
    String? query,
    String? category,
    String? token,
    int page = 1,
    int pageSize = 10,
  }) async {
    final cancelToken = CancelToken();
    Timer? timeoutTimer;

    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'per_page': pageSize,
      };

      if (query != null && query.isNotEmpty) queryParams['search'] = query;
      if (category != null) queryParams['category'] = category;

      timeoutTimer = Timer(const Duration(seconds: 60), () {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Request timed out');
        }
      });

      final response = await _dio.get(
        '/merchants/$merchantId/products',
        queryParameters: queryParams,
        options: token != null ? _getAuthOptions(token) : null,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        throw TimeoutException('Request timed out');
      }
      debugPrint('Error fetching merchant products: $e');
      rethrow;
    } finally {
      timeoutTimer?.cancel();
    }
  }

  Future<Response> getPopularMerchants({
    String? token,
    int limit = 5,
    double? latitude,
    double? longitude,
  }) async {
    final cancelToken = CancelToken();
    Timer? timeoutTimer;

    try {
      Map<String, dynamic> queryParams = {'limit': limit};

      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;

      timeoutTimer = Timer(const Duration(seconds: 60), () {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Request timed out');
        }
      });

      final response = await _dio.get(
        '/merchants/popular',
        queryParameters: queryParams,
        options: token != null ? _getAuthOptions(token) : null,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        throw TimeoutException('Request timed out');
      }
      debugPrint('Error fetching popular merchants: $e');
      rethrow;
    } finally {
      timeoutTimer?.cancel();
    }
  }

  void _handleError(DioException error) {
    String message;
    debugPrint('API Error Response: ${error.response?.data}');

    if (error.response?.data is Map && error.response?.data['meta'] != null) {
      message = error.response?.data['meta']['message'] ?? 'An error occurred';
    } else {
      switch (error.response?.statusCode) {
        case 401:
          message = 'Unauthorized access. Please log in again.';
          break;
        case 403:
          message = 'You don\'t have permission to perform this action.';
          break;
        case 404:
          message = 'Merchant not found.';
          break;
        case 422:
          final errors = error.response?.data['errors'];
          message =
              errors != null ? errors.toString() : 'Validation error occurred';
          break;
        default:
          message = error.response?.data?['message'] ?? 'An error occurred';
      }
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
