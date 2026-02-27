import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';

import 'package:flutter/services.dart';

class HomeAppBarWidget extends StatelessWidget {
  const HomeAppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Attempt to find controller, if not found, we handle gracefully or let GetX handle injection elsewhere
    final locationController = Get.put(UserLocationController());

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // For iOS
      ),
      child: Container(
        padding: EdgeInsets.only(
          left: Dimenssions.width15,
          right: Dimenssions.width15,
          top: MediaQuery.of(context).padding.top + Dimenssions.height10,
          bottom: Dimenssions.height15, // Reduced padding for compact look
        ),
        decoration: BoxDecoration(
          color: navyColor,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(Dimenssions.radius30),
            bottomRight: Radius.circular(Dimenssions.radius30),
          ),
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
                          color: primaryOrange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: Colors.white,
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
                                letterSpacing: 1.2,
                              ),
                            ),
                            Obx(() {
                              final address = locationController.currentAddress;
                              return Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      address.isEmpty
                                          ? 'Pilih Lokasi Pengiriman'
                                          : address,
                                      style: primaryTextStyle.copyWith(
                                        fontSize: Dimenssions.font14,
                                        color: Colors.white,
                                        fontWeight: bold,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.expand_more,
                                    color: Colors.white.withOpacity(0.6),
                                    size: Dimenssions
                                        .iconSize16, // slightly smaller
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
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () {},
                    icon: Stack(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: Dimenssions.iconSize24,
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: primaryOrange,
                              shape: BoxShape.circle,
                              border: Border.all(color: navyColor, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
