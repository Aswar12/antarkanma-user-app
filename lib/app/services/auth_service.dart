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

class AuthService extends GetxService {
  StorageService? _storageService;
  AuthProvider? _authProvider;
  final _isInitialized = false.obs;
  final _isRefreshing = false.obs;

  final RxBool isLoggedIn = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  // Getters for user info
  String? get userName => currentUser.value?.name;
  String? get userPhone => currentUser.value?.phoneNumber;
  String? get userEmail => currentUser.value?.email;

  // Token management
  String? getToken() => _storageService?.getToken();
  UserModel? getUser() => currentUser.value;

  AuthService();

  Future<void> _initializeService() async {
    if (_isInitialized.value) return;

    try {
      _storageService = StorageService.instance;
      await _storageService?.ensureInitialized();

      if (!Get.isRegistered<AuthProvider>()) {
        Get.put(AuthProvider(), permanent: true);
      }
      _authProvider = Get.find<AuthProvider>();

      // Check if there's a valid token and user data
      final token = _storageService?.getToken();
      final userData = _storageService?.getUser();

      if (token != null && userData != null) {
        try {
          final user = UserModel.fromJson(userData);
          if (user.role.toUpperCase() == 'USER') {
            currentUser.value = user;
            isLoggedIn.value = true;
            debugPrint('Valid user found in storage, setting logged in state');
          } else {
            debugPrint('Non-user role found in storage, clearing auth data');
            await _clearAuthData(fullClear: true);
          }
        } catch (e) {
          debugPrint('Error parsing stored user data: $e');
          await _clearAuthData(fullClear: true);
        }
      } else {
        debugPrint('No valid auth data found in storage');
        isLoggedIn.value = false;
      }

      _isInitialized.value = true;
      debugPrint('AuthService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AuthService: $e');
      rethrow;
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized.value) {
      await _initializeService();
    }
  }

  Future<void> handleAuthError(DioException error) async {
    if (error.response?.statusCode == 401) {
      debugPrint('Handling 401 error - attempting token refresh');
      final token = _storageService?.getToken();
      if (token != null) {
        try {
          final response = await _authProvider!.refreshToken(token);
          if (response.statusCode == 200 && response.data != null) {
            final newToken = response.data['data']['access_token'];
            if (newToken != null) {
              await _storageService!.saveToken(newToken);
              debugPrint('Token refreshed successfully');
              return;
            }
          }
        } catch (e) {
          debugPrint('Error refreshing token: $e');
        }
      }
      debugPrint('Token refresh failed, logging out');
      await logout();
    }
  }

