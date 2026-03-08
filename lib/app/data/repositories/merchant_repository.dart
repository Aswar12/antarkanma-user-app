import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/paginated_response.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/services/storage_service.dart';

class MerchantRepository {
  final MerchantService _merchantService = Get.find<MerchantService>();
  final StorageService _storage = StorageService.instance;

  /// Get paginated list of merchants with optional filters
  Future<PaginatedResponse<MerchantModel>> getMerchants({
    String? query,
    String? category,
    int page = 1,
    int pageSize = 10,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = _storage.getToken();
      return await _merchantService.getAllMerchants(
        query: query,
        category: category,
        token: token,
        page: page,
        pageSize: pageSize,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      debugPrint('❌ [MerchantRepository] getMerchants error: $e');
      rethrow;
    }
  }

  /// Get a single merchant by ID
  Future<MerchantModel> getMerchantById(int id) async {
    try {
      final token = _storage.getToken();
      return await _merchantService.getMerchantById(id, token: token);
    } catch (e) {
      debugPrint('❌ [MerchantRepository] getMerchantById error: $e');
      rethrow;
    }
  }

  /// Get popular merchants (limited list)
  Future<List<MerchantModel>> getPopularMerchants({
    int limit = 5,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final token = _storage.getToken();
      return await _merchantService.getPopularMerchants(
        token: token,
        limit: limit,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      debugPrint('❌ [MerchantRepository] getPopularMerchants error: $e');
      rethrow;
    }
  }

  /// Get paginated products for a specific merchant
  Future<PaginatedResponse<ProductModel>> getMerchantProducts(
    int merchantId, {
    String? query,
    String? category,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final token = _storage.getToken();
      return await _merchantService.getMerchantProducts(
        merchantId,
        query: query,
        category: category,
        token: token,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      debugPrint('❌ [MerchantRepository] getMerchantProducts error: $e');
      rethrow;
    }
  }
}
