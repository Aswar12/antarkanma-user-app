import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/product_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize services
      final authService = Get.find<AuthService>();
      final productService = Get.find<ProductService>();

      // Load data in parallel
      await Future.wait([
        // Check auth status
        authService.checkLoginStatus(),

        // Load products (will check local storage first)
        productService.fetchProducts(),

        // Minimum splash duration
        Future.delayed(const Duration(seconds: 3)),
      ]);

      // Navigate based on auth status
      if (!authService.isLoggedIn.value) {
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      // Show error message
      Get.snackbar(
        'Error',
        'Failed to initialize app. Please check your connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      // Navigate to login after error
      await Future.delayed(const Duration(seconds: 2));
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
