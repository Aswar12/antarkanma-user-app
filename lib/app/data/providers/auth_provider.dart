import 'package:antarkanma/config.dart';
import 'package:dio/dio.dart';

class AuthProvider {
  final Dio _dio = Dio();
  final String baseUrl = Config.baseUrl;

  AuthProvider() {
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

  Future<Response> deleteAccount(String token) async {
    try {
      return await _dio.delete(
        '/auth/delete-account', // Ganti dengan endpoint yang sesuai
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  Future<Response> refreshToken(String token) async {
    try {
      return await _dio.post(
        '/auth/refresh',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      throw Exception('Failed to refresh token: $e');
    }
  }

  Future<Response> updateProfilePhoto(String token, dynamic formData) async {
    try {
      return await _dio.post(
        '/auth/update-profile-photo',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
        data: formData,
      );
    } catch (e) {
      throw Exception('Failed to update profile photo: $e');
    }
  }

  Future<Response> updateProfile(
      String token, Map<String, dynamic> data) async {
    try {
      return await _dio.put(
        '/auth/update-profile', // Ganti dengan endpoint yang sesuai
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: data,
      );
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
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

  /// Login dengan email atau nomor WA
  Future<Response> login(String identifier, String password) async {
    try {
      final Map<String, dynamic> loginData = {
        'identifier': identifier,
        'password': password,
      };

      return await _dio.post('/login', data: loginData);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Register
  Future<Response> register(Map<String, dynamic> userData) async {
    try {
      return await _dio.post('/register', data: userData);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Change Password
  Future<Response> changePassword(
      String token, Map<String, dynamic> data) async {
    try {
      return await _dio.put(
        '/auth/change-password',
        options: _getAuthOptions(token),
        data: data, // Pastikan ini adalah Map<String, dynamic>
      );
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  Future<Response> logout(String token) async {
    try {
      return await _dio.post('/auth/logout', options: _getAuthOptions(token));
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  /// Get Current User
  Future<Response> getCurrentUser(String token) async {
    try {
      return await _dio.get('/auth/user', options: _getAuthOptions(token));
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  /// Error Handling
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

  /// Helper method untuk auth header
  Options _getAuthOptions(String token) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }
}
