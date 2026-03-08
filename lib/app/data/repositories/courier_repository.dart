import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:antarkanma/config.dart';
import 'package:antarkanma/app/services/storage_service.dart';

class CourierRepository {
  final StorageService _storage = StorageService.instance;
  final Dio _dio = Dio(BaseOptions(baseUrl: Config.baseUrl));

  /// Get courier details by ID
  Future<Map<String, dynamic>?> getCourierById(int courierId) async {
    try {
      final token = _storage.getToken();
      final response = await _dio.get(
        '/api/couriers/$courierId',
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] ?? response.data;
        return data is Map<String, dynamic> ? data : null;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [CourierRepository] getCourierById error: $e');
      rethrow;
    }
  }
}
