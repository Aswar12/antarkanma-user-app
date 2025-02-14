// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/modules/user/views/cart_page.dart';
import 'package:antarkanma/app/modules/user/views/home_page.dart';
import 'package:antarkanma/app/modules/user/views/order_page.dart';
import 'package:antarkanma/app/modules/user/views/profile_page.dart';
import 'package:antarkanma/app/widgets/home_skeleton_loading.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserMainPage extends StatefulWidget {
  const UserMainPage({super.key});

  @override
  State<UserMainPage> createState() => _UserMainPageState();
}

class _UserMainPageState extends State<UserMainPage>
    with AutomaticKeepAliveClientMixin {
  UserMainController? _controller;
  bool _isInitializing = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      debugPrint('UserMainPage: Starting controller initialization');
      setState(() {
        _isInitializing = true;
        _error = null;
      });

      // Get or create the controller
      try {
        _controller = Get.find<UserMainController>();
        debugPrint('UserMainPage: Found existing controller');
      } catch (e) {
        debugPrint('UserMainPage: Error finding controller - $e');
        setState(() => _error = 'Controller not found. Please try again.');
        if (mounted) {
          await Future.delayed(const Duration(seconds: 2));
          Get.offAllNamed('/splash');
        }
        return;
      }

      // Ensure controller is initialized with retry mechanism
      int retryCount = 0;
      const maxRetries = 3;
      
      while (retryCount < maxRetries) {
        try {
          await _controller!.ensureInitialized();
          break; // If successful, exit the retry loop
        } catch (e) {
          retryCount++;
          debugPrint('UserMainPage: Initialization attempt $retryCount failed - $e');
          
          if (retryCount == maxRetries) {
            throw Exception('Failed to initialize after $maxRetries attempts');
          }
          
          // Wait before retrying, with increasing delay
          await Future.delayed(Duration(seconds: retryCount));
        }
      }

      // Set initial page if provided in arguments
      if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
        final args = Get.arguments as Map<String, dynamic>;
        if (args.containsKey('initialPage')) {
          _controller!.changePage(args['initialPage'] as int);
        }
      }

      debugPrint('UserMainPage: Controller initialized successfully');
    } catch (e) {
      debugPrint('UserMainPage: Error initializing - $e');
      setState(() => _error = e.toString());

      if (mounted) {
        Get.snackbar(
          'Error',
          'Failed to initialize: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        await Future.delayed(const Duration(seconds: 2));
        Get.offAllNamed('/splash');
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      body: SafeArea(
        child: HomeSkeletonLoading(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error: ${_error ?? 'Unknown error'}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeController,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    try {
      return const HomePage();
    } catch (e) {
      debugPrint('Error building HomePage: $e');
      return SafeArea(
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text('Error loading Home Page'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Get.offAllNamed('/splash'),
                  child: const Text('Reload App'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  List<Widget> _buildPages() {
    return [
      _buildHomePage(),
      const CartPage(),
      const OrderPage(),
      ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isInitializing || _controller == null) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return GetBuilder<UserMainController>(
      init: _controller,
      builder: (controller) {
        return Obx(() {
          if (!controller.isInitialized.value) {
            return _buildLoadingState();
          }

          Widget body() {
            return IndexedStack(
              index: controller.currentIndex.value,
              children: _buildPages(),
            );
          }

          BottomNavigationBarItem createNavItem(
              String assetPath, String label, int index) {
            return BottomNavigationBarItem(
              icon: Container(
                margin: EdgeInsets.only(top: Dimenssions.height5),
                child: Image.asset(
                  assetPath,
                  width: Dimenssions.height22,
                  color: controller.currentIndex.value == index
                      ? logoColorSecondary
                      : secondaryTextColor,
                ),
              ),
              label: label,
            );
          }

          Widget customBottomNav() {
            return Container(
              decoration: BoxDecoration(
                color: backgroundColor2,
                boxShadow: controller.currentIndex.value == 1
                    ? []
                    : [
                        BoxShadow(
                          color: backgroundColor6.withOpacity(0.15),
                          offset: const Offset(0, -1),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: backgroundColor6.withOpacity(0.3),
                          offset: const Offset(0, -0.5),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ],
              ),
              child: ClipRRect(
                child: BottomNavigationBar(
                  selectedItemColor: logoColorSecondary,
                  unselectedItemColor: secondaryTextColor,
                  currentIndex: controller.currentIndex.value,
                  onTap: (index) => controller.changePage(index),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: backgroundColor2,
                  elevation: 0,
                  items: [
                    createNavItem('assets/icon_home.png', 'Home', 0),
                    createNavItem('assets/icon_cart.png', 'Keranjang', 1),
                    createNavItem('assets/list.png', 'Pesanan', 2),
                    createNavItem('assets/icon_profile.png', 'Profile', 3),
                  ],
                ),
              ),
            );
          }

          return WillPopScope(
            onWillPop: () async {
              if (controller.currentIndex.value != 0) {
                controller.changePage(0);
                return false;
              }
              return true;
            },
            child: Scaffold(
              backgroundColor: backgroundColor3,
              bottomNavigationBar: customBottomNav(),
              body: body(),
            ),
          );
        });
      },
    );
  }
}
