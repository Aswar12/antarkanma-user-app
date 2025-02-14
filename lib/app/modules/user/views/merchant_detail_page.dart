import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/controllers/merchant_detail_controller.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/widgets/product_grid_card.dart';
import 'package:antarkanma/app/widgets/search_input_field.dart';
import 'package:antarkanma/app/widgets/cached_image_view.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class MerchantDetailPage extends GetView<MerchantDetailController> {
  const MerchantDetailPage({super.key});

  Widget buildSearchBar() {
    return Container(
      height: 40,
      margin: EdgeInsets.only(
        left: Dimenssions.width2,
        right: Dimenssions.width12,
      ),
      child: SearchInputField(
        controller: controller.searchController,
        hintText: 'Cari produk di toko ini',
        onClear: () {
          controller.searchController.clear();
          controller.searchProducts('');
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onChanged: (value) => controller.searchProducts(value),
      ),
    );
  }

  String _getOperatingHours(merchant) {
    if (merchant.openingTime == null || merchant.closingTime == null) {
      return 'Jam operasional tidak tersedia';
    }
    return '${merchant.openingTime} - ${merchant.closingTime} (${merchant.operatingDays?.join(", ") ?? "Tidak tersedia"})';
  }

  Widget buildMerchantHeader(merchant) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: Dimenssions.height10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image and Info
          Stack(
            children: [
              // Background Image with Hero
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Hero(
                  tag: 'merchant-${merchant.id}',
                  child: merchant.logoUrl != null && merchant.logoUrl!.isNotEmpty
                      ? CachedImageView(
                          imageUrl: merchant.logoUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : Container(
                          color: backgroundColor3,
                          child: Center(
                            child: Icon(
                              Icons.store_rounded,
                              color: secondaryTextColor.withOpacity(0.5),
                              size: Dimenssions.iconSize24 * 2,
                            ),
                          ),
                        ),
                ),
              ),
              // Gradient Overlay
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
              // Merchant Info Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(Dimenssions.width20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              merchant.name,
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font20,
                                fontWeight: semiBold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimenssions.width8,
                              vertical: Dimenssions.height4,
                            ),
                            decoration: BoxDecoration(
                              color: merchant.isActive ? Colors.green : alertColor,
                              borderRadius: BorderRadius.circular(Dimenssions.radius8),
                            ),
                            child: Text(
                              merchant.isActive ? 'Buka' : 'Tutup',
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font12,
                                color: Colors.white,
                                fontWeight: medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Dimenssions.height8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: Dimenssions.width4),
                          Expanded(
                            child: Text(
                              merchant.address,
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Additional Info Section
          Container(
            margin: EdgeInsets.all(Dimenssions.width15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description if available
                if (merchant.description != null && merchant.description!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(Dimenssions.width12),
                    decoration: BoxDecoration(
                      color: backgroundColor2,
                      borderRadius: BorderRadius.circular(Dimenssions.radius12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      merchant.description!,
                      style: secondaryTextStyle.copyWith(
                        fontSize: Dimenssions.font14,
                        height: 1.5,
                      ),
                    ),
                  ),

                SizedBox(height: Dimenssions.height10),

                // Info Row
                Container(
                  padding: EdgeInsets.all(Dimenssions.width12),
                  decoration: BoxDecoration(
                    color: backgroundColor2,
                    borderRadius: BorderRadius.circular(Dimenssions.radius12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Operating Hours
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(Dimenssions.width6),
                              decoration: BoxDecoration(
                                color: logoColorSecondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(Dimenssions.radius8),
                              ),
                              child: Icon(
                                Icons.access_time,
                                color: logoColorSecondary,
                                size: 16,
                              ),
                            ),
                            SizedBox(width: Dimenssions.width8),
                            Expanded(
                              child: Text(
                                _getOperatingHours(merchant),
                                style: secondaryTextStyle.copyWith(
                                  fontSize: Dimenssions.font12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 24,
                        width: 1,
                        color: backgroundColor3.withOpacity(0.5),
                        margin: EdgeInsets.symmetric(horizontal: Dimenssions.width12),
                      ),
                      // Product Count
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(Dimenssions.width6),
                            decoration: BoxDecoration(
                              color: logoColorSecondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(Dimenssions.radius8),
                            ),
                            child: Icon(
                              Icons.shopping_bag,
                              color: logoColorSecondary,
                              size: 16,
                            ),
                          ),
                          SizedBox(width: Dimenssions.width8),
                          Text(
                            '${merchant.productCount} Produk',
                            style: secondaryTextStyle.copyWith(
                              fontSize: Dimenssions.font12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Dimenssions.height10),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (merchant.id != null) {
                            Get.toNamed('/chat', arguments: {
                              'merchantId': merchant.id,
                              'merchantName': merchant.name,
                            });
                          }
                        },
                        icon: Icon(Icons.chat_outlined,
                            color: Colors.white, size: 20),
                        label: Text(
                          'Chat Penjual',
                          style: primaryTextStyle.copyWith(
                            color: Colors.white,
                            fontWeight: medium,
                            fontSize: Dimenssions.font14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: logoColorSecondary,
                          padding: EdgeInsets.symmetric(
                              vertical: Dimenssions.height10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Dimenssions.width12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final phoneNumber = merchant.phoneNumber;
                          if (phoneNumber.isNotEmpty) {
                            final url = 'tel:$phoneNumber';
                            if (await url_launcher.canLaunch(url)) {
                              await url_launcher.launch(url);
                            }
                          }
                        },
                        icon: Icon(Icons.phone_outlined,
                            color: Colors.white, size: 20),
                        label: Text(
                          'Hubungi',
                          style: primaryTextStyle.copyWith(
                            color: Colors.white,
                            fontWeight: medium,
                            fontSize: Dimenssions.font14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: logoColorSecondary,
                          padding: EdgeInsets.symmetric(
                              vertical: Dimenssions.height10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductGrid() {
    return Obx(() {
      if (controller.isLoading.value) {
        return SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: logoColorSecondary,
            ),
          ),
        );
      }

      if (controller.products.isEmpty) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: Dimenssions.iconSize24 * 2,
                  color: secondaryTextColor,
                ),
                SizedBox(height: Dimenssions.height10),
                Text(
                  'Tidak ada produk',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font16,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          mainAxisSpacing: Dimenssions.height15,
          crossAxisSpacing: Dimenssions.width15,
        ),
        itemCount: controller.products.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final product = controller.products[index];
          final productWithMerchant = ProductModel(
            id: product.id,
            name: product.name,
            description: product.description,
            galleries: product.galleries,
            price: product.price,
            status: product.status,
            merchant: controller.merchant.value,
            category: product.category,
            createdAt: product.createdAt,
            updatedAt: product.updatedAt,
            variants: product.variants,
            reviews: product.reviews,
            averageRatingRaw: product.averageRatingRaw,
            totalReviewsRaw: product.totalReviewsRaw,
            ratingInfo: product.ratingInfo,
          );

          return ProductGridCard(
            product: productWithMerchant,
            onTap: () => Get.toNamed(
              Routes.productDetail,
              arguments: productWithMerchant,
              preventDuplicates: true,
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor1,
      appBar: AppBar(
        backgroundColor: backgroundColor1,
        elevation: 0,
        leading: IconButton(
          padding: EdgeInsets.only(left: Dimenssions.width8),
          icon: Icon(
            Icons.arrow_back_ios,
            color: primaryTextColor,
            size: Dimenssions.iconSize24,
          ),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: buildSearchBar(),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: logoColorSecondary,
            ),
          );
        }

        if (controller.merchant.value == null) {
          return Center(
            child: Text(
              'Merchant tidak ditemukan',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font16,
                color: secondaryTextColor,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              if (controller.merchant.value != null)
                buildMerchantHeader(controller.merchant.value!),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimenssions.width15,
                  vertical: Dimenssions.height10,
                ),
                child: buildProductGrid(),
              ),
            ],
          ),
        );
      }),
    );
  }
}
