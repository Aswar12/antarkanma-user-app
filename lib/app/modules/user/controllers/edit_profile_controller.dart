import 'dart:io';
import 'dart:async';
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

  Future<void> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      // Pick the image
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile == null) {
        return; // User cancelled image picker
      }

      // Verify file exists and is readable
      final file = File(pickedFile.path);
      if (!await file.exists()) {
        showCustomSnackbar(
          title: 'Error',
          message: 'File tidak ditemukan, coba lagi nanti',
          isError: true,
        );
        return;
      }

      selectedImage.value = file;
    } catch (e) {
      print('Error picking image: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal memilih foto, coba lagi nanti',
        isError: true,
      );
    }
  }

  Future<void> uploadSelectedImage() async {
    if (selectedImage.value == null) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Pilih foto terlebih dahulu',
        isError: true,
      );
      return;
    }

    isLoading.value = true;
    try {
      final success =
          await authService.updateProfilePhoto(selectedImage.value!);
      if (success) {
        // Fetch fresh user data and ensure it's loaded
        final updatedUser = await authService.getProfile();
        if (updatedUser != null) {
          // Clear the cached image
          imageCache.clear();
          imageCache.clearLiveImages();

          showCustomSnackbar(
            title: 'Sukses',
            message: 'Foto profil berhasil diperbarui',
          );

          // Reset selected image after successful upload
          selectedImage.value = null;
        }
      }
    } catch (e) {
      print('Error uploading image: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal mengupload foto, coba lagi nanti',
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void showImageSourceDialog() {
    showDialog(
      context: Get.context!,
      builder: (context) => SimpleDialog(
        title: Text('Pilih Sumber Gambar'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              pickImage(source: ImageSource.camera);
            },
            child: Row(
              children: [
                Icon(Icons.camera_alt),
                SizedBox(width: 10),
                Text('Kamera'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              pickImage(source: ImageSource.gallery);
            },
            child: Row(
              children: [
                Icon(Icons.photo_library),
                SizedBox(width: 10),
                Text('Galeri'),
              ],
            ),
          ),
        ],
      ),
    );
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
        // Fetch fresh user data and ensure it's loaded
        final updatedUser = await authService.getProfile();
        if (updatedUser != null) {
          // Clear the cached image in case profile photo URL changed
          imageCache.clear();
          imageCache.clearLiveImages();

          showCustomSnackbar(
            title: 'Sukses',
            message: 'Profil berhasil diperbarui',
          );

          // Return to main page
          Get.offAllNamed('/usermain');
        }
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
