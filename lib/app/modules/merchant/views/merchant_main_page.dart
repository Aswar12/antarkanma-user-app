import 'package:antarkanma/app/modules/merchant/controllers/merchant_controller.dart';
import 'package:antarkanma/app/modules/merchant/views/merchant_home_page.dart';
import 'package:antarkanma/app/modules/merchant/views/merchant_profile_page.dart';
import 'package:antarkanma/app/modules/merchant/views/order_management_page.dart';
import 'package:antarkanma/app/modules/merchant/views/product_management_view.dart';
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
      const ProductManagementPage(),
      const OrderManagementPage(),
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
        String assetPath, String label, int index) {
      return BottomNavigationBarItem(
        icon: Container(
          margin: EdgeInsets.only(top: Dimenssions.height5),
          child: GetX<MerchantController>(
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
      return GetX<MerchantController>(
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
          child: BottomNavigationBar(
            selectedItemColor: logoColorSecondary,
            unselectedItemColor: secondaryTextColor,
            currentIndex: controller.currentIndex.value,
            onTap: (index) {
              controller.currentIndex.value = index; // Update the current index
              Get.to(pages[
                  index]); // Navigate to the new page without the bottom navigation bar
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: backgroundColor2,
            elevation: 0,
            items: [
              createNavItem('assets/icon_home.png', 'Home', 0),
              createNavItem('assets/list.png', 'Products', 1),
              createNavItem('assets/icon_cart.png', 'Orders', 2),
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
        backgroundColor: backgroundColor1,
        body: body(),
        bottomNavigationBar: customBottomNav(),
      ),
    );
  }
}
