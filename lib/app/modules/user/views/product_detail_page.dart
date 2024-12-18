// ignore_for_file: unused_local_variable, unused_catch_stack, empty_catches, deprecated_member_use, constant_identifier_names

import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/data/models/cart_item_model.dart';
import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/utils/image_viewer_page.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/app/widgets/profile_image.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:antarkanma/app/controllers/product_detail_controller.dart';
import 'package:antarkanma/app/data/models/product_model.dart';

class ProductDetailPage extends GetView<ProductDetailController> {
  const ProductDetailPage({super.key});
  void _addToCart() {
    try {
      final merchant = controller.product.value.merchant;
      if (merchant == null) {
        showCustomSnackbar(
          title: 'Error',
          message: 'Data merchant tidak valid',
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final cartController = Get.find<CartController>();

      // Langsung menambahkan ke keranjang tanpa pengecekan canAddFromMerchant
      cartController.addToCart(
        controller.product.value,
        controller.quantity.value,
        selectedVariant: controller.selectedVariant.value,
        merchant: merchant,
      );

      // Pesan sukses sudah ditangani di dalam addToCart, jadi tidak perlu ditambahkan di sini
    } catch (e, stackTrace) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Terjadi kesalahan saat menambahkan ke keranjang',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _buyNow() {
    try {
      final merchant = controller.product.value.merchant;
      if (merchant == null) {
        showCustomSnackbar(
          title: 'Error',
          message: 'Data merchant tidak valid',
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Create a map structure similar to merchantItems in cart
      final merchantId = merchant.id;
      if (merchantId == null) {
        showCustomSnackbar(
          title: 'Error',
          message: 'ID merchant tidak valid',
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final Map<int, List<CartItemModel>> merchantItems = {
        merchantId: [
          CartItemModel(
            product: controller.product.value,
            merchant: merchant,
            quantity: controller.quantity.value,
            selectedVariant: controller.selectedVariant.value,
          )
        ]
      };

      Get.toNamed('/main/checkout', arguments: {
        'merchantItems': merchantItems,
        'type': 'direct_buy',
      });
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Terjadi kesalahan saat memproses pembelian',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    _initializeDateFormatting();
    final product = Get.arguments as ProductModel;

    controller.setProduct(product);

    return GetBuilder<ProductDetailController>(
      // Ganti Obx dengan GetBuilder
      builder: (controller) {
        return Scaffold(
          backgroundColor: backgroundColor5,
          appBar: _buildAppBar(controller.product.value),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildImageSlider(),
                _buildProductInfo(controller.product.value),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  // AppBar Widget
  AppBar _buildAppBar(ProductModel product) {
    return AppBar(
      title: Text(
        product.name,
        style: priceTextStyle.copyWith(fontSize: Dimenssions.font24),
      ),
      centerTitle: true,
      backgroundColor: transparentColor,
      leading: IconButton(
        color: logoColorSecondary,
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
      actions: [
        Obx(() {
          final cartController = Get.find<CartController>();
          final itemCount = cartController.itemCount;

          return Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: Icon(
                  Icons.shopping_cart,
                  color: logoColorSecondary,
                ),
                onPressed: () {
                  try {
                    Get.toNamed('/cart');
                  } catch (e) {
                    showCustomSnackbar(
                      title: 'Error',
                      message: 'Tidak dapat membuka keranjang',
                      backgroundColor: Colors.red,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
              ),
              if (itemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReviewHeader(),
          const SizedBox(height: 16),
          _buildReviewList(),
        ],
      ),
    );
  }

  Widget _buildReviewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ulasan Produk',
              style: TextStyle(
                color: primaryTextColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Obx(() {
              final averageRating = controller.product.value.averageRating;
              return Row(
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < averageRating.floor()
                            ? Icons.star
                            : index < averageRating
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: Dimenssions.font14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
        Obx(() {
          final reviewCount = controller.product.value.reviews?.length ?? 0;
          return Text(
            '$reviewCount ${reviewCount == 1 ? 'Ulasan' : 'Ulasan'}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: Dimenssions.font14,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReviewList() {
    return Obx(() {
      final reviews = controller.product.value.reviews;

      if (reviews == null || reviews.isEmpty) {
        return _buildEmptyReviewState();
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: reviews.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.grey[200],
          height: 24,
          thickness: 1,
        ),
        itemBuilder: (context, index) => _buildReviewItem(reviews[index]),
      );
    });
  }

  Widget _buildEmptyReviewState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Belum ada ulasan untuk produk ini.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: Dimenssions.font14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jadilah yang pertama memberikan ulasan!',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: Dimenssions.font12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(ProductReviewModel review) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewerAvatar(review),
              const SizedBox(width: 12),
              Expanded(
                child: _buildReviewContent(review),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewerAvatar(ProductReviewModel review) {
    final user = review.user;
    if (user == null) {
      // Jika user null, tampilkan avatar default
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
        ),
        child: Icon(
          Icons.person,
          color: Colors.grey[400],
        ),
      );
    }

    // Jika user tidak null, gunakan ProfileImage
    return ProfileImage(
      user: user,
      size: 40, // Anda bisa menyesuaikan ukuran sesuai kebutuhan
    );
  }

  Widget _buildReviewContent(ProductReviewModel review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              review.user?.name ?? 'Pengguna',
              style: TextStyle(
                fontSize: Dimenssions.font16,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
            Text(
              _formatDate(review.createdAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: Dimenssions.font12,
              ),
            ),
          ],
        ),
        SizedBox(height: Dimenssions.height5),
        Text(
          review.comment,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: Dimenssions.font14,
            height: 1.5,
          ),
        ),
        Row(
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 16,
              );
            }),
            SizedBox(width: Dimenssions.height5),
            Text(
              '${review.rating}/5',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: Dimenssions.font12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} menit yang lalu';
      }
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    }
  }

  Widget _buildVariantSelector(ProductModel product) {
    if (product.variants.isEmpty) return const SizedBox();

    return Container(
      margin: EdgeInsets.symmetric(vertical: Dimenssions.height15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Varian',
            style: primaryTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Dimenssions.height10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: product.variants.map((variant) {
              return Obx(() => GestureDetector(
                    onTap: () => controller.selectVariant(variant),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimenssions.width10,
                        vertical: Dimenssions.height5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            controller.selectedVariant.value?.id == variant.id
                                ? logoColorSecondary
                                : Colors.white,
                        border: Border.all(
                          color:
                              controller.selectedVariant.value?.id == variant.id
                                  ? logoColorSecondary
                                  : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: Dimenssions.height20,
                            width: Dimenssions.width55,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  variant.name,
                                  style: TextStyle(
                                    fontSize: Dimenssions.font16,
                                    color:
                                        controller.selectedVariant.value?.id ==
                                                variant.id
                                            ? Colors.white
                                            : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  variant.value,
                                  style: TextStyle(
                                    fontSize: Dimenssions.font16,
                                    color:
                                        controller.selectedVariant.value?.id ==
                                                variant.id
                                            ? Colors.white
                                            : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '+ Rp ${variant.priceAdjustment}',
                            style: TextStyle(
                              color: controller.selectedVariant.value?.id ==
                                      variant.id
                                  ? Colors.white
                                  : logoColorSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ));
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimenssions.width20,
        vertical: Dimenssions.height10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), // Membuat transparan

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            _buildChatButton(),
            SizedBox(width: Dimenssions.width10),
            _buildBuyNowButton(),
          ],
        ),
      ),
    );
  }

  // Chat Button
  Widget _buildChatButton() {
    return Container(
      width: Dimenssions.width45,
      height: Dimenssions.height45,
      decoration: BoxDecoration(
        border: Border.all(color: logoColorSecondary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.chat, color: logoColorSecondary, size: 20),
        onPressed: () {
          final merchant = controller.product.value.merchant;
          if (merchant != null) {
            Get.toNamed('/chat', arguments: {
              'merchantId': merchant.id,
              'merchantName': merchant.name,
            });
          }
        },
      ),
    );
  }

  // Buy Now Button
  Widget _buildBuyNowButton() {
    return Expanded(
      child: SizedBox(
        height: Dimenssions.height45,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.quantity.value > 0
                ? logoColorSecondary
                : Colors.grey,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: controller.quantity.value > 0
              ? () {
                  if (controller.product.value.status != 'ACTIVE') {
                    Get.snackbar(
                      'Tidak Tersedia',
                      'Produk ini sedang tidak tersedia',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  _buyNow();
                }
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart_checkout,
                  color: Colors.white, size: 18),
              SizedBox(width: Dimenssions.width10),
              Text(
                'Beli Sekarang',
                style: primaryTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Image Indicator
  // Image Slider
  static const List<String> PLACEHOLDER_IMAGES = [
    'assets/image_shoes.png',
    'assets/image_shoes2.png',
    'assets/image_shoes3.png',
  ];

  Widget _buildImageSlider() {
    return GetBuilder<ProductDetailController>(
      builder: (controller) {
        final product = controller.product.value;
        final List<String> displayImages =
            product.imageUrls.isEmpty ? PLACEHOLDER_IMAGES : product.imageUrls;

        return Stack(
          children: [
            CarouselSlider.builder(
              itemCount: displayImages.length,
              options: CarouselOptions(
                height: Dimenssions.height240,
                viewportFraction: 0.7,
                enlargeCenterPage: true,
                autoPlayCurve: Curves.fastOutSlowIn,
                enlargeStrategy: CenterPageEnlargeStrategy.scale,
                enlargeFactor: 0.2,
                autoPlay: displayImages.length > 1,
                autoPlayInterval: const Duration(seconds: 3),
                onPageChanged: (index, _) {
                  controller.updateImageIndex(index);
                },
                padEnds: true,
              ),
              itemBuilder: (context, index, realIndex) {
                return _buildImageSliderItem(
                  imageUrl: displayImages[index],
                  index: index,
                  displayImages: displayImages,
                );
              },
            ),
            _buildImageIndicator(displayImages.length),
          ],
        );
      },
      id: 'image-slider',
    );
  }

  Widget _buildImageSliderItem({
    required String imageUrl,
    required int index,
    required List<String> displayImages,
  }) {
    final String uniqueId =
        '${controller.product.value.id}_${DateTime.now().millisecondsSinceEpoch}';

    return GestureDetector(
      onTap: () {
        Get.to(
          () => ImageViewerPage(
            imageUrls: displayImages,
            initialIndex: index,
            heroTagPrefix: uniqueId,
          ),
          transition: Transition.zoom,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey[200],
        ),
        child: Hero(
          tag: 'product_image_${uniqueId}_$index',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: _buildImage(imageUrl),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return imageUrl.startsWith('assets/')
        ? _buildAssetImage(imageUrl)
        : _buildNetworkImage(imageUrl);
  }

  Widget _buildAssetImage(String imageUrl) {
    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 40,
        ),
      ),
    );
  }

// Image Indicator
  Widget _buildImageIndicator(int imageCount) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Obx(() {
        final currentIndex = controller.currentImageIndex.value;
        return Center(
          child: AnimatedSmoothIndicator(
            activeIndex: currentIndex,
            count: imageCount,
            effect: WormEffect(
                dotWidth: 11,
                dotHeight: 11,
                spacing: 10,
                strokeWidth: 1,
                dotColor: Colors.grey.shade400,
                activeDotColor: logoColorSecondary,
                paintStyle: PaintingStyle.stroke,
                type: WormType.thinUnderground,
                offset: 1),
          ),
        );
      }),
    );
  }

  // Product Information
  Widget _buildProductInfo(ProductModel product) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(product),
          const SizedBox(height: 8),
          _buildPriceAndCategory(product),
          _buildDescription(product),
          _buildVariantSelector(product),
          SizedBox(height: Dimenssions.height25),
          _buildMerchantInfo(product),
          _buildReviewSection(),
          SizedBox(height: Dimenssions.height20),
          _buildQuantityAndCart(product),
          // Tambahkan jarak
        ],
      ),
    );
  }

  // Product Header
  Widget _buildProductHeader(ProductModel product) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            product.name,
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.height30,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: product.status == 'ACTIVE'
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            product.status ?? 'Habis',
            style: TextStyle(
              color: product.status == 'ACTIVE' ? Colors.green : Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  // Price and Category
  Widget _buildPriceAndCategory(ProductModel product) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Obx(() {
          final total = controller.totalPrice;
          return Text(
            'Rp ${total.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              color: logoColorSecondary,
              fontWeight: FontWeight.bold,
            ),
          );
        }),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: logoColorSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            product.category?.name ?? 'No Category',
            style: TextStyle(
              color: logoColorSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Description
  Widget _buildDescription(ProductModel product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deskripsi Produk',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.description,
          style: TextStyle(
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // Merchant Information
  Widget _buildMerchantInfo(ProductModel product) {
    return Container(
      padding: EdgeInsets.all(Dimenssions.height22),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Toko',
            style: TextStyle(
              fontSize: 18,
              color: primaryTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.store, color: logoColorSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.merchant?.name ?? 'Unknown Merchant',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, color: logoColorSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.merchant?.address ?? 'No address available',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone, color: logoColorSecondary),
              const SizedBox(width: 8),
              Text(
                product.merchant?.phoneNumber ?? 'No phone number',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Quantity and Add to Cart Button
  Widget _buildQuantityAndCart(ProductModel product) {
    return Row(
      children: [
        _buildQuantitySelector(),
        SizedBox(width: Dimenssions.width10),
        Expanded(
          child: SizedBox(
            height: Dimenssions.height45,
            child: ElevatedButton(
              onPressed: () {
                _addToCart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: logoColorSecondary,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tambah ke Keranjang',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Quantity Selector
  Widget _buildQuantitySelector() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Text(
            'Jumlah:',
            style: primaryTextStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: Dimenssions.width10),
          Row(
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onTap: () => controller.decrementQuantity(),
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
                child: Obx(() => Text(
                      controller.quantity.value.toString(),
                      style: primaryTextStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    )),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onTap: () => controller.incrementQuantity(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Quantity Button
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: logoColorSecondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: logoColorSecondary,
        ),
      ),
    );
  }
}
