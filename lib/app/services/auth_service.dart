import 'dart:io';
import 'package:antarkanma/app/data/models/user_model.dart';
import 'package:antarkanma/app/data/providers/auth_provider.dart';
import 'package:antarkanma/app/utils/validators.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:dio/dio.dart';
import 'package:antarkanma/app/services/fcm_token_service.dart';

class AuthService extends GetxService {
  final StorageService _storageService = StorageService.instance;
  final AuthProvider _authProvider = AuthProvider();

  final RxBool isLoggedIn = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // Getters
  String? getToken() => _storageService.getToken();
  UserModel? getUser() => currentUser.value;
  String get userName => currentUser.value?.name ?? '';
  String get userEmail => currentUser.value?.email ?? '';
  String get userPhone => currentUser.value?.phoneNumber ?? '';
  String get userRole => currentUser.value?.role ?? '';
  bool get isUser => currentUser.value?.isUser ?? false;
  int? get userId => currentUser.value?.id;
  String? get userProfilePhotoUrl => currentUser.value?.profilePhotoUrl;
  String? get userProfilePhotoPath => currentUser.value?.profilePhotoPath;
  bool get isRememberMeEnabled => _storageService.getRememberMe();

  // FCM token management
  Future<void> _handleFCMToken({bool register = true}) async {
    try {
      final fcmTokenService = Get.find<FCMTokenService>();
      if (register) {
        final fcmToken = fcmTokenService.currentToken;
        if (fcmToken != null && currentUser.value?.id != null) {
          await fcmTokenService.registerFCMToken(fcmToken);
        }
      } else {
        await fcmTokenService.unregisterToken();
      }
    } catch (e) {
      print('Error handling FCM token: $e');
    }
  }

  Future<bool> verifyToken(String token) async {
    try {
      final response = await _authProvider.refreshToken(token);
      return response.statusCode == 200;
    } catch (e) {
      print('Error verifying token: $e');
      return false;
    }
  }

