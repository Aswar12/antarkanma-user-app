import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../routes/app_pages.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_snackbar.dart';
import '../utils/validators.dart';
import '../services/user_location_service.dart';
import '../services/location_service.dart';
import '../controllers/user_main_controller.dart';

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  var isConfirmPasswordHidden = true.obs;
  final formKey = GlobalKey<FormState>();
  final identifierController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final RxBool isLoading = false.obs;
  final RxBool isPasswordHidden = true.obs;
  final rememberMe = false.obs;
  final RxInt _rating = 0.obs;
  int get rating => _rating.value;

  late final StorageService _storageService;
  final _isInitialized = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      // Get storage instance
      _storageService = StorageService.instance;

      // Ensure storage is initialized
      await _storageService.ensureInitialized();

      // Load remember me state
      rememberMe.value = _storageService.getRememberMe();

      _isInitialized.value = true;
    } catch (e) {
      debugPrint('Error initializing AuthController: $e');
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      // Ensure controller is initialized
      if (!_isInitialized.value) {
        await _initializeController();
      }

      final token = _storageService.getToken();
      final rememberMe = _storageService.getRememberMe();

      if (token != null && rememberMe) {
        // Verify the token first
        final isValid = await _authService.verifyToken(token);
        if (isValid) {
          // Set logged in state
          _authService.isLoggedIn.value = true;

          // Try to get user profile
          final user = await _authService.getProfile(showError: false);

          if (user != null) {
            // Update current user in auth service
            _authService.currentUser.value = user;

            // Initialize auth-dependent services
            await _initializeAuthDependentServices();

            // Initialize UserMainController if needed
            if (!Get.isRegistered<UserMainController>()) {
              final userMainController = UserMainController();
              await userMainController.ensureInitialized();
              Get.put(userMainController, permanent: true);
            }

            // Navigate to main page if not already there
            if (Get.currentRoute != Routes.userMainPage) {
              Get.offAllNamed(Routes.userMainPage);
            }
            return;
          }
        }
      }

      // Clear auth data if verification fails
      if (Get.currentRoute != Routes.login) {
        await _authService.logout();
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      if (Get.currentRoute != Routes.login) {
        Get.offAllNamed(Routes.login);
      }
    }
  }

  Future<void> _initializeAuthDependentServices() async {
    try {
      // Initialize basic location service first
      final locationService = Get.find<LocationService>();
      await locationService.init();

      // Then initialize user location service which requires auth
      if (!Get.isRegistered<UserLocationService>()) {
        final userLocationService =
            Get.put(UserLocationService(), permanent: true);
        // Load user locations from API
        await userLocationService.loadUserLocations(forceRefresh: true);
      }

      // Sync locations if needed
      final userLocationService = Get.find<UserLocationService>();
      await userLocationService.syncLocations(forceRefresh: true);
    } catch (e) {
      debugPrint('Error initializing auth-dependent services: $e');
    }
  }

  void togglePasswordVisibility() =>
      isPasswordHidden.value = !isPasswordHidden.value;

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  Future<void> toggleRememberMe() async {
    if (!_isInitialized.value) {
      await _initializeController();
    }
    rememberMe.value = !rememberMe.value;
    await _storageService.saveRememberMe(rememberMe.value);
  }

  void setRating(int value) {
    if (value >= 1 && value <= 5) {
      _rating.value = value;
    }
  }

  Future<void> submitRating() async {
    try {
      if (_rating.value > 0) {
        showCustomSnackbar(
          title: 'Sukses',
          message: 'Terima kasih atas penilaian Anda!',
        );
      } else {
        showCustomSnackbar(
          title: 'Error',
          message: 'Silakan berikan rating terlebih dahulu',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal mengirim rating',
        isError: true,
      );
    }
  }

  Future<void> login() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final success = await _authService.login(
        identifierController.text,
        passwordController.text,
        rememberMe: rememberMe.value,
      );

      if (!success) {
        showCustomSnackbar(
          title: 'Login Gagal',
          message: 'Periksa kembali email/nomor telepon dan password Anda.',
          isError: true,
        );
      } else {
        String role = _authService.currentUser.value?.role ?? '';
        if (role != 'USER') {
          showCustomSnackbar(
            title: 'Login Gagal',
            message: 'Aplikasi ini hanya untuk pengguna.',
            isError: true,
          );
          await logout();
          return;
        }

        // Initialize auth-dependent services after successful login
        await _initializeAuthDependentServices();

        // Initialize UserMainController if needed
        if (!Get.isRegistered<UserMainController>()) {
          final userMainController = UserMainController();
          await userMainController.ensureInitialized();
          Get.put(userMainController, permanent: true);
        }

        debugPrint('Navigating to USER main page');
        Get.offAllNamed(Routes.userMainPage);
        showCustomSnackbar(
          title: 'Login Berhasil',
          message: 'Selamat datang kembali!',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register() async {
    String? nameError = validateName(nameController.text);
    String? emailError = validateEmail(emailController.text);
    String? phoneError = validatePhoneNumber(phoneNumberController.text);

    if (nameError != null || emailError != null || phoneError != null) {
      showCustomSnackbar(
        title: 'Validasi Gagal',
        message: nameError ?? emailError ?? phoneError!,
        isError: true,
      );
      return;
    }

    isLoading.value = true;
    try {
      final success = await _authService.register(
          nameController.text,
          emailController.text,
          phoneNumberController.text,
          passwordController.text,
          confirmPasswordController.text);

      if (!success) {
        showCustomSnackbar(
          title: 'Registrasi Gagal',
          message: 'Pendaftaran gagal. Periksa kembali data Anda.',
          isError: true,
        );
      } else {
        showCustomSnackbar(
          title: 'Registrasi Berhasil',
          message: 'Akun Anda telah berhasil dibuat. Silakan login.',
        );
        Get.offAllNamed(Routes.login);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      if (!_isInitialized.value) {
        await _initializeController();
      }

      // Store remember me state and credentials before logout
      final wasRememberMeEnabled = _storageService.getRememberMe();
      final savedCredentials =
          wasRememberMeEnabled ? _storageService.getSavedCredentials() : null;

      await _authService.logout();

      // Clear auth data while preserving remember me if enabled
      if (wasRememberMeEnabled && savedCredentials != null) {
        // Clear auth data but keep remember me settings
        await _storageService.clearAuth();
      } else {
        // Clear everything including remember me settings
        await _storageService.clearAll();
      }

      // Reset controllers
      identifierController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      nameController.clear();
      emailController.clear();
      phoneNumberController.clear();

      // Reset observable values except remember me if enabled
      isLoading.value = false;
      isPasswordHidden.value = true;
      isConfirmPasswordHidden.value = true;
      if (!wasRememberMeEnabled) {
        rememberMe.value = false;
      }

      Get.offAllNamed(Routes.login);
      showCustomSnackbar(
        title: 'Logout Berhasil',
        message: 'Anda telah berhasil keluar dari akun.',
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
      showCustomSnackbar(
        title: 'Logout Gagal',
        message: 'Gagal logout. Silakan coba lagi.',
        isError: true,
      );
    }
  }

  void navigateToHome() {
    Get.offAllNamed(Routes.userMainPage);
  }

  String? validateIdentifier(String? value) {
    return Validators.validateIdentifier(value!);
  }

  String? validatePassword(String? value) {
    return Validators.validatePassword(value);
  }

  String? validateConfirmPassword(String? value) {
    return Validators.validateConfirmPassword(value, passwordController.text);
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    return null;
  }

  String? validateEmail(String? value) {
    return Validators.validateEmail(value);
  }

  String? validatePhoneNumber(String? value) {
    return Validators.validatePhoneNumber(value);
  }

  @override
  void onClose() {
    identifierController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    super.onClose();
  }
}
