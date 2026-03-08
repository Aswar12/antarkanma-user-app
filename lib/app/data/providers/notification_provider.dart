import 'package:dio/dio.dart';
import 'package:antarkanma/config.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

class NotificationProvider {
  final Dio _dio = Dio();
  final String baseUrl = Config.baseUrl;
  final _storage = GetStorage();

  NotificationProvider() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      validateStatus: (status) => status! < 500,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Get the authentication token, not FCM token
        final authToken = _storage.read('token');
        if (authToken != null) {
          options.headers['Authorization'] = 'Bearer $authToken';
        }
        return handler.next(options);
      },
    ));
  }

  Future<Response> registerFCMToken(String fcmToken, String userId,
      {String? role}) async {
    try {
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FCM token is null or empty, skipping registration');
        throw Exception('FCM token is required');
      }

      debugPrint('Registering FCM token for user $userId with role $role');
      debugPrint('Current token from storage: ${_storage.read('token')?.substring(0, 20)}...');
      
      final response = await _dio.post(
        '/fcm/token', // Updated to match api.php
        data: {
          'token': fcmToken,
          'user_id': userId,
          'role': role,
          'device_type': defaultTargetPlatform.name.toLowerCase(),
          'platform': defaultTargetPlatform.name.toLowerCase(),
          'app_version': '1.0.0',
        },
      );

      if (response.statusCode == 401) {
        debugPrint('401 Unauthorized - Token may be expired. Clearing storage and retrying...');
        // Clear invalid token
        await _storage.remove('token');
        throw Exception('Authentication failed: Token expired or invalid');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        debugPrint('Failed to register FCM token. Status: ${response.statusCode}');
        debugPrint('Response: ${response.data}');
        throw Exception(
            'Failed to register FCM token. Status: ${response.statusCode}');
      }

      debugPrint('FCM Token registration successful: ${response.data}');
      return response;
    } on DioException catch (e) {
      debugPrint('Dio error registering FCM token: ${e.message}');
      if (e.response != null) {
        debugPrint('Response status: ${e.response!.statusCode}');
        debugPrint('Response data: ${e.response!.data}');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('Authentication failed: Please login again');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
      rethrow;
    }
  }

  Future<Response> updateFCMToken(
      String oldFcmToken, String newFcmToken) async {
    try {
      // Logic for update might be the same as storeOrUpdateToken in backend,
      // or if backend handles update via same endpoint.
      // Assuming storeOrUpdateToken handles both based on token existence.
      // But looking at api.php, there's only storeOrUpdateToken at /fcm/token.
      // So we use that.

      final response = await _dio.post(
        '/fcm/token',
        data: {
          'token': newFcmToken, // Send new token
          'old_token':
              oldFcmToken, // Optional if backend supports it, otherwise just sending new one might be enough if it updates by user_id/device_id
          // Re-sending other necessary fields if required by backend validation
          'device_type': defaultTargetPlatform.name.toLowerCase(),
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update FCM token. Status: ${response.statusCode}');
      }

      print('FCM Token update successful: ${response.data}');
      return response;
    } catch (e) {
      print('Error updating FCM token: $e');
      throw Exception('Failed to update FCM token: $e');
    }
  }

  Future<Response> unregisterFCMToken(String fcmToken) async {
    try {
      final response = await _dio.delete(
        '/fcm/token',
        data: {
          'token':
              fcmToken, // Changed from fcm_token to token to match likely controller expectation
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to unregister FCM token. Status: ${response.statusCode}');
      }

      print('FCM Token unregistration successful: ${response.data}');
      return response;
    } catch (e) {
      print('Error unregistering FCM token: $e');
      throw Exception('Failed to unregister FCM token: $e');
    }
  }
}
