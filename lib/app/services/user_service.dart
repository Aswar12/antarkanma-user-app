import 'package:antarkanma/app/data/models/user_model.dart';
import 'package:antarkanma/app/data/providers/user_provider.dart';
import 'package:dio/dio.dart' hide Response;
import 'package:get/get.dart' hide FormData, MultipartFile;

import './storage_service.dart';
import '../widgets/custom_snackbar.dart';

class UserService extends GetxService {
  final UserProvider _userProvider = UserProvider();
  final StorageService _storage = StorageService.instance;

  Future<UserModel?> getUserProfile() async {
    try {
      final token = _storage.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await _userProvider.getUserProfile(token);
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['data'];
        if (userData != null) {
          try {
            final user = UserModel.fromJson(userData);
            await _storage.saveUser(userData);
            return user;
          } catch (e) {
            print('Error parsing user data: $e');
            showCustomSnackbar(
                title: 'Error',
                message: 'Failed to parse user data',
                isError: true);
            return null;
          }
        }
      }
      throw Exception(response.data?['message'] ?? 'Failed to get user profile');
    } catch (e) {
      showCustomSnackbar(
          title: 'Error',
          message: 'Failed to get user profile: ${e.toString()}',
          isError: true);
      return null;
    }
  }

  Future<bool> updateUserProfile({
    required String name,
    String? email,
    String? phoneNumber,
    String? username,
    String? profileImageUrl,
  }) async {
    try {
      final token = _storage.getToken();
      if (token == null) throw Exception('Token not found');

      final data = {
        'name': name,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (username != null) 'username': username,
        if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      };

      final response = await _userProvider.updateUserProfile(token, data);
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['data'];
        if (userData != null) {
          try {
            await _storage.saveUser(userData);
            showCustomSnackbar(
                title: 'Success', message: 'Profile updated successfully');
            return true;
          } catch (e) {
            print('Error saving user data: $e');
            showCustomSnackbar(
                title: 'Error',
                message: 'Failed to save user data',
                isError: true);
            return false;
          }
        }
      }
      throw Exception(response.data?['message'] ?? 'Failed to update profile');
    } catch (e) {
      showCustomSnackbar(
          title: 'Error',
          message: 'Failed to update profile: ${e.toString()}',
          isError: true);
      return false;
    }
  }

  Future<String> uploadProfileImage(String imagePath) async {
    try {
      final token = _storage.getToken();
      if (token == null) throw Exception('Token not found');

      // Create FormData with the image file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath),
      });

      final response = await _userProvider.uploadProfileImage(token, formData);
      if (response.statusCode == 200 && response.data != null) {
        final imageUrl = response.data['data']?['image_url'];
        if (imageUrl != null && imageUrl is String) {
          return imageUrl;
        }
        throw Exception('Invalid image URL in response');
      }
      throw Exception(response.data?['message'] ?? 'Failed to upload image');
    } catch (e) {
      showCustomSnackbar(
          title: 'Error',
          message: 'Failed to upload image: ${e.toString()}',
          isError: true);
      return '';
    }
  }
}
