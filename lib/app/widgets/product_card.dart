import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/controllers/wishlist_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:get/get.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: Dimenssions.width100 * 1.5,
        margin: EdgeInsets.only(right: Dimenssions.width15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(Dimenssions.radius15),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: product.firstImageUrl,
                    height: Dimenssions.height100 * 1.2,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  // Wishlist Heart Icon
                  if (product.id != null)
                    Positioned(
                      top: 8,
                      left: 8,
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
                                  color: isFav ? Colors.red : Colors.grey,
                                  size: Dimenssions.iconSize16,
                                ),
                              ),
                            );
                          });
                        },
                      ),
                    ),
                  if (product.averageRating > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimenssions.width5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(Dimenssions.radius15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: primaryOrange,
                              size: Dimenssions.iconSize16,
                            ),
                            SizedBox(width: 2),
                            Text(
                              product.averageRating.toStringAsFixed(1),
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font12,
                                fontWeight: semiBold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(Dimenssions.width10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font14,
                      fontWeight: semiBold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Dimenssions.height5),
                  Text(
                    product.formattedPrice,
                    style: priceTextStyle.copyWith(
                      fontSize: Dimenssions.font14,
                      fontWeight: bold,
                    ),
                  ),
                  SizedBox(height: Dimenssions.height5),
                  if (product.merchant != null)
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          color: secondaryTextColor,
                          size: Dimenssions.iconSize16,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            product.merchant!.name,
                            style: secondaryTextStyle.copyWith(
                              fontSize: Dimenssions.font12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    );
  }
}
