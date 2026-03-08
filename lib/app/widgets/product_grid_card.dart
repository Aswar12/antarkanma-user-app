import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/widgets/cached_image_view.dart';
import 'package:antarkanma/app/widgets/star_rating.dart';
import 'package:antarkanma/app/controllers/wishlist_controller.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

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
        width: MediaQuery.of(context).size.width * 0.45,
        decoration: BoxDecoration(
          color: backgroundColor2,
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Image with Shimmer Loading
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(Dimenssions.radius15),
                      topRight: Radius.circular(Dimenssions.radius15),
                    ),
                    child: Hero(
                      tag: 'product-grid-${product.id}',
                      child: product.galleries.isNotEmpty &&
                              product.imageUrls[0].isNotEmpty
                          ? CachedImageView(
                              imageUrl: product.imageUrls[0],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Image.asset(
                              'assets/image_shoes.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                    ),
                  ),
                  // Merchant Badge
                  if (product.merchant?.name != null)
                    Positioned(
                      top: Dimenssions.height8,
                      left: Dimenssions.width8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimenssions.width8,
                          vertical: Dimenssions.height4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius:
                              BorderRadius.circular(Dimenssions.radius20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.store,
                              color: backgroundColor1,
                              size: Dimenssions.iconSize16,
                            ),
                            SizedBox(width: Dimenssions.width4),
                            Text(
                              product.merchant!.name,
                              style: primaryTextStyle.copyWith(
                                color: backgroundColor1,
                                fontSize: Dimenssions.font10,
                                fontWeight: medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Wishlist Heart Icon
                  if (product.id != null)
                    Positioned(
                      top: Dimenssions.height8,
                      right: Dimenssions.width8,
                      child: GetBuilder<WishlistController>(
                        init: Get.find<WishlistController>(),
                        builder: (wishlistCtrl) {
                          return Obx(() {
                            final isFav =
                                wishlistCtrl.isWishlisted(product.id!);
                            return GestureDetector(
                              onTap: () => wishlistCtrl.toggleWishlist(
                                product.id!,
                                product: product,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.grey[600],
                                  size: Dimenssions.iconSize16,
                                ),
                              ),
                            );
                          });
                        },
                      ),
                    ),
                ],
              ),
            ),
            // Product Details Section
            Expanded(
              flex: 2,
              child: Container(
                padding: EdgeInsets.all(Dimenssions.width10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font14,
                        fontWeight: semiBold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Merchant Name
                    if (product.merchant?.name != null)
                      Text(
                        product.merchant!.name,
                        style: secondaryTextStyle.copyWith(
                          fontSize: Dimenssions.font12,
                          fontWeight: medium,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    // Price and Rating Row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          ),
                        ),
                        SizedBox(height: Dimenssions.height4),
                        // Rating and Reviews Count
                        Row(
                          children: [
                            StarRating(
                              rating: product.averageRating,
                              size: Dimenssions.iconSize16,
                            ),
                            SizedBox(width: Dimenssions.width4),
                            Text(
                              '(${product.totalReviews} ulasan)',
                              style: secondaryTextStyle.copyWith(
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
            ),
          ],
        ),
      ),
    );
  }
}
