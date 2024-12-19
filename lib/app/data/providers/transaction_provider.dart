import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:antarkanma/config.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/routes/app_pages.dart';

class TransactionProvider {
  final dio.Dio _dio = dio.Dio();
  final String baseUrl = Config.baseUrl;
  final StorageService _storageService = StorageService.instance;

  TransactionProvider() {
    _setupBaseOptions();
    _setupInterceptors();
  }

  void _setupBaseOptions() {
    _dio.options = dio.BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status! < 500,
    );
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _storageService.getToken();

          // Tambahkan token hanya jika tersedia
          if (token != null) {
            options.headers.addAll({
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            });
          }

          return handler.next(options);
        },
        onError: (dio.DioException error, handler) async {
          print('\n=== API Error Interceptor ===');
          print('Status code: ${error.response?.statusCode}');

          if (error.response?.statusCode == 401) {
            try {
              final authService = Get.find<AuthService>();
              authService.handleAuthError(error);
            } catch (e) {
              print('Failed to handle auth error in interceptor: $e');
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // Ganti _handleForceLogout dengan metode yang lebih sederhana

  void _handleError(dio.DioException error) {
    print('\n=== API Error Debug ===');
    print('Status code: ${error.response?.statusCode}');
    print('Response data: ${error.response?.data}');
    print('Error type: ${error.type}');
    print('Error message: ${error.message}');

    String message;
    switch (error.response?.statusCode) {
      case 401:
        message = 'Sesi anda telah berakhir. Silakan login kembali.';
        try {
          final authService = Get.find<AuthService>();
          authService.handleAuthError(error);
        } catch (e) {
          print('Failed to handle auth error: $e');
        }
        break;
      case 422:
        final errors = error.response?.data['errors'];
        message = errors is Map ? errors.values.join(', ') : errors.toString();
        break;
      case 403:
        message = 'Anda tidak memiliki akses ke halaman ini.';
        break;
      case 404:
        message = 'Data tidak ditemukan.';
        break;
      case 500:
        message = 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
        break;
      default:
        message = error.response?.data['message'] ??
            error.message ??
            'Terjadi kesalahan yang tidak diketahui';
    }

    throw Exception(message);
  }

  // Metode-metode transaksi
  Future<dio.Response> createTransaction(
      Map<String, dynamic> transactionData) async {
    try {
      print(
          'Using token: ${_storageService.getToken()}'); // Log the token being used
      print('Transaction Data: $transactionData'); // Log the transaction data
      final response = await _dio.post('/transactions', data: transactionData);
      print('Response: ${response.data}'); // Log the response for debugging
      return response; // Return the response to avoid null return error
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio.Response> getTransactions({String? status}) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (status != null && status.isNotEmpty) {
        // Split status string into array if it contains multiple statuses
        final statuses = status.split(',');
        if (statuses.length > 1) {
          // If multiple statuses, pass them as array parameter
          queryParameters['status[]'] = statuses;
        } else {
          // If single status, pass as simple parameter
          queryParameters['status'] = status;
        }
      }

      print('\n=== Transaction Provider Debug ===');
      print('Making GET request to: ${baseUrl}/transactions');
      print('Query parameters: $queryParameters');
      print('Headers: ${_dio.options.headers}');

      final response = await _dio.get(
        '/transactions',
        queryParameters: queryParameters,
      );

      print('Response status code: ${response.statusCode}');
      print('Response data: ${response.data}');

      return response;
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio.Response> getTransactionById(String transactionId) async {
    try {
      return await _dio.get('/transactions/$transactionId');
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio.Response> updateTransaction(
      String transactionId, Map<String, dynamic> updateData) async {
    try {
      return await _dio.put('/transactions/$transactionId', data: updateData);
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio.Response> cancelTransaction(String transactionId) async {
    try {
      return await _dio.post('/transactions/$transactionId/cancel');
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio.Response> getTransactionsByMerchant(String merchantId) async {
    try {
      return await _dio.get('/merchants/$merchantId/transactions');
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}
