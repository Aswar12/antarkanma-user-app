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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimenssions.radius12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimenssions.radius12),
          child: AspectRatio(
            aspectRatio: 0.72, // Shopee/TikTok ratio ~ 1:1.4
            child: Stack(
              children: [
                // Full Background Image
                Positioned.fill(
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
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.restaurant_outlined,
                              color: Colors.grey[400],
                              size: 50,
                            ),
                          ),
                  ),
                ),
                // Gradient Overlay (Bottom Only - Like Shopee)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 100, // Fixed height for gradient
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                // Wishlist Button (Top Right - Absolute Position)
                if (product.id != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GetBuilder<WishlistController>(
                      init: Get.find<WishlistController>(),
                      builder: (wishlistCtrl) {
                        return Obx(() {
                          final isFav = wishlistCtrl.isWishlisted(product.id!);
                          return GestureDetector(
                            onTap: () => wishlistCtrl.toggleWishlist(
                              product.id!,
                              product: product,
                            ),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.grey[700],
                                size: 18,
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ),
                // Product Info (Bottom Overlay)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: EdgeInsets.all(Dimenssions.width10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product Name
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: Dimenssions.font13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.6),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 2,
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
                          style: TextStyle(
                            fontSize: Dimenssions.font15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 3,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: Dimenssions.height4),
                        // Rating
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StarRating(
                              rating: product.averageRating,
                              size: Dimenssions.font15,
                              color: Colors.amber,
                            ),
                            SizedBox(width: Dimenssions.width4),
                            Text(
                              '(${product.totalReviews})',
                              style: TextStyle(
                                fontSize: Dimenssions.font10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.6),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
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
        ),
      ),
    );
  }
}
