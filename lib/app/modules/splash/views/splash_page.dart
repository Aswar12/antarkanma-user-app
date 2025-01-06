import 'dart:math';
import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/services/transaction_service.dart';

class NeonSpinner extends CustomPainter {
  final double angle;
  final Color color;

  NeonSpinner(this.angle, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    paint.maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(rect, angle, 2 * pi / 3, false, paint);
    paint.maskFilter = const MaskFilter.blur(BlurStyle.inner, 4);
    canvas.drawArc(rect, angle + pi / 6, 2 * pi / 3, false, paint);
  }

  @override
  bool shouldRepaint(NeonSpinner oldDelegate) => angle != oldDelegate.angle;
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _spinnerAnimation;
  final RxString _loadingText = 'Mempersiapkan aplikasi...'.obs;
  final RxBool _isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 60.0,
      ),
    ]).animate(_controller);

    _fadeAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _spinnerAnimation = Tween<double>(
      begin: 0,
      end: 2 * pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _controller.repeat();
  }

  Future<void> _initializeApp() async {
    try {
      final authService = Get.find<AuthService>();

      await Future.delayed(const Duration(seconds: 1));

      _loadingText.value = 'Memeriksa status login...';
      if (!authService.isLoggedIn.value) {
        await Future.delayed(const Duration(seconds: 3));
        Get.offAllNamed(Routes.login);
        return;
      }

      await _loadRoleSpecificData(authService);

      _isLoading.value = false;
      await Future.delayed(const Duration(seconds: 1));
      _navigateBasedOnRole(authService);
    } catch (e) {
      debugPrint('Error during initialization: $e');
      Get.snackbar(
        'Error',
        'Failed to initialize app. Please check your connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      await Future.delayed(const Duration(seconds: 3));
      Get.offAllNamed(Routes.login);
    }
  }

  Future<void> _loadRoleSpecificData(AuthService authService) async {
    if (authService.isUser) {
      _loadingText.value = 'Memuat data kategori...';
      final categoryService = Get.find<CategoryService>();
      await categoryService.getCategories();

      _loadingText.value = 'Memuat data produk populer...';
      // Initialize HomePageController if not already initialized
      if (!Get.isRegistered<HomePageController>()) {
        final homeController = HomePageController();
        Get.put(homeController, permanent: true);
      }
      final homeController = Get.find<HomePageController>();
      
      // Load popular products
      await homeController.loadPopularProducts();
      
      // Verify popular products were loaded
      if (homeController.popularProducts.isEmpty) {
        print('Warning: No popular products loaded');
        _loadingText.value = 'Mencoba memuat ulang data produk...';
        await homeController.refreshProducts(showMessage: false);
      }
      
      print('Loaded ${homeController.popularProducts.length} popular products');
    } 
    else if (authService.isMerchant) {
      _loadingText.value = 'Memuat data merchant...';
      final merchantService = Get.find<MerchantService>();
      final transactionService = Get.find<TransactionService>();

      await Future.wait([
        merchantService.getMerchant(),
        merchantService.getMerchantProducts(),
        transactionService.getTransactions(),
      ]);
    }
    else if (authService.isCourier) {
      _loadingText.value = 'Memuat data pengiriman...';
      final transactionService = Get.find<TransactionService>();
      
      await transactionService.getTransactions(
        status: 'pending,in_progress',
        pageSize: 10,
      );
    }
  }

  void _navigateBasedOnRole(AuthService authService) {
    if (authService.isUser) {
      Get.offAllNamed(Routes.userMainPage);
    } else if (authService.isMerchant) {
      Get.offAllNamed(Routes.merchantMainPage);
    } else if (authService.isCourier) {
      Get.offAllNamed(Routes.courierMainPage);
    } else {
      authService.logout();
      Get.offAllNamed(Routes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _spinnerAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(
                        painter: NeonSpinner(
                          _spinnerAnimation.value,
                          logoColorSecondary.withOpacity(0.8),
                        ),
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/Logo_AntarkanmaNoBg.png'),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
            Obx(() => _isLoading.value
                ? Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: logoColorSecondary.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Obx(() => Text(
                              _loadingText.value,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    color: logoColorSecondary,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            )),
                      ),
                    ],
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