  Future<bool> refreshToken() async {
    try {
      final currentToken = _storageService.getToken();
      if (currentToken == null) return false;

      final response = await _authProvider.refreshToken(currentToken);
      if (response.statusCode == 200) {
        final newToken = response.data['data']['access_token'];
        await _storageService.saveToken(newToken);
        return true;
      }
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  Future<bool> login(
    String identifier,
    String password, {
    bool rememberMe = false,
    bool isAutoLogin = false,
    bool showError = true,
  }) async {
    try {
      if (!isAutoLogin) {
        final validationError = Validators.validateIdentifier(identifier);
        if (validationError != null && showError) {
          showCustomSnackbar(
              title: 'Error', message: validationError, isError: true);
          return false;
        }
      }

      final response = await _authProvider.login(identifier, password);
      if (response.statusCode != 200) {
        if (!isAutoLogin && showError) {
          showCustomSnackbar(
              title: 'Login Gagal',
              message: response.data['meta']['message'] ?? 'Terjadi kesalahan',
              isError: true);
        }
        return false;
      }

      final userData = response.data['data']['user'];
      final token = response.data['data']['access_token'];

      if (token != null) {
        final user = UserModel.fromJson(userData);
        if (!user.isUser) {
          if (!isAutoLogin && showError) {
            showCustomSnackbar(
                title: 'Login Gagal',
                message: 'Aplikasi ini hanya untuk pengguna.',
                isError: true);
          }
          return false;
        }

        await _storageService.saveToken(token);
        await _storageService.saveUser(userData);

        if (rememberMe) {
          await _storageService.saveRememberMe(true);
          await _storageService.saveCredentials(identifier, password);
        } else {
          await _storageService.clearCredentials();
        }

        currentUser.value = user;
        isLoggedIn.value = true;

        await _handleFCMToken(register: true);

        if (!isAutoLogin) {
          Get.offAllNamed(Routes.userMainPage);
          if (showError) {
            showCustomSnackbar(title: 'Sukses', message: 'Login berhasil');
          }
        }
        return true;
      }

      if (!isAutoLogin && showError) {
        showCustomSnackbar(
            title: 'Error', message: 'Token tidak valid.', isError: true);
      }
      return false;
    } catch (e) {
      if (!isAutoLogin && showError) {
        showCustomSnackbar(
            title: 'Error',
            message: 'Gagal login: ${e.toString()}',
            isError: true);
      }
      return false;
    }
  }

  Future<bool> register(String name, String email, String phoneNumber,
      String password, String confirmPassword) async {
    try {
      if ([name, email, phoneNumber, password].any((field) => field.isEmpty)) {
        showCustomSnackbar(
            title: 'Error', message: 'Semua field harus diisi.', isError: true);
        return false;
      }

      final userData = {
        'name': name,
        'email': email,
        'phone_number': phoneNumber,
        'password': password,
        'password_confirmation': confirmPassword,
        'role': UserModel.ROLE_USER,
      };

      final response = await _authProvider.register(userData);
      if (response.statusCode == 200) {
        final userData = response.data['data']['user'];
        final token = response.data['data']['access_token'];
        if (token != null && userData != null) {
          await _storageService.saveToken(token);
          await _storageService.saveUser(userData);
          currentUser.value = UserModel.fromJson(userData);
          isLoggedIn.value = true;
          Get.offAllNamed(Routes.userMainPage);
          return true;
        }
        showCustomSnackbar(
            title: 'Error', message: 'Data login tidak valid.', isError: true);
        return false;
      }

      showCustomSnackbar(
          title: 'Registrasi Gagal',
          message: response.data['meta']['message'] ?? 'Registrasi gagal',
          isError: true);
      return false;
    } catch (e) {
      showCustomSnackbar(
          title: 'Error',
          message: 'Gagal registrasi: ${e.toString()}',
          isError: true);
      return false;
    }
  }

  Future<UserModel?> getProfile({bool showError = false}) async {
    try {
      final token = _storageService.getToken();
      if (token == null) return null;

      final response = await _authProvider.getProfile(token, silent: true);
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['data'];
        if (userData != null) {
          try {
            final user = UserModel.fromJson(userData);
            await _storageService.saveUser(userData);
            currentUser.value = user;
            return user;
          } catch (e) {
            print('Error parsing user data: $e');
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting profile: $e');
      return null;
    }
  }

  Future<bool> updateProfilePhoto(File photo) async {
    try {
      final token = _storageService.getToken();
      if (token == null) {
        showCustomSnackbar(
            title: 'Error', message: 'Token tidak valid', isError: true);
        return false;
      }

      final fileSize = await photo.length();
      if (fileSize > 2 * 1024 * 1024) {
        showCustomSnackbar(
            title: 'Error',
            message: 'Ukuran file melebihi batas 2MB',
            isError: true);
        return false;
      }

      final extension = photo.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        showCustomSnackbar(
            title: 'Error',
            message: 'Format file tidak valid. Gunakan JPG, JPEG, atau PNG',
            isError: true);
        return false;
      }

      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: 'profile_photo.$extension',
        ),
      });

      final response = await _authProvider.updateProfilePhoto(token, formData);
      if (response.statusCode == 200) {
        final userResponse = await _authProvider.getProfile(token);
        if (userResponse.statusCode == 200) {
          final userData = userResponse.data['data'];
          await _storageService.saveUser(userData);
          currentUser.value = UserModel.fromJson(userData);
          showCustomSnackbar(
              title: 'Sukses', message: 'Foto profil berhasil diperbarui');
          return true;
        }
      }

      showCustomSnackbar(
          title: 'Error',
          message: response.data['message'] ?? 'Gagal memperbarui foto profil',
          isError: true);
      return false;
    } catch (e) {
      showCustomSnackbar(
          title: 'Error',
          message: 'Gagal memperbarui foto profil: ${e.toString()}',
          isError: true);
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? phoneNumber,
  }) async {
    try {
      final token = _storageService.getToken();
      if (token == null) {
        showCustomSnackbar(
            title: 'Error', message: 'Token tidak valid', isError: true);
        return false;
      }

      final updateData = {
        'name': name,
        'email': email,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      };

      final response = await _authProvider.updateProfile(token, updateData);
      if (response.statusCode == 200) {
        final userResponse = await _authProvider.getProfile(token);
        if (userResponse.statusCode == 200) {
          final userData = userResponse.data['data'];
          await _storageService.saveUser(userData);
          currentUser.value = UserModel.fromJson(userData);
          showCustomSnackbar(
              title: 'Sukses', message: 'Profil berhasil diperbarui');
          return true;
        }
      }

      showCustomSnackbar(
          title: 'Error',
          message: response.data['message'] ?? 'Gagal memperbarui profil',
          isError: true);
      return false;
    } catch (e) {
      showCustomSnackbar(
          title: 'Error',
          message: 'Gagal memperbarui profil: ${e.toString()}',
          isError: true);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final token = _storageService.getToken();
      if (token != null) {
        await _authProvider.logout(token);
        await _handleFCMToken(register: false);
      }
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      await _clearAuthData(fullClear: true);
      Get.offAllNamed(Routes.login);
    }
  }

  Future<void> _clearAuthData({bool fullClear = false}) async {
    if (fullClear) {
      if (_storageService.getRememberMe()) {
        final credentials = _storageService.getSavedCredentials();
        await _storageService.clearAll();
        if (credentials != null) {
          await _storageService.saveRememberMe(true);
          await _storageService.saveCredentials(
              credentials['identifier']!, credentials['password']!);
        }
      } else {
        await _storageService.clearAll();
      }
    } else {
      await _storageService.clearAuth();
    }

    isLoggedIn.value = false;
    currentUser.value = null;
  }

  void handleAuthError(dynamic error) {
    if (error.toString().contains('401')) {
      _clearAuthData(fullClear: true);
      Get.offAllNamed(Routes.login);
    }
  }

  @override
  void onClose() {
    currentUser.close();
    super.onClose();
  }
}
