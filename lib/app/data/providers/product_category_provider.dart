import 'package:antarkanma/config.dart';
import 'package:dio/dio.dart';

class ProductCategoryProvider {
  final Dio _dio = Dio();
  final String baseUrl = Config.baseUrl;

  ProductCategoryProvider() {
    _setupBaseOptions();
  }

  void _setupBaseOptions() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status! < 500,
    );
  }

  Future<Response> getCategories(String token) async {
    try {
      return await _dio.get(
        '/api/product-categories',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<Response> getCategory(String token, int id) async {
    try {
      return await _dio.get(
        '/api/product-category/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }

  Future<Response> createCategory(
      String token, Map<String, dynamic> data) async {
    try {
      return await _dio.post(
        '/api/product-category',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
        data: data,
      );
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  Future<Response> updateCategory(
      String token, int id, Map<String, dynamic> data) async {
    try {
      return await _dio.put(
        '/api/product-category/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
        data: data,
      );
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<Response> deleteCategory(String token, int id) async {
    try {
      return await _dio.delete(
        '/api/product-category/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}
