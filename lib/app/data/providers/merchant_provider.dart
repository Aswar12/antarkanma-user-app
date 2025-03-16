import 'dart:async';
import 'dart:io';
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
          // Return empty data for DNS lookup errors in debug mode
          if (kDebugMode &&
              error.error != null &&
              (error.error.toString().contains('Failed host lookup') ||
                  error.error.toString().contains('SocketException'))) {
            return handler.resolve(
              Response(
                requestOptions: error.requestOptions,
                data: {'data': []},
                statusCode: 200,
              ),
            );
          }
          _handleError(error);
          return handler.next(error);
        },
      ),
    );

    // Add retry interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, handler) async {
          if (error.error != null &&
              (error.error.toString().contains('Failed host lookup') ||
                  error.error.toString().contains('SocketException'))) {
            // Wait and retry once
            await Future.delayed(const Duration(seconds: 2));
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          }
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

      final cancelToken = CancelToken();
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
        return response;
      } finally {
        timeoutTimer.cancel();
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        throw TimeoutException('Request timed out');
      }
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
      rethrow;
    } finally {
      timeoutTimer?.cancel();
    }
  }

  void _handleError(DioException error) {
    String message;

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
