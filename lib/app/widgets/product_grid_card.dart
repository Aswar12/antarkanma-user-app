import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/widgets/cached_image_view.dart';
import 'package:antarkanma/app/widgets/star_rating.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductGridCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const ProductGridCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: Dimenssions.width4,
          vertical: Dimenssions.height4,
        ),
        decoration: BoxDecoration(
          color: backgroundColor2,
          borderRadius: BorderRadius.circular(Dimenssions.radius20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimenssions.radius20),
          child: Stack(
            children: [
              // Product Image
              SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Hero(
                  tag: 'product-grid-${product.id}',
                  child: product.galleries.isNotEmpty &&
                          product.imageUrls[0].isNotEmpty
                      ? CachedImageView(
                          imageUrl: product.imageUrls[0],
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/image_shoes.png',
                          fit: BoxFit.cover,
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
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.3, 0.5, 0.8, 1.0],
                  ),
                ),
              ),

              // Content Overlay
              Padding(
                padding: EdgeInsets.all(Dimenssions.width12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Merchant Badge
                    if (product.merchant?.name != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimenssions.width8,
                          vertical: Dimenssions.height4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(Dimenssions.radius20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 0,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.store,
                              color: Colors.white,
                              size: Dimenssions.iconSize16,
                            ),
                            SizedBox(width: Dimenssions.width4),
                            Text(
                              product.merchant!.name,
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font12,
                                color: Colors.white,
                                fontWeight: medium,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const Spacer(),

                    // Product Info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product Name
                        Text(
                          product.name,
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font16,
                            fontWeight: semiBold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: Dimenssions.height4),

                        // Price
                        Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(product.price),
                          style: priceTextStyle.copyWith(
                            fontSize: Dimenssions.font14,
                            fontWeight: semiBold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: Dimenssions.height8),

                        // Rating and Reviews
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimenssions.width8,
                            vertical: Dimenssions.height4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(Dimenssions.radius12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StarRating(
                                rating: product.averageRating,
                                size: Dimenssions.iconSize16,
                                color: Colors.amber,
                              ),
                              SizedBox(width: Dimenssions.width4),
                              Text(
                                '(${product.totalReviews})',
                                style: secondaryTextStyle.copyWith(
                                  fontSize: Dimenssions.font12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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
