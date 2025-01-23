import 'package:dio/dio.dart' as dio;
import 'package:antarkanma/config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/paginated_response.dart';

class ProductService extends GetxService {
  final dio.Dio _dio = dio.Dio();
  final String baseUrl = Config.baseUrl;
  final RxList<ProductModel> _localProducts = <ProductModel>[].obs;
  static const int maxRetries = 3;

  ProductService() {
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
        onRequest: (options, handler) {
          debugPrint('🌐 Request URL: ${options.uri}');
          debugPrint('📝 Request Query Parameters: ${options.queryParameters}');

          // Add default headers
          options.headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          });

          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('✅ Response Status Code: ${response.statusCode}');
          debugPrint('✅ Response Data: ${response.data}');

          if (response.data is Map) {
            final data = response.data as Map<String, dynamic>;
            if (data['meta'] != null) {
              debugPrint('📊 Response Meta: ${data['meta']}');
            }
            if (data['data'] != null) {
              final dataSection = data['data'];
              if (dataSection is Map) {
                debugPrint('📊 Current Page: ${dataSection['current_page']}');
                debugPrint('📊 Last Page: ${dataSection['last_page']}');
                debugPrint('📊 Total Items: ${dataSection['total']}');
                if (dataSection['data'] is List) {
                  debugPrint(
                      '📊 Items in Current Page: ${(dataSection['data'] as List).length}');
                }
              }
            }
          }
          return handler.next(response);
        },
        onError: (dio.DioException error, handler) {
          debugPrint('❌ API Error:');
          debugPrint('   Status Code: ${error.response?.statusCode}');
          debugPrint('   Error Data: ${error.response?.data}');
          debugPrint('   Request URL: ${error.requestOptions.uri}');
          debugPrint(
              '   Query Params: ${error.requestOptions.queryParameters}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<T> _retryRequest<T>(Future<T> Function() request) async {
    int attempts = 0;
    dio.DioException? lastError;

    while (attempts < maxRetries) {
      try {
        return await request();
      } on dio.DioException catch (e) {
        lastError = e;
        attempts++;
        debugPrint('Attempt $attempts failed. Retrying...');
        await Future.delayed(
            Duration(seconds: attempts)); // Exponential backoff
      }
    }

    debugPrint('All retry attempts failed');
    throw lastError!;
  }

  void addProductToLocal(ProductModel product) {
    if (!_localProducts.contains(product)) {
      _localProducts.add(product);
    }
  }

  List<ProductModel> get localProducts => _localProducts.toList();

  void clearLocalProducts() {
    _localProducts.clear();
  }

  Future<PaginatedResponse<ProductModel>> getAllProducts({
    String? query,
    String? description,
    List<String>? tags,
    double? priceFrom,
    double? priceTo,
    double? rateFrom,
    double? rateTo,
    int? categoryId,
    String? token,
    String? cursor,
    int? page,
    int pageSize = 10,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page ?? 1,
      };

      if (query != null && query.isNotEmpty) {
        queryParams['name'] = query;
      }
      if (description != null) queryParams['description'] = description;
      if (tags != null && tags.isNotEmpty) queryParams['tags'] = tags.join(',');
      if (priceFrom != null) queryParams['price_from'] = priceFrom;
      if (priceTo != null) queryParams['price_to'] = priceTo;
      if (rateFrom != null) queryParams['rate_from'] = rateFrom;
      if (rateTo != null) queryParams['rate_to'] = rateTo;
      if (categoryId != null) queryParams['categories'] = categoryId;
      if (cursor != null) queryParams['cursor'] = cursor;

      debugPrint('📤 Sending request to /products');
      debugPrint('📋 Query parameters: $queryParams');

      return await _retryRequest(() async {
        final response = await _dio.get(
          '/products',
          queryParameters: queryParams,
          options: token != null ? _getAuthOptions(token) : null,
        );

        if (response.statusCode == 200 && response.data != null) {
          debugPrint('📥 Response received successfully');
          return PaginatedResponse<ProductModel>.fromJson(
            response.data,
            (json) => ProductModel.fromJson(json as Map<String, dynamic>),
          );
        } else {
          throw dio.DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: 'Invalid response format',
          );
        }
      });
    } catch (e) {
      debugPrint('❌ Error fetching products: $e');
      rethrow;
    }
  }

  Future<ProductModel> getProductById(int id, {String? token}) async {
    try {
      return await _retryRequest(() async {
        final response = await _dio.get(
          '/products/$id',
          options: token != null ? _getAuthOptions(token) : null,
        );

        if (response.data != null && response.data['data'] != null) {
          return ProductModel.fromJson(response.data['data']);
        }
        throw Exception('Product data not found');
      });
    } catch (e) {
      debugPrint('Error fetching product: $e');
      rethrow;
    }
  }

  Future<PaginatedResponse<ProductModel>> getProductsByCategory(
    int categoryId, {
    String? token,
    String? cursor,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'categories': categoryId,
        'page': page,
        'per_page': pageSize,
      };
      if (cursor != null) queryParams['cursor'] = cursor;

      return await _retryRequest(() async {
        final response = await _dio.get(
          '/products',
          queryParameters: queryParams,
          options: token != null ? _getAuthOptions(token) : null,
        );

        return PaginatedResponse<ProductModel>.fromJson(
          response.data,
          (json) => ProductModel.fromJson(json as Map<String, dynamic>),
        );
      });
    } catch (e) {
      debugPrint('Error fetching products by category: $e');
      rethrow;
    }
  }

  Future<void> clearLocalStorage() async {
    clearLocalProducts();
    debugPrint('Local storage cleared');
  }

  dio.Options _getAuthOptions(String token) {
    return dio.Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }
}
