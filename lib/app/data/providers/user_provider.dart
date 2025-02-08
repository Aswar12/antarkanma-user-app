import 'package:antarkanma/config.dart';
import 'package:dio/dio.dart';

class UserProvider {
  final Dio _dio = Dio();
  final String baseUrl = Config.baseUrl;

  UserProvider() {
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

  Future<Response> getUserProfile(String token) async {
    try {
      final response = await _dio.get(
        '/user/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      if (response.statusCode == 200) {
        if (response.data != null && response.data['data'] != null) {
          return response;
        }
        throw Exception('Invalid response format');
      }
      
      throw Exception(response.data?['message'] ?? 'Failed to get user profile');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized access. Please log in again.');
      }
      throw Exception('Failed to get user profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  Future<Response> updateUserProfile(
      String token, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '/user/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        if (response.data != null && response.data['data'] != null) {
          return response;
        }
        throw Exception('Invalid response format');
      }

      throw Exception(response.data?['message'] ?? 'Failed to update profile');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized access. Please log in again.');
      } else if (e.response?.statusCode == 422) {
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

  Future<Response> uploadProfileImage(String token, String imagePath) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath),
      });

      final response = await _dio.post(
        '/user/profile/photo',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
        data: formData,
      );

      if (response.statusCode == 200) {
        if (response.data != null && response.data['data'] != null) {
          return response;
        }
        throw Exception('Invalid response format');
      }

      throw Exception(response.data?['message'] ?? 'Failed to upload image');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Unauthorized access. Please log in again.');
      } else if (e.response?.statusCode == 413) {
        throw Exception('File size too large. Maximum size is 2MB.');
      } else if (e.response?.statusCode == 415) {
        throw Exception('Invalid file type. Please upload an image file.');
      }
      throw Exception('Failed to upload image: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  void _handleError(DioException error) {
    String message;
    switch (error.response?.statusCode) {
      case 401:
        message = 'Unauthorized access. Please log in again.';
        break;
      case 422:
        final errors = error.response?.data['errors'];
        message = errors?.toString() ?? 'Validation error occurred';
        break;
      default:
        message = error.response?.data?['message'] ?? 'An error occurred';
    }
    throw Exception(message);
  }
}
