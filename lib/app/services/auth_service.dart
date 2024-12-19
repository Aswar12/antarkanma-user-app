// ignore_for_file: avoid_print

import 'package:antarkanma/app/data/models/user_model.dart';
import 'package:antarkanma/app/data/providers/auth_provider.dart';
import 'package:antarkanma/app/utils/validators.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:get/get.dart';
import './storage_service.dart';
import '../routes/app_pages.dart';

class AuthService extends GetxService {
  final StorageService _storageService = StorageService.instance;
  final AuthProvider _authProvider = AuthProvider();

  final RxBool isLoggedIn = false.obs;
  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    checkLoginStatus();
    tryAutoLogin();
  }

  Future<void> checkLoginStatus() async {
    print('\n=== Auth Service Debug ===');
    final token = _storageService.getToken();
    final userData = _storageService.getUser();

    print('Checking login status:');
    print('- Token exists: ${token != null}');
    print('- User data exists: ${userData != null}');

    if (token != null && userData != null) {
      print('Verifying token...');
      final isValidToken = await verifyToken(token);
      print('- Token valid: $isValidToken');

      if (isValidToken) {
        isLoggedIn.value = true;
        currentUser.value = UserModel.fromJson(userData);
        print('- User role: ${currentUser.value?.role}');
        _redirectBasedOnRole();
      } else {
        print('Token invalid, trying auto login...');
        await tryAutoLogin();
      }
    } else {
      print('No stored credentials found');
    }
  }

  Future<void> tryAutoLogin() async {
    if (!isLoggedIn.value && _storageService.getRememberMe()) {
      final credentials = _storageService.getSavedCredentials();
      if (credentials != null) {
        await login(
          credentials['identifier']!,
          credentials['password']!,
          rememberMe: true,
          isAutoLogin: true,
        );
      }
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
        await _storageService.saveToken(token);
        await _storageService.saveUser(userData);

        if (rememberMe) {
          await _storageService.saveRememberMe(true);
          await _storageService.saveCredentials(identifier, password);
        } else {
          await _storageService.clearCredentials();
        }

        currentUser.value = UserModel.fromJson(userData);
        isLoggedIn.value = true;
        _redirectBasedOnRole();

        if (!isAutoLogin) {
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
          _redirectBasedOnRole();
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

  void _redirectBasedOnRole() {
    if (currentUser.value == null) return;

    switch (currentUser.value!.role) {
      case 'USER':
        Get.offAllNamed(Routes.main);
        break;
      case 'MERCHANT':
        Get.offAllNamed(Routes.merchantHome);
        break;
      case 'COURIER':
        Get.offAllNamed(Routes.courierHome);
        break;
      default:
        Get.offAllNamed(Routes.login);
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
        if (phoneNumber != null) 'phone_number': phoneNumber,
      };

      final response = await _authProvider.updateProfile(token, updateData);

      if (response.statusCode == 200) {
        final updatedUser = currentUser.value?.copyWith(
          name: name,
          email: email,
          phoneNumber: phoneNumber,
        );

        if (updatedUser != null) {
          await _storageService.saveUser(updatedUser.toJson());
          currentUser.value = updatedUser;
        }

        showCustomSnackbar(
            title: 'Sukses', message: 'Profil berhasil diperbarui');
        return true;
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
        await _clearAuthData();
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
      }
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      await _clearAuthData();
      Get.offAllNamed(Routes.login);
    }
  }

  Future<void> _clearAuthData() async {
    await _storageService.clearAuth();
    isLoggedIn.value = false;
    currentUser.value = null;
  }

  void handleAuthError(dynamic error) {
    if (error.toString().contains('401')) {
      _clearAuthData();
      showCustomSnackbar(
          title: 'Error',
          message: 'Sesi Anda telah berakhir. Silakan login kembali.',
          isError: true);
      Get.offAllNamed(Routes.login);
    }
  }

  // Getter Methods
  String? getToken() => _storageService.getToken();
  UserModel? getUser() => currentUser.value;
  String get userName => currentUser.value?.name ?? '';
  String get userEmail => currentUser.value?.email ?? '';
  String get userPhone => currentUser.value?.phoneNumber ?? '';
  String get userRole => currentUser.value?.role ?? '';
  bool get isMerchant => userRole == 'MERCHANT';
  bool get isCourier => userRole == 'COURIER';
  bool get isUser => userRole == 'USER';
  int? get userId => currentUser.value?.id;
  String? get userProfilePhotoUrl => currentUser.value?.profilePhotoUrl;
  String? get userProfilePhotoPath => currentUser.value?.profilePhotoPath;

  // Method untuk mengecek status remember me
  bool get isRememberMeEnabled => _storageService.getRememberMe();

  @override
  void onClose() {
    currentUser.close();
    super.onClose();
  }
}
