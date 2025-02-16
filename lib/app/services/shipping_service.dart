import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../data/providers/shipping_provider.dart';

class ShippingService extends GetxService {
  late final ShippingProvider _shippingProvider;
  bool _isInitialized = false;

  Future<bool> get isInitialized async {
    if (_isInitialized) return true;
    await initializeProvider();
    return _isInitialized;
  }

  Future<void> initializeProvider() async {
    if (_isInitialized) return;

    try {
      _shippingProvider = Get.find<ShippingProvider>();
      await _shippingProvider.ensureInitialized();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing shipping provider: $e');
      rethrow;
    }
  }

  Future<void> updateShipping() async {
    await Future.microtask(() => saveShippingDetails());
  }

  bool saveShippingDetails() {
    return true;
  }

  bool isValidAddress(String address) {
    return address.isNotEmpty;
  }

  Future<Map<String, dynamic>?> calculateShipping({
    required int userLocationId,
    required int merchantId,
  }) async {
    try {
      if (!(await isInitialized)) {
        await initializeProvider();
      }

      final response = await _shippingProvider.calculateShipping(
        userLocationId: userLocationId,
        merchantId: merchantId,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData['meta']['code'] == 200) {
          debugPrint('Shipping calculation successful');
          return {'data': responseData['data']};
        }
        debugPrint('Invalid response meta code: ${responseData['meta']['code']}');
      }

      return null;
    } on TimeoutException catch (e) {
      debugPrint('Shipping calculation timeout: ${e.message}');
      rethrow;
    } on dio.DioException catch (e) {
      debugPrint('Dio error in shipping calculation: ${e.message}');
      if (e.type == dio.DioExceptionType.connectionTimeout ||
          e.type == dio.DioExceptionType.sendTimeout ||
          e.type == dio.DioExceptionType.receiveTimeout) {
        throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
      }
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in shipping calculation: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getShippingPreview({
    required int userLocationId,
    required List<Map<String, dynamic>> items,
    dio.CancelToken? cancelToken,
  }) async {
    try {
      if (!(await isInitialized)) {
        await initializeProvider();
      }

      final response = await _shippingProvider.getShippingPreview(
        userLocationId: userLocationId,
        items: items,
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData['meta']['code'] == 200) {
          debugPrint('Shipping preview successful');
          return {'data': responseData['data']};
        }
        debugPrint('Invalid response meta code: ${responseData['meta']['code']}');
      }

      return null;
    } on TimeoutException catch (e) {
      debugPrint('Shipping preview timeout: ${e.message}');
      rethrow;
    } on dio.DioException catch (e) {
      debugPrint('Dio error in shipping preview: ${e.message}');
      if (e.type == dio.DioExceptionType.connectionTimeout ||
          e.type == dio.DioExceptionType.sendTimeout ||
          e.type == dio.DioExceptionType.receiveTimeout) {
        throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
      }
      if (e.type == dio.DioExceptionType.cancel) {
        debugPrint('Request cancelled');
        return null;
      }
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error in shipping preview: $e');
      return null;
    }
  }
}
