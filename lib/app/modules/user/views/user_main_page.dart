// ignore_for_file: deprecated_member_use

import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/modules/user/views/cart_page.dart';
import 'package:antarkanma/app/modules/user/views/home_page.dart';
import 'package:antarkanma/app/modules/user/views/order_page.dart';
import 'package:antarkanma/app/modules/user/views/profile_page.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/homepage_controller.dart';

class UserMainPage extends GetView<UserMainController> {
  const UserMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Pastikan controller sudah diinisialisasi
    final UserMainController controller = Get.find();

    // Ensure HomePageController is initialized
    if (!Get.isRegistered<HomePageController>()) {
      Get.put(HomePageController(), permanent: true);
    }

    // Set initial page if provided in arguments
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      final args = Get.arguments as Map<String, dynamic>;
      if (args.containsKey('initialPage')) {
        controller.changePage(args['initialPage'] as int);
      }
    }

    final List<Widget> pages = [
      const HomePage(),
      const CartPage(),
      const OrderPage(),
      ProfilePage(),
    ];

    Widget body() {
      return GetX<UserMainController>(
        builder: (_) {
          return IndexedStack(
            index: controller.currentIndex.value,
            children: pages,
          );
        },
      );
    }

    BottomNavigationBarItem createNavItem(
        String assetPath, String label, int index) {
      return BottomNavigationBarItem(
        icon: Container(
          margin: EdgeInsets.only(top: Dimenssions.height5),
          child: GetX<UserMainController>(
            builder: (_) => Image.asset(
              assetPath,
              width: Dimenssions.height22,
              color: controller.currentIndex.value == index
                  ? logoColorSecondary
                  : secondaryTextColor,
            ),
          ),
        ),
        label: label,
      );
    }

    Widget customBottomNav() {
      return GetX<UserMainController>(
        builder: (_) => Container(
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
  }
}
