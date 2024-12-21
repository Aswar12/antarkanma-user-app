import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/modules/user/controllers/edit_profile_controller.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/widgets/custom_input_field.dart';
import 'package:antarkanma/app/widgets/profile_image.dart';

class EditProfileView extends GetView<EditProfileController> {
  const EditProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor3,
      appBar: AppBar(
        backgroundColor: backgroundColor2,
        title: Text(
          'Edit Profil',
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font20,
            fontWeight: semiBold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: primaryTextColor,
            size: Dimenssions.height20,
          ),
          onPressed: () => Get.back(),
        ),
        elevation: 0,
      ),
      body: Obx(() => ListView(
            padding: EdgeInsets.all(Dimenssions.height15),
            children: [
              _buildProfileImage(),
              SizedBox(height: Dimenssions.height20),
              _buildUploadPhotoButton(),
              SizedBox(height: Dimenssions.height30),
              _buildForm(),
            ],
          )),
    );
  }

  Widget _buildProfileImage() {
    final user = controller.authService.getUser();

    return Obx(() {
      return Center(
        child: Stack(
          children: [
            Hero(
              tag: 'profile_image',
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: controller.selectedImage.value != null
                    ? ClipOval(
                        child: Image.file(
                          controller.selectedImage.value!,
                          width: Dimenssions.height100,
                          height: Dimenssions.height100,
                          fit: BoxFit.cover,
                        ),
                      )
                    : user != null
                        ? ProfileImage(
                            user: user,
                            size: Dimenssions.height100,
                            primaryColor: logoColorSecondary,
                          )
                        : CircleAvatar(
                            radius: Dimenssions.height50,
                            backgroundColor: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              size: Dimenssions.height50,
                              color: Colors.grey[600],
                            ),
                          ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(Dimenssions.height5),
                decoration: BoxDecoration(
                  color: logoColorSecondary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  size: Dimenssions.height15,
                  color: backgroundColor1,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildUploadPhotoButton() {
    return Obx(() {
      if (controller.selectedImage.value == null) {
        // Show pick photo button when no image is selected
        return Center(
          child: TextButton(
            onPressed: () => controller.showImageSourceDialog(),
            style: TextButton.styleFrom(
              backgroundColor: logoColorSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimenssions.radius15),
              ),
            ),
            child: Text(
              'Pilih Foto',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font16,
                fontWeight: medium,
                color: backgroundColor1,
              ),
            ),
          ),
        );
      } else {
        // Show confirmation buttons when image is selected
        return Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => controller.selectedImage.value = null,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimenssions.radius15),
                  ),
                ),
                child: Text(
                  'Batal',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font16,
                    fontWeight: medium,
                    color: backgroundColor1,
                  ),
                ),
              ),
              SizedBox(width: Dimenssions.width20),
              TextButton(
                onPressed: () => controller.uploadSelectedImage(),
                style: TextButton.styleFrom(
                  backgroundColor: logoColorSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimenssions.radius15),
                  ),
                ),
                child: Text(
                  'Simpan Foto',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font16,
                    fontWeight: medium,
                    color: backgroundColor1,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomInputField(
          label: 'Nama Lengkap',
          hintText: 'Masukkan nama lengkap',
          controller: controller.nameController,
          validator: (value) =>
              value!.isEmpty ? 'Nama tidak boleh kosong' : null,
          icon: 'assets/icon_name.png',
        ),
        SizedBox(height: Dimenssions.height20),
        CustomInputField(
          label: 'Email',
          hintText: 'Masukkan email',
          controller: controller.emailController,
          validator: (value) =>
              value!.isEmpty ? 'Email tidak boleh kosong' : null,
          icon: 'assets/icon_email.png',
        ),
        SizedBox(height: Dimenssions.height20),
        CustomInputField(
          label: 'Nomor Telepon',
          hintText: 'Masukkan nomor telepon',
          controller: controller.phoneController,
          validator: (value) =>
              value!.isEmpty ? 'Nomor telepon tidak boleh kosong' : null,
          icon: 'assets/phone_icon.png',
        ),
        SizedBox(height: Dimenssions.height30),
        Container(
          height: Dimenssions.height45,
          width: double.infinity,
          child: TextButton(
            onPressed: () => controller.updateProfile(),
            style: TextButton.styleFrom(
              backgroundColor: logoColorSecondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimenssions.radius15),
              ),
            ),
            child: Text(
              'Simpan',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font16,
                fontWeight: medium,
                color: backgroundColor1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
