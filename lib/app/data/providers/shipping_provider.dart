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
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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
    try {
      debugPrint(
          '📤 Calculating shipping cost for location $userLocationId and merchant $merchantId');

      final response = await _dio.post(
        '/shipping/calculate',
        data: {
          'user_location_id': userLocationId,
          'merchant_id': merchantId,
        },
      );

      debugPrint('📥 Shipping calculation response: ${response.data}');
      return response;
    } on dio.DioException catch (e) {
      debugPrint('Error calculating shipping: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error calculating shipping: $e');
      throw Exception('Gagal menghitung biaya pengiriman');
    }
  }

  Future<dio.Response> getShippingPreview({
    required int userLocationId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      debugPrint('📤 Getting shipping preview for location $userLocationId');
      debugPrint('Items: $items');

      final response = await _dio.post(
        '/shipping/preview',
        data: {
          'user_location_id': userLocationId,
          'items': items,
        },
      );

      debugPrint('📥 Shipping preview response: ${response.data}');
      return response;
    } on dio.DioException catch (e) {
      debugPrint('Error getting shipping preview: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error getting shipping preview: $e');
      throw Exception('Gagal mendapatkan preview pengiriman');
    }
  }
}
