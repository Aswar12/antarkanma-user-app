import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/widgets/custom_input_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';

class SignUpPage extends StatelessWidget {
  final GlobalKey<FormState> _signUpFormKey = GlobalKey<FormState>();

  SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.put(AuthController());

    Widget header() {
      return Container(
        margin: EdgeInsets.only(
            top: Dimenssions.height10, left: Dimenssions.height10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Akun',
              style:
                  primaryTextStyle.copyWith(fontSize: 24, fontWeight: semiBold),
            ),
            const SizedBox(height: 2),
            Text('Masukkan Data Anda', style: subtitleTextStyle),
          ],
        ),
      );
    }

    Widget nameInput() {
      return CustomInputField(
        label: 'Nama Lengkap',
        hintText: 'Masukkan Nama Lengkap Kamu',
        controller: controller.nameController,
        validator: controller.validateName,
        icon: 'assets/icon_name.png',
      );
    }

    Widget emailInput() {
      return CustomInputField(
        label: 'Alamat Email',
        hintText: 'Masukkan Alamat Email Kamu',
        controller: controller.emailController,
        validator: controller.validateEmail,
        icon: 'assets/icon_email.png',
      );
    }

    Widget phoneInput() {
      return CustomInputField(
        label: 'Telepon/Wa',
        hintText: 'Masukkan Nomor Telepon/Wa Kamu',
        controller: controller.phoneNumberController,
        validator: controller.validatePhoneNumber,
        icon: 'assets/phone_icon.png',
      );
    }

    Widget passwordInput() {
      return CustomInputField(
        label: 'Password',
        hintText: 'Masukkan Password Kamu',
        controller: controller.passwordController,
        validator: controller.validatePassword,
        initialObscureText: true,
        icon: 'assets/icon_password.png',
        showVisibilityToggle: true,
      );
    }

    Widget confirmPasswordInput() {
      return CustomInputField(
        label: 'Konfirmasi Password',
        hintText: 'Masukkan Konfirmasi Password Kamu',
        controller: controller.confirmPasswordController,
        validator: controller.validateConfirmPassword,
        initialObscureText: true,
        icon: 'assets/icon_password.png',
        showVisibilityToggle: true,
      );
    }

    Widget signButton() {
      return Container(
        height: Dimenssions.height50,
        width: double.infinity,
        margin: EdgeInsets.symmetric(
          vertical: Dimenssions.height30,
          horizontal: Dimenssions.height10,
        ),
        child: TextButton(
          onPressed: () {
            if (_signUpFormKey.currentState!.validate()) {
              controller.register(); // Panggil fungsi register
            }
          },
          style: TextButton.styleFrom(
            backgroundColor: logoColorSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Dimenssions.radius15),
            ),
          ),
          child: Text(
            'Daftar',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font16,
              fontWeight: medium,
            ),
          ),
        ),
      );
    }

    Widget footer() {
      return Container(
        margin: EdgeInsets.only(
          bottom: Dimenssions.height30,
          top: Dimenssions.height10,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sudah Punya Akun? ',
              style: subtitleTextStyle.copyWith(
                fontSize: Dimenssions.font14,
              ),
            ),
            GestureDetector(
              onTap: () {
                Get.toNamed('/login');
              },
              child: Text(
                'Masuk',
                style: primaryTextOrange.copyWith(
                  fontSize: Dimenssions.font14,
                  fontWeight: medium,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor3,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(Dimenssions.height20),
          child: Form(
            key: _signUpFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(),
                SizedBox(height: Dimenssions.height20),
                nameInput(),
                SizedBox(height: Dimenssions.height15),
                emailInput(),
                SizedBox(height: Dimenssions.height15),
                phoneInput(),
                SizedBox(height: Dimenssions.height15),
                passwordInput(),
                SizedBox(height: Dimenssions.height15),
                confirmPasswordInput(),
                signButton(),
                footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
