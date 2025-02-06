import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:antarkanma/config.dart';

class ShippingProvider extends GetxService {
  final dio.Dio _dio = dio.Dio();

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
          options.headers['Accept'] = 'application/json';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  Future<dio.Response> calculateShipping({
    required int userLocationId,
    required int merchantId,
  }) async {
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
  }
}
