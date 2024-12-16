import 'package:dio/dio.dart';
import 'package:antarkanma/config.dart';

class TransactionProvider {
  final Dio _dio = Dio();
  final String baseUrl = Config.baseUrl;

  TransactionProvider() {
    _setupBaseOptions();
    _setupInterceptors();
  }

  void _setupBaseOptions() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
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
          _handleError(error);
          return handler.next(error);
        },
      ),
    );
  }

  void _handleError(DioException error) {
    String message;
    switch (error.response?.statusCode) {
      case 401:
        message = 'Unauthorized access. Please log in again.';
        break;
      case 422:
        final errors = error.response?.data['errors'];
        message = errors.toString();
        break;
      default:
        message = error.response?.data['message'] ?? 'An error occurred';
    }
    throw Exception(message);
  }

  // Menggunakan endpoint untuk membuat transaksi
  Future<Response> createTransaction(
      Map<String, dynamic> transactionData) async {
    try {
      return await _dio.post('/transactions', data: transactionData);
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  // Mengambil daftar transaksi untuk pengguna
  Future<Response> getTransactions() async {
    try {
      return await _dio
          .get('/transactions'); // Endpoint untuk mengambil daftar transaksi
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  // Mengambil transaksi berdasarkan ID
  Future<Response> getTransactionById(String transactionId) async {
    try {
      return await _dio.get(
          '/transactions/$transactionId'); // Endpoint untuk mengambil transaksi berdasarkan ID
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }

  // Memperbarui transaksi
  Future<Response> updateTransaction(
      String transactionId, Map<String, dynamic> updateData) async {
    try {
      return await _dio.put('/transactions/$transactionId',
          data: updateData); // Endpoint untuk memperbarui transaksi
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  // Membatalkan transaksi
  Future<Response> cancelTransaction(String transactionId) async {
    try {
      return await _dio.post(
          '/transactions/$transactionId/cancel'); // Endpoint untuk membatalkan transaksi
    } catch (e) {
      throw Exception('Failed to cancel transaction: $e');
    }
  }

  // Mengambil transaksi berdasarkan merchant
  Future<Response> getTransactionsByMerchant(String merchantId) async {
    try {
      return await _dio.get(
          '/merchants/$merchantId/transactions'); // Endpoint untuk mengambil transaksi berdasarkan merchant
    } catch (e) {
      throw Exception('Failed to get transactions by merchant: $e');
    }
  }
}
