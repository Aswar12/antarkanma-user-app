import 'dart:io';
import 'package:antarkanma/app/data/models/user_model.dart';
import 'package:antarkanma/app/data/providers/auth_provider.dart';
import 'package:antarkanma/app/utils/validators.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:dio/dio.dart';
import 'package:antarkanma/app/services/fcm_token_service.dart';
import 'package:antarkanma/app/services/location_service.dart';
import 'package:antarkanma/app/services/user_location_service.dart';

class AuthService extends GetxService {
  late final StorageService _storageService;
  late final AuthProvider _authProvider;

  final RxBool isLoggedIn = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  AuthService() {
    try {
      _storageService = Get.find<StorageService>();
      _authProvider = Get.find<AuthProvider>();
    } catch (e) {
      debugPrint('Error initializing AuthService dependencies: $e');
      rethrow;
    }
  }

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

  Future<void> _handleFCMToken({bool register = true}) async {
    if (Get.currentRoute.contains('splash')) {
      print('Skipping FCM token handling during splash/initialization');
      return;
    }

    try {
      FCMTokenService? fcmTokenService;
      try {
        if (!Get.isRegistered<FCMTokenService>()) {
          print('FCMTokenService not registered yet, initializing...');
          await Get.putAsync(() async {
            final service = FCMTokenService();
            await service.init();
            return service;
          });
        }
        fcmTokenService = Get.find<FCMTokenService>();
      } catch (e) {
        print('Error initializing FCMTokenService: $e');
        return;
      }

      if (fcmTokenService == null) return;

      if (register) {
        final fcmToken = fcmTokenService.currentToken;
        final userId = currentUser.value?.id;
        if (fcmToken != null && userId != null) {
          try {
            await fcmTokenService.registerFCMToken(fcmToken);
          } catch (e) {
            print('Error registering FCM token: $e');
          }
        }
      } else {
        try {
          await fcmTokenService.unregisterToken();
        } catch (e) {
          print('Error unregistering FCM token: $e');
        }
      }
    } catch (e) {
      print('Error in FCM token handling: $e');
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

  Future<bool> autoLogin() async {
    try {
      final token = _storageService.getToken();
      final rememberMe = _storageService.getRememberMe();
      
      if (token == null || !rememberMe) return false;

      final isValid = await verifyToken(token);
      if (!isValid) return false;

      final credentials = _storageService.getSavedCredentials();
      if (credentials == null) return false;

      final loginSuccess = await login(
        credentials['identifier']!,
        credentials['password']!,
        rememberMe: true,
        isAutoLogin: true,
        showError: false
      );

      if (loginSuccess) {
        // Initialize location services after successful login
        final locationService = Get.find<LocationService>();
        await locationService.init();

        // Initialize UserLocationService
        if (!Get.isRegistered<UserLocationService>()) {
          Get.put(UserLocationService(), permanent: true);
        }

        return true;
      }

      return false;
    } catch (e) {
      print('Error during auto-login: $e');
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

      if (token != null && userData != null) {
        try {
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

          if (!isAutoLogin) {
            await _handleFCMToken(register: true);
          }

          if (!isAutoLogin) {
            Get.offAllNamed(Routes.userMainPage);
            if (showError) {
              showCustomSnackbar(title: 'Sukses', message: 'Login berhasil');
            }
          }
          return true;
        } catch (e) {
          print('Error parsing user data: $e');
          if (!isAutoLogin && showError) {
            showCustomSnackbar(
                title: 'Error', message: 'Data pengguna tidak valid', isError: true);
          }
          return false;
        }
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
          try {
            final user = UserModel.fromJson(userData);
            await _storageService.saveToken(token);
            await _storageService.saveUser(userData);
            currentUser.value = user;
            isLoggedIn.value = true;
            Get.offAllNamed(Routes.userMainPage);
            return true;
          } catch (e) {
            print('Error parsing user data: $e');
            showCustomSnackbar(
                title: 'Error', message: 'Data pengguna tidak valid', isError: true);
            return false;
          }
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
            if (showError) {
              showCustomSnackbar(
                  title: 'Error',
                  message: 'Data profil tidak valid',
                  isError: true);
            }
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting profile: $e');
      if (showError) {
        showCustomSnackbar(
            title: 'Error',
            message: 'Gagal mengambil profil: ${e.toString()}',
            isError: true);
      }
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
          if (userData != null) {
            try {
              final user = UserModel.fromJson(userData);
              await _storageService.saveUser(userData);
              currentUser.value = user;
              showCustomSnackbar(
                  title: 'Sukses', message: 'Foto profil berhasil diperbarui');
              return true;
            } catch (e) {
              print('Error parsing user data: $e');
              showCustomSnackbar(
                  title: 'Error',
                  message: 'Data profil tidak valid',
                  isError: true);
              return false;
            }
          }
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
          if (userData != null) {
            try {
              final user = UserModel.fromJson(userData);
              await _storageService.saveUser(userData);
              currentUser.value = user;
              showCustomSnackbar(
                  title: 'Sukses', message: 'Profil berhasil diperbarui');
              return true;
            } catch (e) {
              print('Error parsing user data: $e');
              showCustomSnackbar(
                  title: 'Error',
                  message: 'Data profil tidak valid',
                  isError: true);
              return false;
            }
          }
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
