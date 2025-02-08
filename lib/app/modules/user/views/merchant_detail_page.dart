import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/controllers/merchant_detail_controller.dart';
import 'package:antarkanma/app/widgets/merchant_detail_section.dart';
import 'package:antarkanma/app/widgets/product_grid_card.dart';
import 'package:antarkanma/app/widgets/search_input_field.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MerchantDetailPage extends GetView<MerchantDetailController> {
  const MerchantDetailPage({super.key});

  Widget buildSearchBar() {
    return Expanded(
      child: Container(
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
          // Ensure product has merchant data before navigation
          final productWithMerchant = ProductModel(
            id: product.id,
            name: product.name,
            description: product.description,
            galleries: product.galleries,
            price: product.price,
            status: product.status,
            merchant: controller.merchant.value,  // Include current merchant data
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
            onTap: () => Get.toNamed('/product-detail', arguments: productWithMerchant),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor1,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
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

        return CustomScrollView(
          slivers: [
            if (controller.merchant.value != null)
              SliverToBoxAdapter(
                child: MerchantDetailSection(merchant: controller.merchant.value!),
              ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Dimenssions.width15,
                vertical: Dimenssions.height10,
              ),
              sliver: SliverToBoxAdapter(
                child: buildProductGrid(),
              ),
            ),
          ],
        );
      }),
    );
  }
}
