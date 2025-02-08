import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:antarkanma/theme.dart';
import 'home_skeleton_loading.dart';

class MerchantSkeletonLoading extends StatelessWidget {
  const MerchantSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: ShimmerWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            _buildHeaderSection(),

            // Info section
            _buildInfoSection(),

            // Products section
            _buildProductsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      height: Dimenssions.height200,
      width: double.infinity,
      color: backgroundColor1,
      child: Stack(
        children: [
          // Cover image skeleton
          Container(
            height: Dimenssions.height150,
            width: double.infinity,
            color: backgroundColor1,
          ),
          
          // Profile image skeleton
          Positioned(
            bottom: Dimenssions.height20,
            left: Dimenssions.width20,
            child: Container(
              height: Dimenssions.height80,
              width: Dimenssions.height80,
              decoration: BoxDecoration(
                color: backgroundColor1,
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Merchant name skeleton
          Positioned(
            bottom: Dimenssions.height45,
            left: Dimenssions.width120,
            child: Container(
              height: Dimenssions.height20,
              width: Dimenssions.width150,
              decoration: BoxDecoration(
                color: backgroundColor1,
                borderRadius: BorderRadius.circular(Dimenssions.radius4),
              ),
            ),
          ),
          
          // Rating skeleton
          Positioned(
            bottom: Dimenssions.height20,
            left: Dimenssions.width120,
            child: Container(
              height: Dimenssions.height15,
              width: Dimenssions.width80,
              decoration: BoxDecoration(
                color: backgroundColor1,
                borderRadius: BorderRadius.circular(Dimenssions.radius4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: EdgeInsets.all(Dimenssions.width15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description skeleton
          Container(
            height: Dimenssions.height15,
            width: double.infinity,
            margin: EdgeInsets.only(bottom: Dimenssions.height10),
            decoration: BoxDecoration(
              color: backgroundColor1,
              borderRadius: BorderRadius.circular(Dimenssions.radius4),
            ),
          ),
          Container(
            height: Dimenssions.height15,
            width: Dimenssions.screenWidth * 0.7,
            decoration: BoxDecoration(
              color: backgroundColor1,
              borderRadius: BorderRadius.circular(Dimenssions.radius4),
            ),
          ),

          SizedBox(height: Dimenssions.height20),

          // Stats skeleton
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (index) => _buildStatItem()),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem() {
    return Column(
      children: [
        Container(
          height: Dimenssions.height30,
          width: Dimenssions.height30,
          decoration: BoxDecoration(
            color: backgroundColor1,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(height: Dimenssions.height5),
        Container(
          height: Dimenssions.height12,
          width: Dimenssions.width60,
          decoration: BoxDecoration(
            color: backgroundColor1,
            borderRadius: BorderRadius.circular(Dimenssions.radius4),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title skeleton
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

        // Products grid skeleton
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.all(Dimenssions.width15),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: Dimenssions.height15,
            crossAxisSpacing: Dimenssions.width15,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => _buildProductItem(),
        ),
      ],
    );
  }

  Widget _buildProductItem() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
      ),
      child: Column(
        children: [
          // Product image skeleton
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor1,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(Dimenssions.radius15),
                ),
              ),
            ),
          ),

          // Product info skeleton
          Expanded(
            flex: 2,
            child: Container(
              padding: EdgeInsets.all(Dimenssions.width10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Product name skeleton
                  Container(
                    height: Dimenssions.height15,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: backgroundColor1,
                      borderRadius: BorderRadius.circular(Dimenssions.radius4),
                    ),
                  ),

                  // Price skeleton
                  Container(
                    height: Dimenssions.height15,
                    width: Dimenssions.width80,
                    decoration: BoxDecoration(
                      color: backgroundColor1,
                      borderRadius: BorderRadius.circular(Dimenssions.radius4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
