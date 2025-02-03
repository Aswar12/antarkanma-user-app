import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/widgets/cached_image_view.dart';
import 'package:antarkanma/app/widgets/star_rating.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductCarouselCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductCarouselCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: Dimenssions.width5),
        decoration: BoxDecoration(
          color: backgroundColor1,
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Product Image
              if (product.galleries.isNotEmpty &&
                  product.imageUrls[0].isNotEmpty)
                Hero(
                  tag: 'product-${product.id}',
                  child: CachedImageView(
                    imageUrl: product.imageUrls[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              else
                Image.asset(
                  'assets/image_shoes.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),

              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(Dimenssions.width15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Product Name and Merchant
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: primaryTextStyle.copyWith(
                            color: backgroundColor1,
                            fontSize: Dimenssions.font18,
                            fontWeight: semiBold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (product.merchant?.name != null) ...[
                          SizedBox(height: Dimenssions.height4),
                          Row(
                            children: [
                              Icon(
                                Icons.store,
                                color: backgroundColor1,
                                size: Dimenssions.iconSize16,
                              ),
                              SizedBox(width: Dimenssions.width4),
                              Expanded(
                                child: Text(
                                  product.merchant!.name,
                                  style: primaryTextStyle.copyWith(
                                    color: backgroundColor1.withOpacity(0.8),
                                    fontSize: Dimenssions.font12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    // Price and Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(product.price),
                              style: priceTextStyle.copyWith(
                                color: backgroundColor1,
                                fontSize: Dimenssions.font16,
                                fontWeight: semiBold,
                              ),
                            ),
                          ],
                        ),

                        // Rating
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            StarRating(
                              rating: product.ratingInfo != null
                                  ? (product.ratingInfo!['average_rating']
                                          as num)
                                      .toDouble()
                                  : product.averageRating,
                              size: Dimenssions.height15,
                            ),
                            SizedBox(height: Dimenssions.height2),
                            Text(
                              '${product.ratingInfo != null ? product.ratingInfo!['total_reviews'] : product.totalReviews} ulasan',
                              style: primaryTextStyle.copyWith(
                                color: backgroundColor1.withOpacity(0.8),
                                fontSize: Dimenssions.font12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
