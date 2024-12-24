import 'package:antarkanma/config.dart';
import 'package:dio/dio.dart';

class MerchantProvider {
  final Dio _dio = Dio(); // Initialize Dio instance
  final String baseUrl = Config.baseUrl;

  MerchantProvider() {
    _setupBaseOptions(); // Set up base options for Dio
    _setupInterceptors(); // Set up interceptors for authorization
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

  Future<Response> getMerchantsByOwnerId(String ownerId, String token) async {
    print('Fetching merchants for owner ID: $ownerId'); // Debugging statement
    try {
      final response = await _dio.get(
        '/merchants/owner/$ownerId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      print('token : $token'); // Debugging statement
      print('Response body: ${response.data}'); // Log the full response body
      return response; // Return the entire response
    } catch (e) {
      print('Exception occurred: $e'); // Log the exception
      throw Exception('Failed to load merchants: $e');
    }
  }

  // New methods for merchant management
  Future<Response> getMerchants(String token) async {
    try {
      return await _dio.get(
        '/merchants',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to get merchants: $e');
    }
  }

  Future<Response> getMerchant(String token, int merchantId) async {
    try {
      return await _dio.get(
        '/merchants/$merchantId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to get merchant: $e');
    }
  }

  Future<Response> addMerchant(String token, Map<String, dynamic> data) async {
    try {
      return await _dio.post(
        '/merchants',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
        data: data,
      );
    } catch (e) {
      throw Exception('Failed to add merchant: $e');
    }
  }

  Future<Response> updateMerchant(
      String token, int merchantId, Map<String, dynamic> data) async {
    try {
      return await _dio.put(
        '/merchants/$merchantId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
        data: data,
      );
    } catch (e) {
      throw Exception('Failed to update merchant: $e');
    }
  }

  Future<Response> deleteMerchant(String token, int merchantId) async {
    try {
      return await _dio.delete(
        '/merchants/$merchantId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      throw Exception('Failed to delete merchant: $e');
    }
  }

  void _handleError(DioException error) {
    // Handle errors similarly to the product provider
    String message;
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
        message = errors.toString();
        break;
      default:
        message = error.response?.data['message'] ?? 'An error occurred';
    }
    throw Exception(message);
  }
}
