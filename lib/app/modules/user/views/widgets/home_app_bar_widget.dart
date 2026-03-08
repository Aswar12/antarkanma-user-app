import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/controllers/notification_controller.dart';

import 'package:flutter/services.dart';

class HomeAppBarWidget extends StatelessWidget {
  const HomeAppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final locationController = Get.put(UserLocationController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: Dimenssions.width20,
          right: Dimenssions.width20,
          top: MediaQuery.of(context).padding.top + Dimenssions.height12,
          bottom: Dimenssions.height12,
        ),
        decoration: BoxDecoration(
          color: navyColor,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(Dimenssions.radius30),
            bottomRight: Radius.circular(Dimenssions.radius30),
          ),
          boxShadow: [
            BoxShadow(
              color: navyColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(Dimenssions.width8),
                        decoration: BoxDecoration(
                          color: primaryOrange.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: primaryOrange,
                          size: Dimenssions.iconSize20,
                        ),
                      ),
                      SizedBox(width: Dimenssions.width10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Antar ke',
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font10,
                                color: primaryOrange.withOpacity(0.9),
                                fontWeight: semiBold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Obx(() {
                              final address = locationController.currentAddress;
                              return Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      address.isEmpty
                                          ? 'Pilih Lokasi'
                                          : address,
                                      style: primaryTextStyle.copyWith(
                                        fontSize: Dimenssions.font12,
                                        color: Colors.white,
                                        fontWeight: bold,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white.withOpacity(0.7),
                                    size: Dimenssions.iconSize16,
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(Dimenssions.radius12),
                  ),
                  child: GetBuilder<NotificationController>(
                    init: NotificationController(),
                    builder: (notificationController) {
                      return Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              Get.toNamed('/usermain/notification-inbox');
                            },
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: Colors.white,
                              size: Dimenssions.iconSize24,
                            ),
                          ),
                          Obx(() => notificationController.unreadCount.value > 0
                              ? Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: primaryOrange,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: navyColor, width: 2.5),
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink()),
                        ],
                      );
                    }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
