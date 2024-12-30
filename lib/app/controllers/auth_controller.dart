// ignore_for_file: avoid_print

import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:antarkanma/app/modules/merchant/controllers/merchant_controller.dart'; // Importing MerchantController
import 'package:antarkanma/app/utils/validators.dart';

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
  final StorageService _storageService = StorageService.instance;

  @override
  void onInit() {
    super.onInit();
    rememberMe.value = _storageService.getRememberMe();
  }

  void togglePasswordVisibility() =>
      isPasswordHidden.value = !isPasswordHidden.value;

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  void toggleRememberMe() {
    rememberMe.value = !rememberMe.value;
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
        String role = _authService.userRole;
        switch (role) {
          case 'USER':
            print('Navigating to USER main page');
            Get.offAllNamed(Routes.userMainPage);
            break;
          case 'MERCHANT':
            Get.offAllNamed(Routes.merchantMainPage);
            break;
          case 'COURIER':
            Get.offAllNamed(Routes.courierMainPage);
            break;
          default:
            Get.offAllNamed(Routes.login);
        }
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
      await _authService.logout();
      await _storageService.clearAll();

      // Reset controllers
      identifierController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      nameController.clear();
      emailController.clear();
      phoneNumberController.clear();

      // Reset observable values
      rememberMe.value = false;
      isLoading.value = false;
      isPasswordHidden.value = true;
      isConfirmPasswordHidden.value = true;

      Get.offAllNamed(Routes.login);
      showCustomSnackbar(
        title: 'Logout Berhasil',
        message: 'Anda telah berhasil keluar dari akun.',
      );
    } catch (e) {
      print('Error during logout: $e');
      showCustomSnackbar(
        title: 'Logout Gagal',
        message: 'Gagal logout. Silakan coba lagi.',
        isError: true,
      );
    }
  }

  void navigateToHome(String role) {
    switch (role) {
      case 'USER':
        Get.offAllNamed(Routes.userHome);
        break;
      case 'MERCHANT':
        Get.offAllNamed(Routes.merchantMainPage);
        break;
      case 'COURIER':
        Get.offAllNamed(Routes.courierMainPage);
        break;
      default:
        Get.offAllNamed(Routes.login);
    }
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

  final RxInt _rating = 0.obs;
  int get rating => _rating.value;

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
      print('Error submitting rating: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal mengirim rating',
        isError: true,
      );
    }
  }
}
