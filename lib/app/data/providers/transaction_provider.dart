import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:antarkanma/config.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/routes/app_pages.dart'; // Pastikan Anda punya routes

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
          // Tangani error 401 (Unauthorized)
          if (error.response?.statusCode == 401) {}

          return handler.next(error);
        },
      ),
    );
  }

  // Ganti _handleForceLogout dengan metode yang lebih sederhana

  void _handleError(dio.DioException error) {
    String message;
    switch (error.response?.statusCode) {
      case 401:
        message = 'Unauthorized access. Please log in again.';

        break;
      case 422:
        final errors = error.response?.data['errors'];
        message = errors is Map ? errors.values.join(', ') : errors.toString();
        break;
      case 403:
        message = 'Forbidden. You do not have permission.';
        break;
      case 404:
        message = 'Resource not found.';
        break;
      case 500:
        message = 'Internal server error. Please try again later.';
        break;
      default:
        message = error.response?.data['message'] ??
            error.message ??
            'An unexpected error occurred';
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

  Future<dio.Response> getTransactions() async {
    try {
      return await _dio.get('/transactions');
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
