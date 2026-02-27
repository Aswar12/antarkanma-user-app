import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/widgets/product_carousel_card.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:shimmer/shimmer.dart';

class PopularProductsWidget extends StatelessWidget {
  final HomePageController controller;

  const PopularProductsWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Produk Populer',
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font18,
                  fontWeight: bold,
                  color: navyColor,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to all products if implemented
                },
                child: Text(
                  'Lihat Semua',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font14,
                    color: primaryOrange,
                    fontWeight: medium,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Dimenssions.height15),
        Obx(() {
          if (controller.isLoadingPopularProducts.value) {
            return Container(
              height: Dimenssions.height100 * 2.8,
              margin: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Dimenssions.radius15),
                  ),
                ),
              ),
            );
          }

          if (controller.popularProducts.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(Dimenssions.height20),
                child: Text(
                  'Belum ada produk populer',
                  style: secondaryTextStyle,
                ),
              ),
            );
          }

          return Column(
            children: [
              CarouselSlider.builder(
                itemCount: controller.popularProducts.length,
                itemBuilder: (context, index, realIndex) {
                  final product = controller.popularProducts[index];
                  return ProductCarouselCard(
                    product: product,
                    onTap: () {
                      Get.toNamed(Routes.productDetail, arguments: product);
                    },
                  );
                },
                options: CarouselOptions(
                  height: Dimenssions.height100 * 2.2,
                  viewportFraction: 0.8, // Adjusted to show side cards
                  enlargeCenterPage: true,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 4),
                  onPageChanged: (index, reason) {
                    controller.updateCurrentIndex(index);
                  },
                ),
              ),
              SizedBox(height: Dimenssions.height15),
              AnimatedSmoothIndicator(
                activeIndex: controller.currentIndex.value,
                count: controller.popularProducts.length,
                effect: ExpandingDotsEffect(
                  dotWidth: 8,
                  dotHeight: 8,
                  activeDotColor: primaryOrange,
                  dotColor: Colors.grey.withOpacity(0.5),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}
