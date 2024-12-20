import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/modules/user/controllers/edit_profile_controller.dart';
import 'package:antarkanma/theme.dart';

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
              SizedBox(height: Dimenssions.height30),
              _buildForm(),
            ],
          )),
    );
  }

  Widget _buildProfileImage() {
    final selectedImage = controller.selectedImage.value;
    final user = controller.authService.getUser();

    return Center(
      child: Stack(
        children: [
          if (selectedImage != null)
            CircleAvatar(
              radius: Dimenssions.height60,
              backgroundImage: FileImage(selectedImage),
            )
          else if (user?.profilePhotoUrl != null)
            CircleAvatar(
              radius: Dimenssions.height60,
              backgroundImage: NetworkImage(user!.profilePhotoUrl!),
            )
          else
            CircleAvatar(
              radius: Dimenssions.height60,
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.person,
                size: Dimenssions.height60,
                color: Colors.grey[600],
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: () => controller.pickImage(),
              child: Container(
                padding: EdgeInsets.all(Dimenssions.height8),
                decoration: BoxDecoration(
                  color: logoColorSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: backgroundColor1,
                  size: Dimenssions.height20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nama Lengkap',
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font16,
            fontWeight: medium,
          ),
        ),
        SizedBox(height: Dimenssions.height10),
        TextFormField(
          controller: controller.nameController,
          style: primaryTextStyle,
          decoration: InputDecoration(
            hintText: 'Masukkan nama lengkap',
            hintStyle: subtitleTextStyle,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimenssions.radius15),
              borderSide: BorderSide(color: subtitleColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimenssions.radius15),
              borderSide: BorderSide(color: logoColorSecondary),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: Dimenssions.width15,
              vertical: Dimenssions.height15,
            ),
          ),
        ),
        SizedBox(height: Dimenssions.height20),
        Text(
          'Email',
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font16,
            fontWeight: medium,
          ),
        ),
        SizedBox(height: Dimenssions.height10),
        TextFormField(
          controller: controller.emailController,
          style: primaryTextStyle,
          decoration: InputDecoration(
            hintText: 'Masukkan email',
            hintStyle: subtitleTextStyle,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimenssions.radius15),
              borderSide: BorderSide(color: subtitleColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimenssions.radius15),
              borderSide: BorderSide(color: logoColorSecondary),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: Dimenssions.width15,
              vertical: Dimenssions.height15,
            ),
          ),
        ),
        SizedBox(height: Dimenssions.height20),
        Text(
          'Nomor Telepon',
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font16,
            fontWeight: medium,
          ),
        ),
        SizedBox(height: Dimenssions.height10),
        TextFormField(
          controller: controller.phoneController,
          style: primaryTextStyle,
          decoration: InputDecoration(
            hintText: 'Masukkan nomor telepon',
            hintStyle: subtitleTextStyle,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimenssions.radius15),
              borderSide: BorderSide(color: subtitleColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimenssions.radius15),
              borderSide: BorderSide(color: logoColorSecondary),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: Dimenssions.width15,
              vertical: Dimenssions.height15,
            ),
          ),
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
