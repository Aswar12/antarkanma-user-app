import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/wishlist_controller.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/widgets/cached_image_view.dart';
import 'package:antarkanma/theme.dart';
import 'package:intl/intl.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final WishlistController controller = Get.find<WishlistController>();

    return Scaffold(
      backgroundColor: backgroundColor1,
      appBar: AppBar(
        backgroundColor: backgroundColor1,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryTextColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Favorit Saya',
          style: primaryTextStyle.copyWith(
            fontSize: 18,
            fontWeight: semiBold,
          ),
        ),
        centerTitle: true,
        actions: [
          Obx(() {
            if (controller.wishlistProducts.isEmpty) return const SizedBox();
            return IconButton(
              icon: Icon(Icons.delete_sweep_outlined, color: Colors.red[400]),
              onPressed: () => _showClearConfirmation(controller),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.wishlistProducts.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchWishlist(),
          child: GridView.builder(
            padding: EdgeInsets.all(Dimenssions.width15),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: Dimenssions.width10,
              mainAxisSpacing: Dimenssions.height10,
              childAspectRatio: 0.65,
            ),
            itemCount: controller.wishlistProducts.length,
            itemBuilder: (context, index) {
              final product = controller.wishlistProducts[index];
              return _buildWishlistCard(product, controller);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada favorit',
            style: primaryTextStyle.copyWith(
              fontSize: 18,
              fontWeight: semiBold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap ikon ❤️ pada produk untuk\nmenyimpan ke favorit',
            textAlign: TextAlign.center,
            style: secondaryTextStyle.copyWith(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.explore, color: Colors.white),
            label: const Text('Jelajahi Produk',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: logoColorSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistCard(
      ProductModel product, WishlistController controller) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          Routes.productDetail,
          arguments: product,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor2,
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(Dimenssions.radius15),
                      topRight: Radius.circular(Dimenssions.radius15),
                    ),
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
                  // Remove from wishlist button
                  if (product.id != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => controller.toggleWishlist(
                          product.id!,
                          product: product,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Details Section
            Expanded(
              flex: 2,
              child: Padding(
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
                    if (product.merchant?.name != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.merchant!.name,
                        style: secondaryTextStyle.copyWith(
                          fontSize: Dimenssions.font12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          product.averageRating.toStringAsFixed(1),
                          style: secondaryTextStyle.copyWith(
                            fontSize: Dimenssions.font12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.totalReviews})',
                          style: secondaryTextStyle.copyWith(
                            fontSize: Dimenssions.font12,
                            color: Colors.grey[400],
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
    );
  }

  void _showClearConfirmation(WishlistController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Semua Favorit?'),
        content:
            const Text('Semua produk favorit akan dihapus dari daftar Anda.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // Remove all items one by one
              final ids = List<int>.from(
                controller.wishlistProducts.map((p) => p.id).whereType<int>(),
              );
              for (final id in ids) {
                controller.toggleWishlist(id);
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
