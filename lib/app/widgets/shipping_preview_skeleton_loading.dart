import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:antarkanma/theme.dart';

class ShippingPreviewSkeletonLoading extends StatelessWidget {
  const ShippingPreviewSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shipping method title
          Container(
            margin: EdgeInsets.symmetric(
              horizontal: Dimenssions.width15,
              vertical: Dimenssions.height10,
            ),
            height: Dimenssions.height20,
            width: Dimenssions.screenWidth * 0.6,
            decoration: BoxDecoration(
              color: backgroundColor3,
              borderRadius: BorderRadius.circular(Dimenssions.radius4),
            ),
          ),

          // Shipping details card
          Container(
            margin: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
            padding: EdgeInsets.all(Dimenssions.height15),
            decoration: BoxDecoration(
              color: backgroundColor3,
              borderRadius: BorderRadius.circular(Dimenssions.radius15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Distance info
                _buildInfoRow(),
                SizedBox(height: Dimenssions.height15),

                // Time estimate
                _buildInfoRow(),
                SizedBox(height: Dimenssions.height15),

                // Cost estimate
                _buildInfoRow(),
              ],
            ),
          ),

          // Route optimization info
          Container(
            margin: EdgeInsets.all(Dimenssions.height15),
            padding: EdgeInsets.all(Dimenssions.height15),
            decoration: BoxDecoration(
              color: backgroundColor3,
              borderRadius: BorderRadius.circular(Dimenssions.radius15),
            ),
            child: Column(
              children: [
                // Route title
                Container(
                  height: Dimenssions.height20,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: backgroundColor3,
                    borderRadius: BorderRadius.circular(Dimenssions.radius4),
                  ),
                ),
                SizedBox(height: Dimenssions.height15),

                // Route details
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: Dimenssions.height100,
                        decoration: BoxDecoration(
                          color: backgroundColor3,
                          borderRadius: BorderRadius.circular(Dimenssions.radius8),
                        ),
                      ),
                    ),
                    SizedBox(width: Dimenssions.width15),
                    Container(
                      width: Dimenssions.width100,
                      height: Dimenssions.height100,
                      decoration: BoxDecoration(
                        color: backgroundColor3,
                        borderRadius: BorderRadius.circular(Dimenssions.radius8),
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

  Widget _buildInfoRow() {
    return Row(
      children: [
        // Icon placeholder
        Container(
          width: Dimenssions.width20,
          height: Dimenssions.height20,
          decoration: BoxDecoration(
            color: backgroundColor3,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: Dimenssions.width10),
        
        // Text placeholder
        Expanded(
          child: Container(
            height: Dimenssions.height16,
            decoration: BoxDecoration(
              color: backgroundColor3,
              borderRadius: BorderRadius.circular(Dimenssions.radius4),
            ),
          ),
        ),
      ],
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
      baseColor: backgroundColor3.withOpacity(0.1),
      highlightColor: logoColor.withOpacity(0.3),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}
