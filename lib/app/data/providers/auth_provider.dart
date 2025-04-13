import 'package:antarkanma/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AuthProvider {
  static AuthProvider? _instance;
  late final Dio _dio;
  final String baseUrl = Config.baseUrl;
  bool _isInitialized = false;

  // Private constructor
  AuthProvider._() {
    _dio = Dio();
    _setupBaseOptions();
    _setupInterceptors();
    _isInitialized = true;
    debugPrint('AuthProvider initialized with baseUrl: $baseUrl');
  }

  // Factory constructor to return the singleton instance
  factory AuthProvider() {
    _instance ??= AuthProvider._();
    return _instance!;
  }

  bool get isInitialized => _isInitialized;

  void _setupBaseOptions() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 45),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Connection': 'keep-alive',
      },
      validateStatus: (status) {
        return status != null && status < 500;
      },
      followRedirects: true,
      maxRedirects: 5,
      extra: {
        'retryAttempts': 3,
        'retryDelay': const Duration(seconds: 2),
      },
    );
  }

  void _setupInterceptors() {
    _dio.interceptors.clear();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
          debugPrint('🌐 Request URL: ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
              '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          debugPrint(
              '🔴 ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
          debugPrint('🔴 Error Type: ${error.type}');
          debugPrint('🔴 Error Message: ${error.message}');

          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.unknown) {
            debugPrint('🔄 Connection error occurred. Attempting retry...');

            final retryCount =
                (error.requestOptions.extra['retryCount'] ?? 0) as int;
            final maxRetries = error.requestOptions.extra['retryAttempts'] ?? 3;

            if (retryCount < maxRetries) {
              error.requestOptions.extra['retryCount'] = retryCount + 1;

              // Calculate delay with exponential backoff starting at 2 seconds
              final delay = Duration(seconds: 2 * (1 << retryCount));
              debugPrint(
                  '🔄 Waiting ${delay.inSeconds}s before retry ${retryCount + 1}/$maxRetries');
              await Future.delayed(delay);

              try {
                // Keep timeouts consistent at 45 seconds
                error.requestOptions.connectTimeout =
                    const Duration(seconds: 45);
                error.requestOptions.sendTimeout = const Duration(seconds: 45);
                error.requestOptions.receiveTimeout =
                    const Duration(seconds: 45);

                final response = await _dio.fetch(error.requestOptions);
                return handler.resolve(response);
              } catch (e) {
                debugPrint('🔴 Retry failed: $e');
                return handler.next(error);
              }
            }
          }

          if (error.requestOptions.extra['silent'] == true) {
            return handler.resolve(Response(
              requestOptions: error.requestOptions,
              statusCode: 200,
              data: {'data': null},
            ));
          }

          _handleError(error);
          return handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) {
          debugPrint(obj.toString());
        },
      ));
    }
  }

  Future<Response> getProfile(String token, {bool silent = false}) async {
    try {
      final response = await _dio.get(
        Config.profile,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          extra: {
            'silent': silent,
          },
          validateStatus: (status) {
            if (silent) return true;
            return status! < 500;
          },
        ),
      );
      return response;
    } catch (e) {
      debugPrint('Error in getProfile: $e');
      if (silent) {
        return Response(
          requestOptions: RequestOptions(path: Config.profile),
          statusCode: 200,
          data: {'data': null},
        );
      }
      rethrow;
    }
  }

  Future<Response> login(String identifier, String password,
      {bool silent = false}) async {
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
      debugPrint('Error in login: $e');
      if (silent) {
        return Response(
          requestOptions: RequestOptions(path: Config.login),
          statusCode: 200,
          data: {'data': null},
        );
      }
      rethrow;
    }
  }

  Future<Response> register(Map<String, dynamic> userData) async {
    try {
      return await _dio.post(Config.register, data: userData);
    } catch (e) {
      debugPrint('Error in register: $e');
      rethrow;
    }
  }

  Future<Response> refreshToken(String token, {bool silent = false}) async {
    try {
      final response = await _dio.post(
        Config.refresh,
        data: {
          'token': token,
        },
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
      debugPrint('Error in refreshToken: $e');
      if (silent) {
        return Response(
          requestOptions: RequestOptions(path: Config.refresh),
          statusCode: 200,
          data: {'data': null},
        );
      }
      rethrow;
    }
  }

  Future<Response> updateProfilePhoto(String token, FormData formData) async {
    try {
      return await _dio.post(
        Config.profilePhoto,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
        data: formData,
      );
    } on DioException catch (e) {
      debugPrint('DioError in updateProfilePhoto: $e');
      if (e.response?.statusCode == 413) {
        throw Exception('File size too large. Maximum size is 2MB.');
      } else if (e.response?.statusCode == 415) {
        throw Exception('Invalid file type. Please upload an image file.');
      }
      debugPrint('Error response: ${e.response?.data}');
      rethrow;
    } catch (e) {
      debugPrint('Error in updateProfilePhoto: $e');
      rethrow;
    }
  }

  Future<Response> updateProfile(
      String token, Map<String, dynamic> data) async {
    try {
      return await _dio.put(
        Config.profile,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
        data: data,
      );
    } on DioException catch (e) {
      debugPrint('DioError in updateProfile: $e');
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
      rethrow;
    } catch (e) {
      debugPrint('Error in updateProfile: $e');
      rethrow;
    }
  }

  Future<Response> changePassword(
      String token, Map<String, dynamic> data) async {
    try {
      return await _dio.put(
        Config.changePassword,
        options: _getAuthOptions(token),
        data: data,
      );
    } catch (e) {
      debugPrint('Error in changePassword: $e');
      rethrow;
    }
  }

  Future<Response> logout(String token, {bool silent = false}) async {
    try {
      final response = await _dio.post(
        Config.logout,
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
      debugPrint('Error in logout: $e');
      if (silent) {
        return Response(
          requestOptions: RequestOptions(path: Config.logout),
          statusCode: 200,
          data: {'data': null},
        );
      }
      rethrow;
    }
  }

  Future<Response> getCurrentUser(String token, {bool silent = false}) async {
    try {
      final response = await _dio.get(
        Config.profile,
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
      debugPrint('Error in getCurrentUser: $e');
      if (silent) {
        return Response(
          requestOptions: RequestOptions(path: Config.profile),
          statusCode: 200,
          data: {'data': null},
        );
      }
      rethrow;
    }
  }

  void _handleError(DioException error) {
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
