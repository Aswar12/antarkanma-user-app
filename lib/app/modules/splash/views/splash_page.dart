import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkUserAndNavigate();
  }

  void _checkUserAndNavigate() async {
    // Simulasi delay loading
    await Future.delayed(const Duration(seconds: 3));

    final authService = Get.find<AuthService>();

    // Check login status using AuthService
    await authService.checkLoginStatus();

    // AuthService will automatically redirect based on role if logged in
    if (!authService.isLoggedIn.value) {
      Get.offAllNamed(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: logoColor,
      body: Center(
        child: Container(
          width: 200,
          height: 200,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/Logo_AntarkanmaNoBg.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
