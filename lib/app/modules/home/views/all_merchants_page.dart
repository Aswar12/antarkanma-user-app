import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/widgets/merchant_card.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AllMerchantsPage extends StatelessWidget {
  const AllMerchantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomePageController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Semua Merchant',
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font18,
            fontWeight: bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.allMerchants.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: Dimenssions.height16),
                Text(
                  'Belum ada merchant',
                  style: secondaryTextStyle.copyWith(
                    fontSize: Dimenssions.font16,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.refreshProducts();
          },
          color: primaryOrange,
          child: GridView.builder(
            padding: EdgeInsets.all(Dimenssions.width15),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              mainAxisSpacing: Dimenssions.height10,
              crossAxisSpacing: Dimenssions.width10,
            ),
            itemCount: controller.allMerchants.length,
            itemBuilder: (context, index) {
              final merchant = controller.allMerchants[index];
              return MerchantCard(
                merchant: merchant,
                onTap: () {
                  Get.toNamed(
                    Routes.merchantDetail,
                    arguments: {'merchantId': merchant.id},
                  );
                },
              );
            },
          ),
        );
      }),
    );
  }
}
