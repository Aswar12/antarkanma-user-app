import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

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

    // Periksa status login
    final box = GetStorage();
    bool isLoggedIn = box.read('isLoggedIn') ?? false;

    // Navigasi berdasarkan status login
    if (isLoggedIn) {
      Get.offAllNamed(Routes.main);
    } else {
      Get.offAllNamed(Routes.login); // Pastikan Anda memiliki Routes.login
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