  Future<bool> verifyToken(String token) async {
    try {
      if (!_isInitialized.value || _authProvider == null) return false;

      final response = await _authProvider!.getProfile(token);
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['data'];
        if (userData != null) {
          final user = UserModel.fromJson(userData);
          return user.role.toUpperCase() == 'USER';
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error verifying token: $e');
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
      debugPrint('Login attempt - identifier: $identifier');
      if (!_isInitialized.value ||
          _authProvider == null ||
          _storageService == null) {
        debugPrint('Services not initialized');
        return false;
      }

      if (!isAutoLogin) {
        final validationError = Validators.validateIdentifier(identifier);
        if (validationError != null && showError) {
          showCustomSnackbar(
              title: 'Error', message: validationError, isError: true);
          return false;
        }
      }

      final response = await _authProvider!.login(identifier, password);
      debugPrint('Login response status: ${response.statusCode}');

      if (response.statusCode != 200 || response.data == null) {
        if (!isAutoLogin && showError) {
          showCustomSnackbar(
              title: 'Login Gagal',
              message:
                  response.data?['meta']?['message'] ?? 'Terjadi kesalahan',
              isError: true);
        }
        return false;
      }

      final userData = response.data['data']['user'];
      final token = response.data['data']['access_token'];

      if (token != null && userData != null) {
        try {
          final user = UserModel.fromJson(userData);

          // Check if user role is USER
          if (user.role.toUpperCase() != 'USER') {
            if (!isAutoLogin && showError) {
              showCustomSnackbar(
                  title: 'Login Gagal',
                  message: 'Aplikasi ini hanya untuk pengguna.',
                  isError: true);
            }
            return false;
          }

          // Save token and user data
          await _storageService!.saveToken(token);
          await _storageService!.saveUser(userData);

          // Handle remember me
          if (rememberMe) {
            debugPrint('Saving credentials for auto-login');
            await _storageService!.saveRememberMe(true);
            await _storageService!.saveCredentials(identifier, password);
          } else {
            debugPrint('Clearing saved credentials');
            await _storageService!.clearCredentials();
            await _storageService!.saveRememberMe(false);
          }

          currentUser.value = user;
          isLoggedIn.value = true;

          if (!isAutoLogin) {
            // Register FCM token after successful login
            await _handleFCMToken(register: true);
            Get.offAllNamed(Routes.userMainPage);
            if (showError) {
              showCustomSnackbar(title: 'Sukses', message: 'Login berhasil');
            }
          }
          debugPrint('Login successful - user: ${user.name}');
          return true;
        } catch (e) {
          debugPrint('Error parsing user data: $e');
          if (!isAutoLogin && showError) {
            showCustomSnackbar(
                title: 'Error',
                message: 'Data pengguna tidak valid',
                isError: true);
          }
          return false;
        }
      }

      debugPrint('Invalid token or user data');
      if (!isAutoLogin && showError) {
        showCustomSnackbar(
            title: 'Error', message: 'Token tidak valid.', isError: true);
      }
      return false;
    } catch (e) {
      debugPrint('Error during login: $e');
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
      if (!_isInitialized.value ||
          _authProvider == null ||
          _storageService == null) {
        return false;
      }

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
        'role': 'USER',
      };

      final response = await _authProvider!.register(userData);
      if (response.statusCode == 200) {
        final userData = response.data['data']['user'];
        final token = response.data['data']['access_token'];
        if (token != null && userData != null) {
          try {
            final user = UserModel.fromJson(userData);
            await _storageService!.saveToken(token);
            await _storageService!.saveUser(userData);
            currentUser.value = user;
            isLoggedIn.value = true;
            Get.offAllNamed(Routes.userMainPage);
            return true;
          } catch (e) {
            debugPrint('Error parsing user data: $e');
            showCustomSnackbar(
                title: 'Error',
                message: 'Data pengguna tidak valid',
                isError: true);
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
      if (!_isInitialized.value ||
          _authProvider == null ||
          _storageService == null) {
        return null;
      }

      final token = _storageService!.getToken();
      if (token == null) return null;

      final response = await _authProvider!.getProfile(token, silent: true);
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data['data'];
        if (userData != null) {
          try {
            final user = UserModel.fromJson(userData);
            await _storageService!.saveUser(userData);
            currentUser.value = user;
            return user;
          } catch (e) {
            debugPrint('Error parsing user data: $e');
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
      debugPrint('Error getting profile: $e');
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
      if (!_isInitialized.value ||
          _authProvider == null ||
          _storageService == null) {
        return false;
      }

      final token = _storageService!.getToken();
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

      final response = await _authProvider!.updateProfilePhoto(token, formData);
      if (response.statusCode == 200) {
        final userResponse = await _authProvider!.getProfile(token);
        if (userResponse.statusCode == 200) {
          final userData = userResponse.data['data'];
          if (userData != null) {
            try {
              final user = UserModel.fromJson(userData);
              await _storageService!.saveUser(userData);
              currentUser.value = user;
              showCustomSnackbar(
                  title: 'Sukses', message: 'Foto profil berhasil diperbarui');
              return true;
            } catch (e) {
              debugPrint('Error parsing user data: $e');
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
      if (!_isInitialized.value ||
          _authProvider == null ||
          _storageService == null) {
        return false;
      }

      final token = _storageService!.getToken();
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

      final response = await _authProvider!.updateProfile(token, updateData);
      if (response.statusCode == 200) {
        final userResponse = await _authProvider!.getProfile(token);
        if (userResponse.statusCode == 200) {
          final userData = userResponse.data['data'];
          if (userData != null) {
            try {
              final user = UserModel.fromJson(userData);
              await _storageService!.saveUser(userData);
              currentUser.value = user;
              showCustomSnackbar(
                  title: 'Sukses', message: 'Profil berhasil diperbarui');
              return true;
            } catch (e) {
              debugPrint('Error parsing user data: $e');
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
      if (!_isInitialized.value ||
          _authProvider == null ||
          _storageService == null) return;

      final token = _storageService!.getToken();
      if (token != null) {
        await _authProvider!.logout(token);
        await _handleFCMToken(register: false);
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      await _clearAuthData(fullClear: true);
      Get.offAllNamed(Routes.login);
    }
  }

  Future<void> _clearAuthData({bool fullClear = false}) async {
    if (!_isInitialized.value || _storageService == null) return;

    if (fullClear) {
      if (_storageService!.getRememberMe()) {
        // Keep credentials if remember me is enabled
        final credentials = _storageService!.getSavedCredentials();
        await _storageService!.clearAll();
        if (credentials != null) {
          await _storageService!.saveRememberMe(true);
          await _storageService!.saveCredentials(
              credentials['identifier']!, credentials['password']!);
        }
      } else {
        await _storageService!.clearAll();
      }
    } else {
      await _storageService!.clearAuth();
    }

    isLoggedIn.value = false;
    currentUser.value = null;
  }

  Future<void> _handleFCMToken({bool register = true}) async {
    // ... rest of the code remains the same ...
  }
}
