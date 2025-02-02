import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/data/models/cart_item_model.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/app/widgets/product_review_section.dart';
import 'package:antarkanma/app/widgets/merchant_info_section.dart';
import 'package:antarkanma/app/widgets/product_info_section.dart';
import 'package:antarkanma/app/widgets/variant_selector_section.dart';
import 'package:antarkanma/app/widgets/product_image_slider.dart';
import 'package:antarkanma/app/widgets/product_bottom_nav.dart';
import 'package:antarkanma/app/widgets/cart_button.dart';
import 'package:antarkanma/app/widgets/back_button.dart';
import 'package:antarkanma/app/widgets/curved_bottom_decoration.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:antarkanma/app/controllers/product_detail_controller.dart';
import 'package:antarkanma/app/data/models/product_model.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({Key? key}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late ProductDetailController controller;
  late CartController cartController;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProductDetailController>();
    // Initialize CartController if not already initialized
    if (!Get.isRegistered<CartController>()) {
      Get.put(CartController());
    }
    cartController = Get.find<CartController>();
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
      if (merchant == null) return;

      cartController.addToCart(
        controller.product.value,
        controller.quantity.value,
        selectedVariant: controller.selectedVariant.value,
        merchant: merchant,
      );
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Terjadi kesalahan saat menambahkan ke keranjang',
        backgroundColor: Colors.red,
      );
    }
  }

  void _buyNow() {
    try {
      if (!controller.validateCheckout()) {
        return;
      }

      final merchant = controller.product.value.merchant;
      if (merchant == null || merchant.id == null) {
        showCustomSnackbar(
          title: 'Error',
          message: 'Data merchant tidak valid',
          backgroundColor: Colors.red,
        );
        return;
      }

      final Map<int, List<CartItemModel>> merchantItems = {
        merchant.id!: [
          CartItemModel(
            product: controller.product.value,
            merchant: merchant,
            quantity: controller.quantity.value,
            selectedVariant: controller.selectedVariant.value,
          )
        ]
      };

      Get.toNamed(Routes.userCheckout, arguments: {
        'merchantItems': merchantItems,
        'type': 'direct_buy',
      });
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Terjadi kesalahan saat memproses pembelian',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _initializeDateFormatting() async {
    try {
      await initializeDateFormatting('id_ID', null);
    } catch (e) {}
  }

  void _navigateToCart() {
    Get.back(); // Go back to UserMainPage
    // Get UserMainController and change to cart tab (index 1)
    final userMainController = Get.find<UserMainController>();
    userMainController.changePage(1);
  }

  @override
  Widget build(BuildContext context) {
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
                _buildSliverAppBar(context),
                SliverPadding(
                  padding: EdgeInsets.zero,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Container(
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Obx(() => ProductInfoSection(
                                  product: controller.product.value,
                                  totalPrice: controller.totalPrice,
                                )),
                            Obx(() => VariantSelectorSection(
                                  product: controller.product.value,
                                  selectedVariant:
                                      controller.selectedVariant.value,
                                  onVariantSelected: controller.selectVariant,
                                )),
                            MerchantInfoSection(
                                product: controller.product.value),
                            ProductReviewSection(controller: controller),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Obx(() => ProductBottomNav(
                quantity: controller.quantity.value,
                onDecrement: controller.decrementQuantity,
                onIncrement: controller.incrementQuantity,
                onAddToCart: _addToCart,
                onBuyNow: _buyNow,
                isProductActive: controller.product.value.status == 'ACTIVE',
              )),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.width,
      floating: false,
      pinned: true,
      backgroundColor: backgroundColor1,
      elevation: 0,
      stretch: true,
      stretchTriggerOffset: 150,
      leading: CustomBackButton(
        onPressed: () => Get.back(),
        backgroundColor: backgroundColor1,
      ),
      actions: [
        Obx(() => CartButton(
              itemCount: cartController.itemCount,
              onPressed: _navigateToCart,
              backgroundColor: backgroundColor1,
            )),
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
                      child: Obx(() => ProductImageSlider(
                            imageUrls: controller.product.value.imageUrls,
                            currentIndex: controller.currentImageIndex.value,
                            onPageChanged: controller.updateImageIndex,
                            productId: controller.product.value.id.toString(),
                          )),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: CurvedBottomDecoration(
                        height: Dimenssions.height30,
                        color: backgroundColor1,
                        radius: Dimenssions.radius30,
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
}
