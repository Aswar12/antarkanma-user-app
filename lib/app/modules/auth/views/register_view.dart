import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/widgets/custom_button.dart';
import 'package:antarkanma/app/widgets/custom_input_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';

class RegisterView extends GetView<AuthController> {
  final GlobalKey<FormState> _signUpFormKey = GlobalKey<FormState>();

  RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor1,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(Dimenssions.height20),
            child: Form(
              key: _signUpFormKey,
              child: Column(
                children: [
                  SizedBox(height: Dimenssions.height20),
                  header(),
                  SizedBox(height: Dimenssions.height40),
                  registrationForm(controller),
                  signButton(controller),
                  footer(),
                  SizedBox(height: Dimenssions.height20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget header() {
    return Column(
      children: [
        Image.asset(
          'assets/logo.png',
          height: Dimenssions.height80,
          fit: BoxFit.contain,
        ),
        SizedBox(height: Dimenssions.height30),
        Text(
          'Buat Akun Baru',
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font24,
            fontWeight: semiBold,
          ),
        ),
        SizedBox(height: Dimenssions.height10),
        Text(
          'Silahkan lengkapi data diri Anda',
          style: subtitleTextStyle.copyWith(
            fontSize: Dimenssions.font16,
          ),
        ),
      ],
    );
  }

  Widget registrationForm(AuthController controller) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor2,
        borderRadius: BorderRadius.circular(Dimenssions.radius20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: Dimenssions.width20,
        vertical: Dimenssions.height30,
      ),
      child: Column(
        children: [
          _buildInputField(
            label: 'Nama Lengkap',
            hintText: 'Masukkan Nama Lengkap Kamu',
            controller: controller.nameController,
            validator: controller.validateName,
            icon: 'assets/icon_name.png',
          ),
          SizedBox(height: Dimenssions.height20),
          _buildInputField(
            label: 'Alamat Email',
            hintText: 'Masukkan Alamat Email Kamu',
            controller: controller.emailController,
            validator: controller.validateEmail,
            icon: 'assets/icon_email.png',
          ),
          SizedBox(height: Dimenssions.height20),
          _buildInputField(
            label: 'Telepon/WA',
            hintText: 'Masukkan Nomor Telepon/WA Kamu',
            controller: controller.phoneNumberController,
            validator: controller.validatePhoneNumber,
            icon: 'assets/phone_icon.png',
          ),
          SizedBox(height: Dimenssions.height20),
          _buildInputField(
            label: 'Password',
            hintText: 'Masukkan Password Kamu',
            controller: controller.passwordController,
            validator: controller.validatePassword,
            icon: 'assets/icon_password.png',
            initialObscureText: true,
            showVisibilityToggle: true,
          ),
          SizedBox(height: Dimenssions.height20),
          _buildInputField(
            label: 'Konfirmasi Password',
            hintText: 'Masukkan Konfirmasi Password Kamu',
            controller: controller.confirmPasswordController,
            validator: controller.validateConfirmPassword,
            icon: 'assets/icon_password.png',
            initialObscureText: true,
            showVisibilityToggle: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hintText,
    required TextEditingController controller,
    required String? Function(String?)? validator,
    required String icon,
    bool initialObscureText = false,
    bool showVisibilityToggle = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: BorderRadius.circular(Dimenssions.radius12),
      ),
      child: CustomInputField(
        label: label,
        hintText: hintText,
        controller: controller,
        validator: validator,
        icon: icon,
        initialObscureText: initialObscureText,
        showVisibilityToggle: showVisibilityToggle,
      ),
    );
  }

  Widget signButton(AuthController controller) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: Dimenssions.height30,
      ),
      child: Obx(
        () => CustomButton(
          text: 'Daftar Sekarang',
          isLoading: controller.isLoading.value,
          backgroundColor: logoColorSecondary,
          onPressed: () {
            if (_signUpFormKey.currentState!.validate()) {
              controller.register();
            }
          },
        ),
      ),
    );
  }

  Widget footer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sudah Punya Akun? ',
          style: subtitleTextStyle.copyWith(
            fontSize: Dimenssions.font14,
          ),
        ),
        GestureDetector(
          onTap: () => Get.toNamed('/login'),
          child: Text(
            'Masuk',
            style: primaryTextOrange.copyWith(
              fontSize: Dimenssions.font14,
              fontWeight: semiBold,
            ),
          ),
        ),
      ],
    );
  }
}
