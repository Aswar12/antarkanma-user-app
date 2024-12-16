import 'package:antarkanma/app/data/models/user_model.dart';
import 'package:antarkanma/app/data/providers/user_provider.dart';
import 'package:get/get.dart';

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

      if (response.statusCode == 200) {
        final userData = response.data['data']['user'];
        return UserModel.fromJson(userData);
      }

      throw Exception(response.data['meta']['message']);
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
  }) async {
    try {
      final token = _storage.getToken();
      if (token == null) throw Exception('Token not found');

      final data = {
        'name': name,
        if (email != null) 'email': email,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (username != null) 'username': username,
      };

      final response = await _userProvider.updateUserProfile(token, data);

      if (response.statusCode == 200) {
        showCustomSnackbar(
            title: 'Success', message: 'Profile updated successfully');
        return true;
      }

      throw Exception(response.data['meta']['message']);
    } catch (e) {
      showCustomSnackbar(
          title: 'Error',
          message: 'Failed to update profile: ${e.toString()}',
          isError: true);
      return false;
    }
  }
}
