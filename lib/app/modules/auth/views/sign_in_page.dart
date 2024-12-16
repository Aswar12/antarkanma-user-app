import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/auth_controller.dart';
import '../../../constants/app_values.dart';
import '../../../widgets/custom_input_field.dart';

class SignInPage extends GetView<AuthController> {
  final GlobalKey<FormState> _signInFormKey = GlobalKey<FormState>();

  SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor3,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: EdgeInsets.all(Dimenssions.height15),
        child: SafeArea(
          child: Form(
            key: _signInFormKey,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: defaultMargin),
              child: Column(
                children: [
                  header(),
                  emailInput(),
                  SizedBox(height: Dimenssions.height15),
                  passwordInput(),
                  rememberMeCheckbox(),
                  signButton(),
                  const Spacer(),
                  footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget rememberMeCheckbox() {
    return Obx(
      () => Container(
        margin: EdgeInsets.symmetric(
          horizontal: Dimenssions.width10,
        ),
        child: CheckboxListTile(
          title: Text(
            'Ingat Saya',
            style: primaryTextStyle.copyWith(
              fontSize: 14,
              fontWeight: medium,
            ),
          ),
          value: controller.rememberMe.value,
          onChanged: (value) => controller.toggleRememberMe(),
          controlAffinity: ListTileControlAffinity.trailing, // Ubah ke trailing
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeColor: logoColorSecondary,
          checkColor: Colors.white,
        ),
      ),
    );
  }

  Widget header() {
    return Container(
      margin: const EdgeInsets.only(
          top: AppValues.height10, left: AppValues.height10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text(
              'Login',
              style:
                  primaryTextStyle.copyWith(fontSize: 24, fontWeight: semiBold),
            ),
          ),
          const SizedBox(height: 2),
          const Text('Masuk Untuk lanjut'),
        ],
      ),
    );
  }

  // Di dalam class SignInPage

  Widget emailInput() {
    return CustomInputField(
      label: 'Email atau WhatsApp',
      hintText: 'Masukkan Email atau Nomor WA',
      controller: controller.identifierController,
      validator: controller.validateIdentifier,
      icon: 'assets/icon_email.png',
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

  Widget signButton() {
    return Container(
      height: AppValues.height50,
      width: double.infinity,
      margin: EdgeInsets.only(
        top: Dimenssions.height10,
        left: AppValues.height10,
        right: AppValues.height10,
      ),
      child: Obx(
        () => TextButton(
          onPressed: controller.isLoading.value
              ? null
              : () {
                  if (_signInFormKey.currentState!.validate()) {
                    controller.login();
                  }
                },
          style: TextButton.styleFrom(
            backgroundColor: logoColorSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppValues.radius15),
            ),
          ),
          child: controller.isLoading.value
              ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              : Text(
                  'Login',
                  style: primaryTextStyle.copyWith(
                    fontSize: AppValues.font16,
                    fontWeight: medium,
                  ),
                ),
        ),
      ),
    );
  }

  Widget footer() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppValues.height30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Belum Punya Akun? ',
            style: subtitleTextStyle.copyWith(
              fontSize: AppValues.font14,
            ),
          ),
          GestureDetector(
            onTap: () => Get.toNamed('/register'),
            child: Text(
              'Daftar',
              style: primaryTextOrange.copyWith(
                fontSize: AppValues.font14,
                fontWeight: medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
