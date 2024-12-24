import 'package:antarkanma/app/modules/courier/views/courier_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/constants/app_colors.dart';
import 'package:antarkanma/app/modules/courier/views/delivery_list_view.dart';
import 'package:antarkanma/app/modules/courier/views/delivery_management_page.dart';
import 'package:antarkanma/app/modules/courier/views/courier_home_page.dart';
import 'package:antarkanma/app/modules/user/views/profile_page.dart';
import 'package:antarkanma/app/modules/courier/controllers/courier_controller.dart';

class CourierMainPage extends GetView<CourierController> {
  const CourierMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final CourierController controller = Get.find();

    final List<Widget> pages = [
      const CourierHomePage(),
      const DeliveryManagementPage(),
      CourierProfilePage(),
      const DeliveryListView(),
    ];

    Widget body() {
      return GetX<CourierController>(
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
          child: GetX<CourierController>(
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
      return GetX<CourierController>(
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
              controller.changePage(index); // Update the current index
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: backgroundColor2,
            elevation: 0,
            items: [
              createNavItem('assets/icon_home.png', 'Home', 0),
              createNavItem('assets/icon_shipping.png', 'Shipments', 1),
              createNavItem('assets/icon_profile.png', 'Profile', 2),
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
