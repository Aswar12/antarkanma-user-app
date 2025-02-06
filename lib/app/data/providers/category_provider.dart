import 'package:antarkanma/config.dart';
import 'package:dio/dio.dart';

class CategoryProvider {
  final Dio _dio = Dio();
  final String baseUrl = Config.baseUrl;

  CategoryProvider() {
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
              statusCode: 200,
              data: {'data': []}, // Return empty array for categories
            ));
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> getCategories(String token, {bool silent = false}) async {
    try {
      final response = await _dio.get(
        '/categories',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
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
      if (silent) {
        return Response(
          requestOptions: RequestOptions(path: '/categories'),
          statusCode: 200,
          data: {'data': []},
        );
      }
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<Response> getCategory(String token, int id, {bool silent = false}) async {
    try {
      final response = await _dio.get(
        '/categories/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
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
      if (silent) {
        return Response(
          requestOptions: RequestOptions(path: '/categories/$id'),
          statusCode: 200,
          data: {'data': null},
        );
      }
      throw Exception('Failed to get category: $e');
    }
  }
}
