import 'package:dio/dio.dart';
import 'package:antarkanma/config.dart';

class MerchantProvider {
  final Dio _dio = Dio();
  final String baseUrl = Config.baseUrl;

  MerchantProvider() {
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
          print('Making request to: ${options.path}');
          print('Request data: ${options.data}');
          options.headers.addAll({
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          });
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('Response received: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          print('Error occurred: ${error.message}');
          print('Error response: ${error.response?.data}');
          _handleError(error);
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> getMerchantsByOwnerId(String token, int ownerId) async {
    try {
      print('Fetching merchant data for owner ID: $ownerId');
      final response = await _dio.get(
        '/merchants/owner/$ownerId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      print('API Response: ${response.data}');
      return response;
    } catch (e) {
      print('Error fetching merchants: $e');
      throw Exception('Failed to load merchants: $e');
    }
  }

  Future<Response> updateMerchant(
      String token, int merchantId, Map<String, dynamic> data) async {
    try {
      print('Updating merchant $merchantId with data: $data');
      final response = await _dio.put(
        '/merchant/$merchantId',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
        data: data,
      );
      print('Update response: ${response.data}');
      return response;
    } catch (e) {
      print('Error updating merchant: $e');
      throw Exception('Failed to update merchant: $e');
    }
  }

  Future<Response> createProduct(
      String token, int merchantId, Map<String, dynamic> data) async {
    try {
      print('Creating product for merchant ID: $merchantId');
      data['merchant_id'] = merchantId;

      final response = await _dio.post(
        '/products',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
        data: data,
      );
      print('Product creation response: ${response.data}');
      return response;
    } catch (e) {
      print('Error creating product: $e');
      throw Exception('Failed to create product: $e');
    }
  }

  Future<Response> uploadProductGallery(
      String token, int productId, List<String> imagePaths) async {
    try {
      print('Uploading gallery for product ID: $productId');

      final formData = FormData.fromMap({
        for (var i = 0; i < imagePaths.length; i++)
          'images[$i]': await MultipartFile.fromFile(imagePaths[i]),
      });

      final response = await _dio.post(
        '/products/$productId/gallery',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
        data: formData,
      );
      print('Gallery upload response: ${response.data}');
      return response;
    } catch (e) {
      print('Error uploading gallery: $e');
      throw Exception('Failed to upload gallery: $e');
    }
  }

  Future<Response> getMerchantProducts(String token, int merchantId) async {
    try {
      print('Fetching products for merchant ID: $merchantId');
      final response = await _dio.get(
        '/merchants/$merchantId/products',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      print('Products API Response: ${response.data}');
      return response;
    } catch (e) {
      print('Error fetching merchant products: $e');
      throw Exception('Failed to load merchant products: $e');
    }
  }

  void _handleError(DioException error) {
    String message;
    print('Error status code: ${error.response?.statusCode}');
    print('Error response data: ${error.response?.data}');

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
        message = errors?.toString() ?? 'Validation error occurred';
        break;
      default:
        message = error.response?.data?['message'] ?? 'An error occurred';
    }
    throw Exception(message);
  }
}
