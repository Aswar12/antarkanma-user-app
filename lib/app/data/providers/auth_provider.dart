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

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Accept'] = 'application/json';
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          // Don't throw errors during silent requests
          if (error.requestOptions.extra['silent'] == true) {
            return handler.resolve(Response(
              requestOptions: error.requestOptions,
              statusCode: 200,  // Force success status
              data: {'data': null},  // Return empty data
            ));
          }
          
          _handleError(error);
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> getProfile(String token, {bool silent = false}) async {
    try {
      final response = await _dio.get(
        '/user/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          extra: {
            'silent': silent,
          },
          validateStatus: (status) {
            // For silent requests, treat all responses as valid
            if (silent) return true;
            // Otherwise only accept < 500
            return status! < 500;
          },
        ),
      );
      return response;
    } catch (e) {
      // For silent requests, return fake success response
      if (silent) {
        return Response(
          requestOptions: RequestOptions(path: '/user/profile'),
          statusCode: 200,
          data: {'data': null},
        );
      }
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<Response> login(String identifier, String password, {bool silent = false}) async {
    try {
      final Map<String, dynamic> loginData = {
        'identifier': identifier,
        'password': password,
      };

      final response = await _dio.post(
        Config.login, 
        data: loginData,
        options: Options(
          extra: {
            'silent': silent,
          },
        ),
      );
      return response;
    } catch (e) {
      if (silent) {
        return Response(
          requestOptions: RequestOptions(path: Config.login),
          statusCode: 200,
          data: {'data': null},
        );
      }
      throw Exception('Login failed: $e');
    }
  }

  Future<Response> register(Map<String, dynamic> userData) async {
    try {
      return await _dio.post(Config.register, data: userData);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  Future<Response> refreshToken(String token, {bool silent = false}) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          extra: {
            'silent': silent,
          },
        ),
      );
      return response;
    } catch (e) {
      if (silent) {
        return Response(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          statusCode: 200,
          data: {'data': null},
        );
      }
      throw Exception('Failed to refresh token: $e');
    }
  }

  Future<Response> updateProfilePhoto(String token, FormData formData) async {
    try {
      return await _dio.post(
        '/user/profile/photo',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
        data: formData,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        throw Exception('File size too large. Maximum size is 2MB.');
      } else if (e.response?.statusCode == 415) {
        throw Exception('Invalid file type. Please upload an image file.');
      }
      print('Error response: ${e.response?.data}');
      throw Exception('Failed to update profile photo: ${e.message}');
    } catch (e) {
      print('Error updating photo: $e');
      throw Exception('Failed to update profile photo: $e');
    }
  }

  Future<Response> updateProfile(
      String token, Map<String, dynamic> data) async {
    try {
      return await _dio.put(
        '/user/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: data,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data['errors'];
        if (errors != null) {
          if (errors['email'] != null) {
            throw Exception('Email already exists');
          }
          if (errors['phone_number'] != null) {
            throw Exception('Phone number already exists');
          }
        }
      }
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<Response> changePassword(
      String token, Map<String, dynamic> data) async {
    try {
      return await _dio.put(
        '/auth/change-password',
        options: _getAuthOptions(token),
        data: data,
      );
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  Future<Response> logout(String token, {bool silent = false}) async {
    try {
      final response = await _dio.post(
        '/auth/logout', 
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          extra: {
            'silent': silent,
          },
        ),
      );
      return response;
    } catch (e) {
      if (silent) {
        return Response(
          requestOptions: RequestOptions(path: '/auth/logout'),
          statusCode: 200,
          data: {'data': null},
        );
      }
      throw Exception('Logout failed: $e');
    }
  }

  Future<Response> getCurrentUser(String token, {bool silent = false}) async {
    try {
      final response = await _dio.get(
        '/auth/user',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          extra: {
            'silent': silent,
          },
        ),
      );
      return response;
    } catch (e) {
      if (silent) {
        return Response(
          requestOptions: RequestOptions(path: '/auth/user'),
          statusCode: 200,
          data: {'data': null},
        );
      }
      throw Exception('Failed to get current user: $e');
    }
  }

  void _handleError(DioException error) {
    // Don't handle errors for silent requests
    if (error.requestOptions.extra['silent'] == true) {
      return;
    }

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

  Options _getAuthOptions(String token, {bool silent = false}) {
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
      extra: {
        'silent': silent,
      },
    );
  }
}
