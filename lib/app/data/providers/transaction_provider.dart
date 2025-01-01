import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:antarkanma/config.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';

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
      validateStatus: (status) => true,  // Accept all status codes to handle them manually
    );
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = _storageService.getToken();

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
          print('Error data: ${error.response?.data}');
          print('Error message: ${error.message}');
          print('Error type: ${error.type}');
          print('Error stacktrace: ${error.stackTrace}');

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

  void _handleError(dio.DioException error) {
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
        final data = error.response?.data;
        if (data != null && data['meta'] != null && data['meta']['message'] != null) {
          message = data['meta']['message'];
        } else if (data != null && data['data'] != null) {
          // Handle validation errors
          final errors = data['data'] as Map<String, dynamic>;
          final errorMessages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else {
              errorMessages.add(value.toString());
            }
          });
          message = errorMessages.join('\n');
        } else {
          message = 'Validasi gagal';
        }
        break;
      case 403:
        message = 'Anda tidak memiliki akses ke halaman ini.';
        break;
      case 404:
        message = 'Data tidak ditemukan.';
        break;
      case 500:
        final data = error.response?.data;
        if (data != null && data['message'] != null) {
          message = data['message'];
        } else {
          message = 'Terjadi kesalahan pada server. Silakan coba beberapa saat lagi.';
        }
        break;
      default:
        if (error.type == dio.DioExceptionType.connectionTimeout) {
          message = 'Koneksi timeout. Silakan periksa koneksi internet Anda.';
        } else if (error.type == dio.DioExceptionType.receiveTimeout) {
          message = 'Server tidak merespons. Silakan coba lagi.';
        } else {
          message = error.response?.data?['message'] ??
              error.message ??
              'Terjadi kesalahan yang tidak diketahui';
        }
    }

    CustomSnackbarX.showError(
      title: 'Error',
      message: message,
      position: SnackPosition.BOTTOM,
    );
    throw Exception(message);
  }

  Future<dio.Response> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      print('Using token: ${_storageService.getToken()}');
      print('Transaction Data: $transactionData');
      final response = await _dio.post('/transactions', data: transactionData);
      print('Response: ${response.data}');

      if (response.statusCode == 500) {
        _handleError(dio.DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: dio.DioExceptionType.badResponse,
        ));
      }

      if (response.statusCode == 422) {
        _handleError(dio.DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: dio.DioExceptionType.badResponse,
        ));
      }

      return response;
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio.Response> getTransactions({
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };

      if (status != null && status.isNotEmpty) {
        final statuses = status.split(',');
        if (statuses.length > 1) {
          queryParameters['status[]'] = statuses;
        } else {
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

  Future<dio.Response> cancelTransaction(String transactionId) async {
    try {
      return await _dio.post('/transactions/$transactionId/cancel');
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio.Response> getTransactionsByMerchant(
    String merchantId, {
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      };

      return await _dio.get(
        '/merchants/$merchantId/transactions',
        queryParameters: queryParams,
      );
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio.Response> getTransactionSummaryByMerchant(String merchantId) async {
    try {
      return await _dio.get('/merchants/$merchantId/transaction-summary');
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio.Response> updateOrderStatus(
    String merchantId,
    String orderId, {
    required String status,
    String? notes,
  }) async {
    try {
      return await _dio.put(
        '/merchants/$merchantId/orders/$orderId/status',
        data: {
          'status': status,
          if (notes != null) 'notes': notes,
        },
      );
    } on dio.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}
