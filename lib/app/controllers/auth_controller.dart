// ignore_for_file: avoid_print

import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:antarkanma/app/utils/validators.dart'; // Import validators

class AuthController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  var isConfirmPasswordHidden = true.obs;
  final formKey = GlobalKey<FormState>();
  final identifierController =
      TextEditingController(); // Untuk login (email/nomor telepon)
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController(); // Kontroler untuk nama
  final emailController = TextEditingController(); // Kontroler untuk email
  final phoneNumberController =
      TextEditingController(); // Kontroler untuk nomor telepon
  final RxBool isLoading = false.obs;
  final RxBool isPasswordHidden = true.obs;
  final rememberMe = false.obs;
  final StorageService _storageService = StorageService.instance;
  @override
  void onInit() {
    super.onInit();
    rememberMe.value = _storageService.getRememberMe();
    print('Initial Remember Me Value: ${rememberMe.value}'); // Debug print
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
      await _storageService
          .clearAuth(); // Menggunakan clearAuth() alih-alih removeUser()
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
    if (role == 'USER ') {
      Get.offAllNamed(
          Routes.home); // Pastikan Routes.home mengarah ke UserMainPage
    } else if (role == 'MERCHANT') {
      Get.offAllNamed(Routes
          .merchantHome); // Pastikan Routes.merchantHome mengarah ke MerchantMainPage
    } else if (role == 'COURIER') {
      Get.offAllNamed(Routes
          .courierHome); // Pastikan Routes.courierHome mengarah ke CourierMainPage
    }
  }

  String? validateIdentifier(String? value) {
    return Validators.validateIdentifier(value!); // Menggunakan validator
  }

  String? validatePassword(String? value) {
    return Validators.validatePassword(value); // Menggunakan validator
  }

  String? validateConfirmPassword(String? value) {
    return Validators.validateConfirmPassword(
        value, passwordController.text); // Menggunakan validator
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    return null;
  }

  String? validateEmail(String? value) {
    return Validators.validateEmail(
        value); // Pastikan ada validator untuk email
  }

  String? validatePhoneNumber(String? value) {
    return Validators.validatePhoneNumber(value); // Menggunakan validator
  }

  @override
  void onClose() {
    identifierController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose(); // Dispose kontroler nama
    emailController.dispose(); // Dispose kontroler email
    super.onClose();
  }

  Future<void> updateProfileImage() async {
    // Implementasi untuk memilih dan mengupdate foto profil
    try {
      // Tambahkan logika untuk memilih gambar
      // Contoh menggunakan image_picker
      // final ImagePicker _picker = ImagePicker();
      // final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      // if (image != null) {
      //   // Upload image dan update profile
      // }
    } catch (e) {
      print('Error updating profile image: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal mengupdate foto profil',
        isError: true,
      );
    }
  }

  // Untuk menangani rating
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
        // Implementasi untuk mengirim rating ke backend
        // await _authService.submitRating(_rating.value);
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
