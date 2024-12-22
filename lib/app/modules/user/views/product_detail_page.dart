// ignore_for_file: unused_local_variable, unused_catch_stack, empty_catches, deprecated_member_use, constant_identifier_names

import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/data/models/cart_item_model.dart';
import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/data/models/variant_model.dart';
import 'package:antarkanma/app/utils/image_viewer_page.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/app/widgets/product_review_section.dart';
import 'package:antarkanma/app/widgets/profile_image.dart';
import 'package:antarkanma/app/widgets/quantity_button.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:antarkanma/app/controllers/product_detail_controller.dart';
import 'package:antarkanma/app/data/models/product_model.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({Key? key}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ProductDetailController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProductDetailController>();
    _initializeDateFormatting();
    final product = Get.arguments as ProductModel;
    controller.setProduct(product);
  }

  void _addToCart() {
    try {
      if (!controller.validateCheckout()) {
        return;
      }

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
      cartController.addToCart(
        controller.product.value,
        controller.quantity.value,
        selectedVariant: controller.selectedVariant.value,
        merchant: merchant,
      );

      showCustomSnackbar(
        title: 'Berhasil',
        message: 'Produk berhasil ditambahkan ke keranjang',
        backgroundColor: Colors.green,
        snackPosition: SnackPosition.BOTTOM,
      );
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
      if (!controller.validateCheckout()) {
        return;
      }

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
    return GetBuilder<ProductDetailController>(
      builder: (controller) {
        return Scaffold(
          backgroundColor: backgroundColor1,
          body: WillPopScope(
            onWillPop: () async {
              Get.back();
              return false;
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(controller.product.value),
                SliverPadding(
                  padding: EdgeInsets.zero,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildProductInfo(controller.product.value),
                            _buildVariantSelector(controller.product.value),
                            _buildMerchantInfo(controller.product.value),
                            _buildReviewSection(),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildSliverAppBar(ProductModel product) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(Get.context!).size.width,
      floating: false,
      pinned: true,
      backgroundColor: backgroundColor1,
      elevation: 0,
      stretch: true,
      stretchTriggerOffset: 150,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(Dimenssions.height8),
          decoration: BoxDecoration(
            color: backgroundColor1.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: logoColorSecondary),
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        Obx(() {
          final cartController = Get.find<CartController>();
          final itemCount = cartController.itemCount;

          return Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                margin: EdgeInsets.all(Dimenssions.height8),
                padding: EdgeInsets.all(Dimenssions.height8),
                decoration: BoxDecoration(
                  color: backgroundColor1.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.shopping_cart, color: logoColorSecondary),
                  onPressed: () => Get.toNamed('/cart'),
                ),
              ),
              if (itemCount > 0)
                Positioned(
                  right: Dimenssions.width8,
                  top: Dimenssions.height8,
                  child: Container(
                    padding: EdgeInsets.all(Dimenssions.height4),
                    decoration: BoxDecoration(
                      color: alertColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: Dimenssions.width18,
                      minHeight: Dimenssions.height18,
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: TextStyle(
                        color: backgroundColor1,
                        fontSize: Dimenssions.font10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return FlexibleSpaceBar(
            stretchModes: const [
              StretchMode.zoomBackground,
              StretchMode.blurBackground,
            ],
            background: Container(
              height: constraints.maxHeight,
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: _buildImageSlider(),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: Dimenssions.height30,
                        decoration: BoxDecoration(
                          color: backgroundColor1,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(Dimenssions.radius30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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
                height: double.infinity,
                viewportFraction: 1.0,
                enlargeCenterPage: false,
                autoPlay: displayImages.length > 1,
                autoPlayInterval: const Duration(seconds: 3),
                onPageChanged: (index, _) {
                  controller.updateImageIndex(index);
                },
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
      child: Hero(
        tag: 'product_image_${uniqueId}_$index',
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor3,
          ),
          child: _buildImage(imageUrl),
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
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            color: logoColorSecondary,
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
      color: backgroundColor3,
      child: Center(
        child: Icon(
          Icons.error_outline,
          color: alertColor,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildImageIndicator(int imageCount) {
    return Positioned(
      bottom: Dimenssions.height40,
      left: 0,
      right: 0,
      child: Obx(() {
        final currentIndex = controller.currentImageIndex.value;
        return Center(
          child: AnimatedSmoothIndicator(
            activeIndex: currentIndex,
            count: imageCount,
            effect: ExpandingDotsEffect(
              dotWidth: Dimenssions.width8,
              dotHeight: Dimenssions.height8,
              spacing: Dimenssions.width6,
              activeDotColor: logoColorSecondary,
              dotColor: backgroundColor1.withOpacity(0.5),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProductInfo(ProductModel product) {
    return Padding(
      padding: EdgeInsets.all(Dimenssions.height20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font16, // Updated size
                        fontWeight: semiBold,
                      ),
                    ),
                    SizedBox(height: Dimenssions.height8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimenssions.width12,
                        vertical: Dimenssions.height6,
                      ),
                      decoration: BoxDecoration(
                        color: logoColorSecondary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(Dimenssions.radius20),
                      ),
                      child: Text(
                        product.category?.name ?? 'No Category',
                        style: primaryTextOrange.copyWith(
                          fontWeight: medium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimenssions.width12,
                  vertical: Dimenssions.height6,
                ),
                decoration: BoxDecoration(
                  color: product.status == 'ACTIVE'
                      ? Colors.green.withOpacity(0.1)
                      : alertColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimenssions.radius20),
                ),
                child: Text(
                  product.status ?? 'Habis',
                  style: TextStyle(
                    color:
                        product.status == 'ACTIVE' ? Colors.green : alertColor,
                    fontWeight: medium,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimenssions.height16),
          Obx(() {
            final total = controller.totalPrice;
            return Text(
              'Rp ${NumberFormat('#,###', 'id_ID').format(total)}',
              style: priceTextStyle.copyWith(
                fontSize: Dimenssions.font20, // Updated size
                fontWeight: semiBold,
              ),
            );
          }),
          SizedBox(height: Dimenssions.height24),
          Text(
            'Deskripsi Produk',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font16, // Updated size
              fontWeight: semiBold,
            ),
          ),
          SizedBox(height: Dimenssions.height8),
          Text(
            product.description,
            style: secondaryTextStyle.copyWith(
              height: 1.5,
              fontSize: Dimenssions.font16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSelector(ProductModel product) {
    if (product.variants.isEmpty) return const SizedBox();

    // Group variants by name
    final variantGroups = <String, List<VariantModel>>{};
    for (var variant in product.variants) {
      if (!variantGroups.containsKey(variant.name)) {
        variantGroups[variant.name] = [];
      }
      variantGroups[variant.name]!.add(variant);
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Dimenssions.width20,
        vertical: Dimenssions.height10,
      ),
      padding: EdgeInsets.all(Dimenssions.height16),
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: BorderRadius.circular(Dimenssions.radius12),
        border: Border.all(color: backgroundColor3.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pilih Varian',
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font16,
                  fontWeight: semiBold,
                ),
              ),
              SizedBox(width: Dimenssions.width8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimenssions.width8,
                  vertical: Dimenssions.height4,
                ),
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimenssions.radius8),
                ),
                child: Text(
                  'Wajib',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font12,
                    color: alertColor,
                    fontWeight: medium,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimenssions.height16),
          ...variantGroups.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: secondaryTextStyle.copyWith(
                    fontSize: Dimenssions.font14,
                  ),
                ),
                SizedBox(height: Dimenssions.height8),
                Wrap(
                  spacing: Dimenssions.width8,
                  runSpacing: Dimenssions.height8,
                  children: entry.value.map((variant) {
                    return Obx(() {
                      final isSelected =
                          controller.selectedVariant.value?.id == variant.id;
                      return GestureDetector(
                        onTap: () => controller.selectVariant(variant),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimenssions.width12,
                            vertical: Dimenssions.height8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? logoColorSecondary
                                : backgroundColor1,
                            border: Border.all(
                              color: isSelected
                                  ? logoColorSecondary
                                  : backgroundColor3,
                              width: 1.5,
                            ),
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                variant.value,
                                style: TextStyle(
                                  fontSize: Dimenssions.font14,
                                  color: isSelected
                                      ? backgroundColor1
                                      : primaryTextColor,
                                  fontWeight: medium,
                                ),
                              ),
                              if (variant.priceAdjustment > 0) ...[
                                SizedBox(width: Dimenssions.width4),
                                Text(
                                  '+${NumberFormat('#,###', 'id_ID').format(variant.priceAdjustment)}',
                                  style: TextStyle(
                                    fontSize: Dimenssions.font12,
                                    color: isSelected
                                        ? backgroundColor1
                                        : logoColorSecondary,
                                    fontWeight: medium,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    });
                  }).toList(),
                ),
                SizedBox(height: Dimenssions.height12),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMerchantInfo(ProductModel product) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Dimenssions.width20,
        vertical: Dimenssions.height10,
      ),
      padding: EdgeInsets.all(Dimenssions.height20),
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: BorderRadius.circular(Dimenssions.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Dimenssions.height12),
                decoration: BoxDecoration(
                  color: logoColorSecondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.store,
                  color: logoColorSecondary,
                  size: 24,
                ),
              ),
              SizedBox(width: Dimenssions.width16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.merchant?.name ?? 'Unknown Merchant',
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font16,
                        fontWeight: semiBold,
                      ),
                    ),
                    SizedBox(height: Dimenssions.height4),
                    Text(
                      product.merchant?.address ?? 'No address available',
                      style: secondaryTextStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Dimenssions.height16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final merchant = controller.product.value.merchant;
                    if (merchant != null) {
                      Get.toNamed('/chat', arguments: {
                        'merchantId': merchant.id,
                        'merchantName': merchant.name,
                      });
                    }
                  },
                  icon: Icon(Icons.chat_outlined, color: logoColorSecondary),
                  label: Text(
                    'Chat Penjual',
                    style: primaryTextOrange,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: logoColorSecondary,
                    side: BorderSide(color: logoColorSecondary),
                    padding:
                        EdgeInsets.symmetric(vertical: Dimenssions.height12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimenssions.radius12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: Dimenssions.width12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.phone_outlined, color: logoColorSecondary),
                  label: Text(
                    'Hubungi',
                    style: primaryTextOrange,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: logoColorSecondary,
                    side: BorderSide(color: logoColorSecondary),
                    padding:
                        EdgeInsets.symmetric(vertical: Dimenssions.height12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimenssions.radius12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return ProductReviewSection(controller: controller);
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: EdgeInsets.all(Dimenssions.height15),
      decoration: BoxDecoration(
        color: backgroundColor1,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Row(
              children: [
                QuantityButton(
                  icon: Icons.remove,
                  onTap: () => controller.decrementQuantity(),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: Dimenssions.width12),
                  child: Obx(() => Text(
                        controller.quantity.value.toString(),
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font14,
                          fontWeight: semiBold,
                        ),
                      )),
                ),
                QuantityButton(
                  icon: Icons.add,
                  onTap: () => controller.incrementQuantity(),
                ),
              ],
            ),
            SizedBox(width: Dimenssions.width12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.quantity.value > 0
                          ? () => _addToCart()
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: logoColorSecondary,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                            vertical: Dimenssions.height16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimenssions.radius12),
                          side: BorderSide(color: logoColorSecondary),
                        ),
                      ),
                      child: Text(
                        'Keranjang',
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font16,
                          fontWeight: semiBold,
                          color: logoColorSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Dimenssions.width12),
                  Expanded(
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: logoColorSecondary,
                        padding: EdgeInsets.symmetric(
                            vertical: Dimenssions.height16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimenssions.radius12),
                        ),
                      ),
                      child: Text(
                        'Beli Sekarang',
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font16,
                          fontWeight: semiBold,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
