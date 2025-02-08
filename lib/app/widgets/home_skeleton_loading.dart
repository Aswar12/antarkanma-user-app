import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:antarkanma/theme.dart';

class HomeSkeletonLoading extends StatelessWidget {
  const HomeSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: ShimmerWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar skeleton
            _buildSearchBar(),

            // Popular products section
            _buildPopularProductsSection(),

            // Categories section
            _buildCategoriesSection(),

            // Merchants section
            _buildMerchantsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(Dimenssions.height15),
      height: Dimenssions.height45,
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
      ),
    );
  }

  Widget _buildPopularProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title skeleton
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: Dimenssions.width15,
            vertical: Dimenssions.height10,
          ),
          height: Dimenssions.height20,
          width: Dimenssions.screenWidth * 0.4,
          decoration: BoxDecoration(
            color: backgroundColor1,
            borderRadius: BorderRadius.circular(Dimenssions.radius4),
          ),
        ),

        // Carousel skeleton
        Container(
          margin: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
          height: Dimenssions.pageView,
          decoration: BoxDecoration(
            color: backgroundColor1,
            borderRadius: BorderRadius.circular(Dimenssions.radius15),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Dimenssions.width15,
        vertical: Dimenssions.height15,
      ),
      height: Dimenssions.height45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) => _buildCategoryItem(),
      ),
    );
  }

  Widget _buildCategoryItem() {
    return Container(
      margin: EdgeInsets.only(right: Dimenssions.width10),
      width: Dimenssions.width100,
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: BorderRadius.circular(Dimenssions.radius8),
      ),
    );
  }

  Widget _buildMerchantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title skeleton
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: Dimenssions.width15,
            vertical: Dimenssions.height10,
          ),
          height: Dimenssions.height20,
          width: Dimenssions.screenWidth * 0.4,
          decoration: BoxDecoration(
            color: backgroundColor1,
            borderRadius: BorderRadius.circular(Dimenssions.radius4),
          ),
        ),

        // Merchants grid skeleton
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            mainAxisSpacing: Dimenssions.height10,
            crossAxisSpacing: Dimenssions.width10,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => _buildMerchantItem(),
        ),
      ],
    );
  }

  Widget _buildMerchantItem() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
      ),
    );
  }
}

class ShimmerWrapper extends StatelessWidget {
  final Widget child;

  const ShimmerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: backgroundColor1.withOpacity(0.1),
      highlightColor: backgroundColor1.withOpacity(0.3),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}
