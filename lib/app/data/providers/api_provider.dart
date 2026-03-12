import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../../config.dart';
import 'package:antarkanma/app/services/storage_service.dart';

class ApiProvider {
  late final Dio _dio;
  final StorageService _storageService;

  ApiProvider() : _storageService = Get.find<StorageService>() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Config.baseUrl,
        connectTimeout: const Duration(milliseconds: Config.connectTimeout),
        receiveTimeout: const Duration(milliseconds: Config.receiveTimeout),
        responseType: ResponseType.json,
      ),
    );

    // Add auth interceptor to attach token to all requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = _storageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          options.headers['Accept'] = 'application/json';
          debugPrint('🔑 Auth header attached for: ${options.path}');
        } else {
          debugPrint('⚠️ No auth token found for request: ${options.path}');
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          debugPrint('⚠️ Token expired or invalid (401 Unauthorized)');
          _storageService.clearAuth();
        }
        return handler.next(error);
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? data}) async {
    try {
      final response = await _dio.delete(path, data: data);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    debugPrint(
        '🔴 API Error: ${e.type} | Path: ${e.requestOptions.path} | Message: ${e.message}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return Exception(
            'Koneksi timeout. Pastikan server aktif atau cek "adb reverse".');
      case DioExceptionType.receiveTimeout:
        return Exception('Server lambat merespon (Receive timeout).');
      case DioExceptionType.sendTimeout:
        return Exception('Gagal mengirim data (Send timeout).');
      case DioExceptionType.connectionError:
        return Exception(
            'Tidak dapat terhubung ke server. Pastikan backend aktif.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['message'] ?? 'Kesalahan Server ($statusCode)';
        return Exception(message);
      case DioExceptionType.cancel:
        return Exception('Permintaan dibatalkan.');
      default:
        return Exception('Terjadi kesalahan koneksi. Silakan coba lagi.');
    }
  }
}
