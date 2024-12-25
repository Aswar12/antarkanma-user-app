// ignore_for_file: deprecated_member_use

import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/courier_controller.dart';
import 'courier_home_page.dart';
import 'courier_delivery_page.dart';
import 'courier_profile_page.dart';
import 'courier_available_orders_page.dart';

class CourierMainPage extends GetView<CourierController> {
  const CourierMainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    final CourierController controller = Get.find();

    final List<Widget> pages = [
      const CourierHomePage(),
      const CourierAvailableOrdersPage(),
      const CourierDeliveryPage(),
      const CourierProfilePage(),
    ];

    Widget body() {
      return GetX<CourierController>(
        builder: (_) {
          return IndexedStack(
            index: controller.currentTabIndex.value,
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
          child: GetX<CourierController>(
            builder: (_) => Image.asset(
              assetPath,
              width: Dimenssions.height22,
              color: controller.currentTabIndex.value == index
                  ? logoColorSecondary
                  : secondaryTextColor,
            ),
          ),
        ),
        label: label,
      );
    }

    Widget customBottomNav() {
      return GetX<CourierController>(
        builder: (_) => Container(
          decoration: BoxDecoration(
            color: backgroundColor2,
            boxShadow: [
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
              currentIndex: controller.currentTabIndex.value,
              onTap: (index) => controller.changePage(index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: backgroundColor2,
              elevation: 0,
              items: [
                createNavItem('assets/icon_home.png', 'Beranda', 0),
                createNavItem('assets/list.png', 'Orderan', 1),
                createNavItem('assets/motorbike.png', 'Pengantaran', 2),
                createNavItem('assets/icon_profile.png', 'Profil', 3),
              ],
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (controller.currentTabIndex.value != 0) {
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
