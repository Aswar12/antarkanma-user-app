import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:antarkanma/theme.dart';

class ProductDetailSkeletonLoading extends StatelessWidget {
  const ProductDetailSkeletonLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: backgroundColor1.withOpacity(0.1),
      highlightColor: logoColor.withOpacity(0.3),
      period: const Duration(milliseconds: 1500),
      child: Column(
        children: [
          // Merchant section skeleton
          Container(
            margin: EdgeInsets.all(Dimenssions.width15),
            padding: EdgeInsets.all(Dimenssions.width15),
            decoration: BoxDecoration(
              color: backgroundColor2,
              borderRadius: BorderRadius.circular(Dimenssions.radius12),
            ),
            child: Row(
              children: [
                // Merchant image
                Container(
                  height: Dimenssions.height50,
                  width: Dimenssions.height50,
                  decoration: BoxDecoration(
                    color: backgroundColor1,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: Dimenssions.width15),

                // Merchant info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: Dimenssions.height15,
                        width: Dimenssions.width150,
                        decoration: BoxDecoration(
                          color: backgroundColor1,
                          borderRadius: BorderRadius.circular(Dimenssions.radius4),
                        ),
                      ),
                      SizedBox(height: Dimenssions.height8),
                      Container(
                        height: Dimenssions.height12,
                        width: Dimenssions.width100,
                        decoration: BoxDecoration(
                          color: backgroundColor1,
                          borderRadius: BorderRadius.circular(Dimenssions.radius4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Reviews section skeleton
          Container(
            margin: EdgeInsets.all(Dimenssions.width15),
            padding: EdgeInsets.all(Dimenssions.width15),
            decoration: BoxDecoration(
              color: backgroundColor2,
              borderRadius: BorderRadius.circular(Dimenssions.radius12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                Container(
                  height: Dimenssions.height20,
                  width: Dimenssions.width120,
                  decoration: BoxDecoration(
                    color: backgroundColor1,
                    borderRadius: BorderRadius.circular(Dimenssions.radius4),
                  ),
                ),
                SizedBox(height: Dimenssions.height15),

                // Review items
                ...List.generate(2, (index) => _buildReviewItem()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem() {
    return Container(
      margin: EdgeInsets.only(bottom: Dimenssions.height15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info
          Row(
            children: [
              Container(
                height: Dimenssions.height40,
                width: Dimenssions.height40,
                decoration: BoxDecoration(
                  color: backgroundColor1,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: Dimenssions.width10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: Dimenssions.height15,
                    width: Dimenssions.width100,
                    decoration: BoxDecoration(
                      color: backgroundColor1,
                      borderRadius: BorderRadius.circular(Dimenssions.radius4),
                    ),
                  ),
                  SizedBox(height: Dimenssions.height5),
                  Container(
                    height: Dimenssions.height12,
                    width: Dimenssions.width80,
                    decoration: BoxDecoration(
                      color: backgroundColor1,
                      borderRadius: BorderRadius.circular(Dimenssions.radius4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: Dimenssions.height10),

          // Review content
          Container(
            height: Dimenssions.height15,
            width: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor1,
              borderRadius: BorderRadius.circular(Dimenssions.radius4),
            ),
          ),
          SizedBox(height: Dimenssions.height5),
          Container(
            height: Dimenssions.height15,
            width: Dimenssions.screenWidth * 0.7,
            decoration: BoxDecoration(
              color: backgroundColor1,
              borderRadius: BorderRadius.circular(Dimenssions.radius4),
            ),
          ),
        ],
      ),
    );
  }
}
