import 'package:dio/dio.dart' as dio;
import 'package:antarkanma/config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/paginated_response.dart';
import 'package:antarkanma/app/data/providers/merchant_provider.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/services/location_service.dart';

class MerchantService extends GetxService {
  final MerchantProvider _merchantProvider = Get.find<MerchantProvider>();
  final LocationService _locationService = Get.find<LocationService>();
  final RxList<MerchantModel> _localMerchants = <MerchantModel>[].obs;
  static const int maxRetries = 3;

  void addMerchantToLocal(MerchantModel merchant) {
    if (!_localMerchants.contains(merchant)) {
      _localMerchants.add(merchant);
    }
  }

  List<MerchantModel> get localMerchants => _localMerchants.toList();

  void clearLocalMerchants() {
    _localMerchants.clear();
  }

  Future<PaginatedResponse<MerchantModel>> getAllMerchants({
    String? query,
    String? category,
    String? token,
    int page = 1,
    int pageSize = 10,
    double? latitude,
    double? longitude,
  }) async {
    try {
      debugPrint('📤 Sending request to get all merchants');
      debugPrint('📋 Query parameters: ${{
        'query': query,
        'category': category,
        'page': page,
        'pageSize': pageSize,
        'latitude': latitude,
        'longitude': longitude,
      }}');

      final response = await _merchantProvider.getAllMerchants(
        query: query,
        category: category,
        token: token,
        page: page,
        pageSize: pageSize,
        latitude: latitude,
        longitude: longitude,
      );

      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('Raw response data: ${response.data}');
        Map<String, dynamic> responseData;
        
        // Handle response structure
        if (response.data is Map) {
          if (response.data['meta'] != null && response.data['data'] != null) {
            // Standard API response with meta wrapper
            responseData = {
              'data': response.data['data'],
              'current_page': response.data['meta']['current_page'] ?? page,
              'last_page': response.data['meta']['last_page'] ?? page,
              'total': response.data['meta']['total'] ?? 0,
            };
          } else if (response.data['data'] != null) {
            // Response with data wrapper but no meta
            responseData = response.data;
          } else {
            // Direct response without wrappers
            responseData = {
              'data': [response.data],
              'current_page': page,
              'last_page': page,
              'total': 1,
            };
          }
        } else if (response.data is List) {
          // Direct list response
          responseData = {
            'data': response.data,
            'current_page': page,
            'last_page': page,
            'total': response.data.length,
          };
        } else {
          throw dio.DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: 'Unexpected response data type: ${response.data.runtimeType}',
          );
        }

        debugPrint('Structured response data: $responseData');

        debugPrint('Creating PaginatedResponse from data: $responseData');
        final paginatedResponse = PaginatedResponse<MerchantModel>.fromJson(
          responseData,
          (json) {
            debugPrint('Parsing merchant data: $json');
            return MerchantModel.fromJson(json);
          },
        );
        debugPrint('Created PaginatedResponse: $paginatedResponse');
        return paginatedResponse;
      } else {
        debugPrint(
            'Invalid response: Status ${response.statusCode}, Data: ${response.data}');
        throw dio.DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid response format',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching merchants: $e');
      rethrow;
    }
  }

  Future<MerchantModel> getMerchantById(int id, {String? token}) async {
    try {
      final response = await _merchantProvider.getMerchantById(id, token: token);

      if (response.data != null) {
        final merchantData = response.data['data'] ?? response.data;
        if (merchantData != null) {
          debugPrint('Merchant data before parsing: $merchantData');
          final merchant = MerchantModel.fromJson(merchantData);
          debugPrint('Parsed merchant: $merchant');
          return merchant;
        }
      }
      throw Exception('Merchant data not found');
    } catch (e) {
      debugPrint('Error fetching merchant: $e');
      rethrow;
    }
  }

  Future<List<MerchantModel>> getPopularMerchants({
    String? token,
    int limit = 5,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _merchantProvider.getPopularMerchants(
        token: token,
        limit: limit,
        latitude: latitude,
        longitude: longitude,
      );

      if (response.data != null) {
        final List<dynamic> data;
        if (response.data['data'] != null) {
          data = response.data['data'];
        } else if (response.data is List) {
          data = response.data;
        } else {
          throw Exception('Unexpected response format');
        }
        debugPrint('Popular merchants data before parsing: $data');
        final merchants = data.map((json) {
          debugPrint('Parsing merchant data: $json');
          return MerchantModel.fromJson(json);
        }).toList();
        debugPrint('Parsed merchants: $merchants');
        return merchants;
      }
      throw Exception('Popular merchants data not found');
    } catch (e) {
      debugPrint('Error fetching popular merchants: $e');
      rethrow;
    }
  }

  Future<PaginatedResponse<ProductModel>> getMerchantProducts(
    int merchantId, {
    String? query,
    String? category,
    String? token,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _merchantProvider.getMerchantProducts(
        merchantId,
        query: query,
        category: category,
        token: token,
        page: page,
        pageSize: pageSize,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data['data'] ?? response.data;
        debugPrint('Product response data: $responseData');
        return PaginatedResponse<ProductModel>.fromJson(
          responseData,
          (json) {
            debugPrint('Parsing product data: $json');
            return ProductModel.fromJson(json);
          },
        );
      } else {
        throw dio.DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Invalid response format',
        );
      }
    } catch (e) {
      debugPrint('Error fetching merchant products: $e');
      rethrow;
    }
  }

  Future<void> clearLocalStorage() async {
    clearLocalMerchants();
    debugPrint('Local storage cleared');
  }
}
