import 'package:antarkanma/app/widgets/merchant_card.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:get/get.dart';

class MerchantHorizontalList extends StatelessWidget {
  final HomePageController controller;

  const MerchantHorizontalList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Merchant Terdekat',
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font18,
                  fontWeight: bold,
                  color: navyColor,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to all merchants
                },
                child: Row(
                  children: [
                    Text(
                      'Lihat Semua',
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font14,
                        fontWeight: bold,
                        color: primaryOrange,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: primaryOrange,
                      size: Dimenssions.iconSize16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Dimenssions.height10),
        SizedBox(
          height: Dimenssions.height220, // Adjust based on card height
          child: Obx(() {
            if (controller.isLoading.value) {
              return Center(child: CircularProgressIndicator());
            }
            if (controller.allMerchants.isEmpty) {
              return Center(child: Text("Belum ada merchant"));
            }
            // Use top 5 merchants for horizontal list
            final merchants = controller.allMerchants.take(5).toList();

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
              scrollDirection: Axis.horizontal,
              itemCount: merchants.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: Dimenssions.width15),
                  child: SizedBox(
                    width: Dimenssions.width150 * 1.6, // Card width
                    child: MerchantCard(merchant: merchants[index]),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}
