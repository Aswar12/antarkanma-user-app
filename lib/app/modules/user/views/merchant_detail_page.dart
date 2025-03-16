import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/controllers/merchant_detail_controller.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/widgets/merchant_skeleton_loading.dart';
import 'package:antarkanma/app/widgets/product_grid_card.dart';
import 'package:antarkanma/app/widgets/search_input_field.dart';
import 'package:antarkanma/app/widgets/cached_image_view.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
          AspectRatio(
            aspectRatio: 16/9, // Wider aspect ratio for header image
            child: Stack(
              children: [
                // Background Image with Hero
                Hero(
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
                // Gradient Overlay
                Container(
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

                // WhatsApp Chat Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final phoneNumber = merchant.phoneNumber;
                      if (phoneNumber.isNotEmpty) {
                        // Format phone number for WhatsApp
                        String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
                        if (!formattedPhone.startsWith('+62')) {
                          formattedPhone = '+62${formattedPhone.startsWith('0') ? formattedPhone.substring(1) : formattedPhone}';
                        }
                        
                        // Try to launch WhatsApp app first
                        final whatsappUri = Uri.parse('whatsapp://send?phone=${formattedPhone.substring(1)}');
                        try {
                          final launched = await launchUrl(
                            whatsappUri,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!launched) {
                            // Fallback to web WhatsApp if app launch fails
                            final webWhatsappUri = Uri.parse('https://wa.me/${formattedPhone.substring(1)}');
                            await launchUrl(webWhatsappUri);
                          }
                        } catch (e) {
                          print('Error launching WhatsApp: $e');
                        }
                      }
                    },
                    icon: FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: Text(
                      'Chat WhatsApp',
                      style: primaryTextStyle.copyWith(
                        color: Colors.white,
                        fontWeight: medium,
                        fontSize: Dimenssions.font14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: logoColorSecondary,
                      padding: EdgeInsets.symmetric(
                        vertical: Dimenssions.height12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimenssions.radius12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProductGrid(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const MerchantSkeletonLoading();
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

      final screenWidth = MediaQuery.of(context).size.width;
      final cardWidth = (screenWidth - (Dimenssions.width15 * 2) - Dimenssions.width8) / 2;
      final cardHeight = cardWidth * 1.5; // 3:2 aspect ratio

      return GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: Dimenssions.height8,
          crossAxisSpacing: Dimenssions.width8,
          mainAxisExtent: cardHeight,
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
          return const MerchantSkeletonLoading();
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

        return RefreshIndicator(
          onRefresh: () async {
            if (controller.merchant.value?.id != null) {
              await controller.loadMerchantData(controller.merchant.value!.id!);
            }
          },
          color: logoColorSecondary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                if (controller.merchant.value != null && 
                    controller.searchController.text.isEmpty)
                  buildMerchantHeader(controller.merchant.value),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimenssions.width15,
                    vertical: Dimenssions.height10,
                  ),
                  child: buildProductGrid(context),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
