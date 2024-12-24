import 'package:antarkanma/app/modules/merchant/controllers/merchant_controller.dart';
import 'package:antarkanma/app/modules/merchant/views/merchant_home_page.dart';
import 'package:antarkanma/app/modules/merchant/views/merchant_order_page.dart';
import 'package:antarkanma/app/modules/merchant/views/merchant_profile_page.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MerchantMainPage extends GetView<MerchantController> {
  const MerchantMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final MerchantController controller = Get.find();

    final List<Widget> pages = [
      const MerchantHomePage(),
      const MerchantOrderPage(),
      MerchantProfilePage(),
    ];

    Widget body() {
      return GetX<MerchantController>(
        builder: (_) {
          return IndexedStack(
            index: controller.currentIndex.value,
            children: pages,
          );
        },
      );
    }

    BottomNavigationBarItem createNavItem(
        IconData icon, String label, int index) {
      return BottomNavigationBarItem(
        icon: Container(
          margin: EdgeInsets.only(top: Dimenssions.height5),
          child: GetX<MerchantController>(
            builder: (_) => Icon(
              icon,
              size: Dimenssions.height22,
              color: controller.currentIndex.value == index
                  ? logoColor
                  : Colors.grey,
            ),
          ),
        ),
        label: label,
      );
    }

    Widget customBottomNav() {
      return GetX<MerchantController>(
        builder: (_) => Container(
          decoration: BoxDecoration(
            color: backgroundColor1,
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
              selectedItemColor: logoColor,
              unselectedItemColor: Colors.grey,
              currentIndex: controller.currentIndex.value,
              onTap: (index) => controller.changePage(index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: backgroundColor1,
              elevation: 0,
              items: [
                createNavItem(Icons.home, 'Home', 0),
                createNavItem(Icons.list, 'Orders', 1), // Updated here
                createNavItem(Icons.person, 'Profile', 2),
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
