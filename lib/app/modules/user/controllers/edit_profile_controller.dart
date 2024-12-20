import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';

class EditProfileController extends GetxController {
  final AuthService authService = Get.find<AuthService>();
  final ImagePicker _picker = ImagePicker();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize text controllers with current user data
    final user = authService.getUser();
    if (user != null) {
      nameController.text = user.name;
      emailController.text = user.email ?? '';
      phoneController.text = user.phoneNumber ?? '';
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        await authService.updateProfilePhoto(selectedImage.value!);
      }
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal memilih gambar: ${e.toString()}',
        isError: true,
      );
    }
  }

  Future<void> updateProfile() async {
    if (!_validateInputs()) return;

    isLoading.value = true;
    try {
      final success = await authService.updateProfile(
        name: nameController.text,
        email: emailController.text,
        phoneNumber: phoneController.text,
      );

      if (success) {
        showCustomSnackbar(
          title: 'Sukses',
          message: 'Profil berhasil diperbarui',
        );
        Get.back(); // Return to previous screen
      }
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateInputs() {
    if (nameController.text.isEmpty) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Nama tidak boleh kosong',
        isError: true,
      );
      return false;
    }

    if (emailController.text.isNotEmpty && !emailController.text.isEmail) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Format email tidak valid',
        isError: true,
      );
      return false;
    }

    if (phoneController.text.isNotEmpty &&
        !phoneController.text.isPhoneNumber) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Format nomor telepon tidak valid',
        isError: true,
      );
      return false;
    }

    return true;
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
