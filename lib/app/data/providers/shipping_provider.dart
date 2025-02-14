import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:antarkanma/config.dart';
import 'package:antarkanma/app/services/storage_service.dart';

class ShippingProvider extends GetxService {
  final dio.Dio _dio = dio.Dio();
  final _storage = StorageService.instance;

  ShippingProvider() {
    _setupBaseOptions();
    _setupInterceptors();
  }

  void _setupBaseOptions() {
    _dio.options = dio.BaseOptions(
      baseUrl: Config.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      validateStatus: (status) => status! < 500,
    );
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add auth token to all requests
          final token = _storage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          _handleError(error);
          return handler.next(error);
        },
      ),
    );
  }

  void _handleError(dio.DioException error) {
    String message;
    debugPrint('DioException type: ${error.type}');
    debugPrint('DioException message: ${error.message}');
    
    if (error.type == dio.DioExceptionType.connectionTimeout ||
        error.type == dio.DioExceptionType.sendTimeout ||
        error.type == dio.DioExceptionType.receiveTimeout) {
      throw Exception('Koneksi timeout. Silakan coba lagi.');
    }
    
    switch (error.response?.statusCode) {
      case 401:
        message = 'Sesi telah berakhir. Silakan login kembali.';
        break;
      case 403:
        message = 'Anda tidak memiliki akses ke fitur ini.';
        break;
      case 422:
        final errors = error.response?.data['errors'];
        if (errors != null) {
          message = errors.toString();
        } else {
          message = error.response?.data['message'] ?? 'Terjadi kesalahan validasi';
        }
        break;
      default:
        message = error.response?.data['message'] ?? 'Terjadi kesalahan';
    }
    throw Exception(message);
  }

  Future<dio.Response> calculateShipping({
    required int userLocationId,
    required int merchantId,
  }) async {
    final cancelToken = dio.CancelToken();
    Timer? timeoutTimer;

    try {
      debugPrint(
          '📤 Calculating shipping cost for location $userLocationId and merchant $merchantId');

      timeoutTimer = Timer(const Duration(seconds: 60), () {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Request timed out');
        }
      });

      final response = await _dio.post(
        '/shipping/calculate',
        data: {
          'user_location_id': userLocationId,
          'merchant_id': merchantId,
        },
        cancelToken: cancelToken,
      );

      debugPrint('📥 Shipping calculation response: ${response.data}');
      return response;
    } on dio.DioException catch (e) {
      if (e.type == dio.DioExceptionType.cancel) {
        throw TimeoutException('Request timed out');
      }
      debugPrint('Error calculating shipping: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error calculating shipping: $e');
      throw Exception('Gagal menghitung biaya pengiriman');
    } finally {
      timeoutTimer?.cancel();
    }
  }

  Future<dio.Response> getShippingPreview({
    required int userLocationId,
    required List<Map<String, dynamic>> items,
  }) async {
    final cancelToken = dio.CancelToken();
    Timer? timeoutTimer;

    try {
      debugPrint('📤 Getting shipping preview for location $userLocationId');
      debugPrint('Items: $items');

      timeoutTimer = Timer(const Duration(seconds: 30), () {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Request timed out');
        }
      });

      final response = await _dio.post(
        '/shipping/preview',
        data: {
          'user_location_id': userLocationId,
          'items': items,
        },
        options: dio.Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
        cancelToken: cancelToken,
      );

      debugPrint('📥 Shipping preview response: ${response.data}');
      return response;
    } on dio.DioException catch (e) {
      if (e.type == dio.DioExceptionType.cancel) {
        throw TimeoutException('Request timed out');
      }
      debugPrint('Error getting shipping preview: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error getting shipping preview: $e');
      throw Exception('Gagal mendapatkan preview pengiriman');
    } finally {
      timeoutTimer?.cancel();
    }
  }
}
