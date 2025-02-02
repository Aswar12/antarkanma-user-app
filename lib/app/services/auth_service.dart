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

  @override
  void onInit() {
    super.onInit();
  }

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
  }) async {
    try {
      if (!isAutoLogin) {
        final validationError = Validators.validateIdentifier(identifier);
        if (validationError != null) {
          showCustomSnackbar(
              title: 'Error', message: validationError, isError: true);
          return false;
        }
      }

      final response = await _authProvider.login(identifier, password);
      if (response.statusCode != 200) {
        if (!isAutoLogin) {
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
        // Create UserModel and check role
        final user = UserModel.fromJson(userData);
        if (!user.isUser) {
          if (!isAutoLogin) {
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
        print("User logged in successfully: ${currentUser.value}"); // Debug log
        isLoggedIn.value = true;

        // Register FCM token after successful login
        await _handleFCMToken(register: true);

        // Only redirect and show snackbar if not auto-login
        if (!isAutoLogin) {
          Get.offAllNamed(Routes.userMainPage);
          showCustomSnackbar(title: 'Sukses', message: 'Login berhasil');
        }
        return true;
      }

      if (!isAutoLogin) {
        showCustomSnackbar(
            title: 'Error', message: 'Token tidak valid.', isError: true);
      }
      return false;
    } catch (e) {
      if (!isAutoLogin) {
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
        'role': UserModel.ROLE_USER, // Use constant from UserModel
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

  Future<bool> updateProfilePhoto(File photo) async {
    try {
      final token = _storageService.getToken();
      if (token == null) {
        showCustomSnackbar(
            title: 'Error', message: 'Token tidak valid', isError: true);
        return false;
      }

      // Check file size before creating FormData (2MB limit)
      final fileSize = await photo.length();
      if (fileSize > 2 * 1024 * 1024) {
        showCustomSnackbar(
            title: 'Error',
            message: 'Ukuran file melebihi batas 2MB',
            isError: true);
        return false;
      }

      // Check file type
      final extension = photo.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(extension)) {
        showCustomSnackbar(
            title: 'Error',
            message: 'Format file tidak valid. Gunakan JPG, JPEG, atau PNG',
            isError: true);
        return false;
      }

      // Create form data with the correct field name
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(
          photo.path,
          filename: 'profile_photo.$extension',
        ),
      });

      try {
        final response =
            await _authProvider.updateProfilePhoto(token, formData);

        if (response.statusCode == 200) {
          // Get fresh user data
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

        final errorMessage =
            response.data['message'] ?? 'Gagal memperbarui foto profil';
        print('Upload failed: $errorMessage');
        print('Response data: ${response.data}');
        showCustomSnackbar(
            title: 'Error', message: errorMessage, isError: true);
        return false;
      } catch (e) {
        print('Error during API call: $e');
        throw e;
      }
    } catch (e) {
      print('Error in updateProfilePhoto: $e');
      String errorMessage = 'Gagal memperbarui foto profil';
      if (e.toString().contains('File size exceeds 2MB limit')) {
        errorMessage = 'Ukuran file melebihi batas 2MB';
      } else if (e.toString().contains('Invalid file type')) {
        errorMessage = 'Format file tidak valid. Gunakan JPG, JPEG, atau PNG';
      }
      showCustomSnackbar(title: 'Error', message: errorMessage, isError: true);
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

      // Validate input
      if (name.isEmpty) {
        showCustomSnackbar(
            title: 'Error', message: 'Nama tidak boleh kosong', isError: true);
        return false;
      }

      if (email.isNotEmpty && !GetUtils.isEmail(email)) {
        showCustomSnackbar(
            title: 'Error', message: 'Format email tidak valid', isError: true);
        return false;
      }

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        if (!GetUtils.isPhoneNumber(phoneNumber)) {
          showCustomSnackbar(
              title: 'Error',
              message: 'Format nomor telepon tidak valid',
              isError: true);
          return false;
        }
      }

      final updateData = {
        'name': name,
        'email': email,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      };

      final response = await _authProvider.updateProfile(token, updateData);

      if (response.statusCode == 200) {
        // Get fresh user data
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
      String errorMessage = 'Gagal memperbarui profil';
      if (e.toString().contains('Email already exists')) {
        errorMessage = 'Email sudah digunakan';
      } else if (e.toString().contains('Phone number already exists')) {
        errorMessage = 'Nomor telepon sudah digunakan';
      }
      showCustomSnackbar(title: 'Error', message: errorMessage, isError: true);
      return false;
    }
  }

  Future<UserModel?> getProfile() async {
    try {
      final token = _storageService.getToken();
      if (token == null) {
        showCustomSnackbar(
            title: 'Error', message: 'Token tidak valid', isError: true);
        return null;
      }

      final response = await _authProvider.getProfile(token);
      if (response.statusCode == 200) {
        final userData = response.data['data'];
        await _storageService.saveUser(userData);
        currentUser.value = UserModel.fromJson(userData);
        return currentUser.value;
      }

      return null;
    } catch (e) {
      showCustomSnackbar(
          title: 'Error',
          message: 'Gagal mengambil data profil: ${e.toString()}',
          isError: true);
      return null;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final token = _storageService.getToken();
      if (token == null) {
        showCustomSnackbar(
            title: 'Error', message: 'Token tidak valid', isError: true);
        return false;
      }

      if (newPassword.length < 6) {
        showCustomSnackbar(
            title: 'Error',
            message: 'Password baru harus memiliki minimal 6 karakter',
            isError: true);
        return false;
      }

      if (newPassword != confirmPassword) {
        showCustomSnackbar(
            title: 'Error',
            message: 'Password baru tidak cocok',
            isError: true);
        return false;
      }

      final response = await _authProvider.changePassword(token, {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      });

      if (response.statusCode == 200) {
        if (_storageService.getRememberMe()) {
          final credentials = _storageService.getSavedCredentials();
          if (credentials != null) {
            await _storageService.saveCredentials(
              credentials['identifier']!,
              newPassword,
            );
          }
        }

        showCustomSnackbar(
            title: 'Sukses', message: 'Password berhasil diubah');
        return true;
      }

      showCustomSnackbar(
          title: 'Error',
          message: response.data['message'] ?? 'Gagal mengganti password',
          isError: true);
      return false;
    } catch (e) {
      showCustomSnackbar(
          title: 'Error',
          message: 'Gagal mengganti password: ${e.toString()}',
          isError: true);
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      final token = _storageService.getToken();
      if (token == null) {
        showCustomSnackbar(
            title: 'Error', message: 'Token tidak valid', isError: true);
        return false;
      }

      final response = await _authProvider.deleteAccount(token);
      if (response.statusCode == 200) {
        showCustomSnackbar(title: 'Sukses', message: 'Akun berhasil dihapus');
        await _clearAuthData(fullClear: true);
        return true;
      }

      showCustomSnackbar(
          title: 'Error',
          message: response.data['message'] ?? 'Gagal menghapus akun',
          isError: true);
      return false;
    } catch (e) {
      showCustomSnackbar(
          title: 'Error',
          message: 'Gagal menghapus akun: ${e.toString()}',
          isError: true);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final token = _storageService.getToken();
      if (token != null) {
        await _authProvider.logout(token);
        // Unregister FCM token before logging out
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
      // Clear all data except remember me settings if enabled
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

    // Clear observable states
    isLoggedIn.value = false;
    currentUser.value = null;

    // Clear any cached data
    await _storageService.clearOrders();
    await _storageService.clearLocationData();
  }

  void handleAuthError(dynamic error) {
    if (error.toString().contains('401')) {
      _clearAuthData(fullClear: true);
      showCustomSnackbar(
          title: 'Error',
          message: 'Sesi Anda telah berakhir. Silakan login kembali.',
          isError: true);
      Get.offAllNamed(Routes.login);
    }
  }

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

  @override
  void onClose() {
    currentUser.close();
    super.onClose();
  }
}
