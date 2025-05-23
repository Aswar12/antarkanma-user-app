import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/services/location_service.dart';
import 'package:antarkanma/app/widgets/profile_image.dart';
import 'package:antarkanma/app/widgets/category_widget.dart';
import 'package:antarkanma/app/widgets/search_input_field.dart';
import 'package:antarkanma/app/widgets/product_carousel_card.dart';
import 'package:antarkanma/app/widgets/merchant_card.dart';
import 'package:antarkanma/app/widgets/home_skeleton_loading.dart';
import 'package:antarkanma/app/widgets/merchant_skeleton_loading.dart';
import 'package:antarkanma/theme.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:antarkanma/app/data/models/product_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  late HomePageController controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final productService = Get.find<ProductService>();
    final merchantService = Get.find<MerchantService>();
    final categoryService = Get.find<CategoryService>();
    final authService = Get.find<AuthService>();
    final locationService = Get.find<LocationService>();

    controller = HomePageController(
      productService: productService,
      merchantService: merchantService,
      categoryService: categoryService,
      authService: authService,
      locationService: locationService,
    );

    // Ensure data is loaded when page is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.allMerchants.isEmpty) {
        controller.loadInitialData();
      }
    });
  }

  Widget _buildProfileWidget() {
    return Obx(() {
      Widget defaultProfileWidget = Container(
        width: Dimenssions.height40,
        height: Dimenssions.height40,
        decoration: BoxDecoration(
          color: backgroundColor3,
          shape: BoxShape.circle,
          border: Border.all(
            color: logoColorSecondary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.person,
          color: secondaryTextColor,
          size: Dimenssions.iconSize20,
        ),
      );

      try {
        final authService = Get.find<AuthService>();
        final user = authService.getUser();
        if (user == null) {
          return defaultProfileWidget;
        }
        return ProfileImage(
          user: user,
          size: Dimenssions.height40,
        );
      } catch (e) {
        debugPrint('Error getting auth service: $e');
        return defaultProfileWidget;
      }
    });
  }

  Future<void> navigateToProductDetail(ProductModel product) async {
    if (product.id == null) {
      Get.snackbar(
        'Error',
        'Data produk tidak valid',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Ensure product data is loaded before navigation
    if (!controller.hasValidData) {
      try {
        Get.snackbar(
          'Loading',
          'Mohon tunggu sebentar...',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 1),
        );
        await controller.loadInitialData();
      } catch (e) {
        Get.snackbar(
          'Error',
          'Gagal memuat data produk',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    Get.toNamed(Routes.productDetail, arguments: product);
  }

  Future<void> _handleRefresh() async {
    try {
      await controller.refreshProducts();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat data. Tarik ke bawah untuk mencoba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  Widget _buildSearchBar() {
    return SearchInputField(
      controller: controller.searchController,
      focusNode: controller.searchFocusNode,
      hintText: 'Cari Merchant...',
      onClear: () {
        controller.searchController.clear();
        controller.searchQuery.value = '';
        FocusManager.instance.primaryFocus?.unfocus();
      },
      onChanged: (value) async {
        controller.searchQuery.value = value;
        if (value.isNotEmpty) {
          await controller.performSearch();
        }
      },
    );
  }

  Widget popularProductsTitle() {
    return Container(
      margin: EdgeInsets.only(
        top: Dimenssions.height15,
        left: Dimenssions.width15,
        right: Dimenssions.width15,
        bottom: Dimenssions.height10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Produk Populer',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font18,
                fontWeight: semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget popularProducts() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          height: Dimenssions.pageView,
          margin: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(Dimenssions.radius15),
          ),
        );
      }

      if (controller.popularProducts.isEmpty) {
        return SizedBox(
          height: Dimenssions.pageView,
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: Dimenssions.iconSize24 * 2,
                    color: secondaryTextColor,
                  ),
                  SizedBox(height: Dimenssions.height10),
                  Text(
                    'Tidak ada produk populer',
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font16,
                      color: secondaryTextColor,
                    ),
                  ),
                  SizedBox(height: Dimenssions.height10),
                  TextButton(
                    onPressed: () => controller.loadPopularProducts(),
                    child: Text(
                      'Muat Ulang',
                      style: primaryTextStyle.copyWith(
                        color: logoColorSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Column(
        children: [
          CarouselSlider.builder(
            itemCount: controller.popularProducts.length,
            options: CarouselOptions(
              height: Dimenssions.pageView,
              viewportFraction: 0.85,
              enlargeCenterPage: true,
              autoPlayCurve: Curves.fastOutSlowIn,
              enlargeStrategy: CenterPageEnlargeStrategy.scale,
              enlargeFactor: 0.15,
              autoPlay: controller.popularProducts.length > 1,
              autoPlayInterval: const Duration(seconds: 3),
              onPageChanged: (index, reason) {
                controller.updateCurrentIndex(index);
              },
              padEnds: true,
            ),
            itemBuilder: (context, index, realIndex) {
              final product = controller.popularProducts[index];
              return ProductCarouselCard(
                product: product,
                onTap: () => navigateToProductDetail(product),
              );
            },
          ),
          SizedBox(height: Dimenssions.height10),
          Obx(() => AnimatedSmoothIndicator(
                activeIndex: controller.currentIndex.value,
                count: controller.popularProducts.length,
                effect: WormEffect(
                  activeDotColor: logoColorSecondary,
                  dotColor: secondaryTextColor.withOpacity(0.2),
                  dotHeight: Dimenssions.height10,
                  dotWidth: Dimenssions.height10,
                  type: WormType.thin,
                ),
              )),
        ],
      );
    });
  }

  Widget merchantListTitle() {
    return Container(
      margin: EdgeInsets.only(
        top: Dimenssions.height15,
        left: Dimenssions.width15,
        right: Dimenssions.width15,
        bottom: Dimenssions.height10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              controller.searchQuery.isEmpty
                  ? 'Semua Merchant'
                  : 'Hasil Pencarian',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font18,
                fontWeight: semiBold,
              ),
            ),
          ),
          if (!controller.isLoading.value && controller.allMerchants.isNotEmpty)
            TextButton(
              onPressed: _handleRefresh,
              child: Text(
                'Segarkan',
                style: primaryTextStyle.copyWith(
                  color: logoColorSecondary,
                  fontSize: Dimenssions.font14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildMerchantSlivers() {
    if (controller.isLoading.value) {
      return [
        const SliverToBoxAdapter(
          child: MerchantSkeletonLoading(),
        ),
      ];
    }

    if (controller.filteredMerchants.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(Dimenssions.height20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    controller.searchQuery.isEmpty
                        ? Icons.store_outlined
                        : Icons.search_off_outlined,
                    size: Dimenssions.iconSize24 * 2,
                    color: secondaryTextColor,
                  ),
                  SizedBox(height: Dimenssions.height10),
                  Text(
                    controller.searchQuery.isEmpty
                        ? 'Tidak ada merchant'
                        : 'Tidak ada merchant ditemukan',
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font16,
                      color: secondaryTextColor,
                    ),
                  ),
                  if (controller.searchQuery.isEmpty) ...[
                    SizedBox(height: Dimenssions.height10),
                    TextButton(
                      onPressed: () => controller.loadAllMerchants(),
                      child: Text(
                        'Muat Ulang',
                        style: primaryTextStyle.copyWith(
                          color: logoColorSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
        sliver: SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            mainAxisSpacing: Dimenssions.height10,
            crossAxisSpacing: Dimenssions.width10,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final merchant = controller.filteredMerchants[index];

              if (index >= controller.filteredMerchants.length - 3 &&
                  !controller.isLoadingMore.value &&
                  controller.hasMoreData.value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.loadMoreMerchants();
                });
              }

              return MerchantCard(merchant: merchant);
            },
            childCount: controller.filteredMerchants.length,
          ),
        ),
      ),
      if (controller.isLoadingMore.value)
        const SliverToBoxAdapter(
          child: MerchantSkeletonLoading(),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Obx(() {
      if (controller.isLoading.value && controller.searchQuery.isEmpty) {
        return const SafeArea(
          child: Scaffold(
            body: HomeSkeletonLoading(),
          ),
        );
      }

      return Scaffold(
        backgroundColor: backgroundColor1,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: logoColorSecondary,
            child: CustomScrollView(
              controller: controller.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  backgroundColor: backgroundColor1,
                  floating: true,
                  pinned: true,
                  elevation: 0,
                  toolbarHeight: kToolbarHeight,
                  title: Container(
                    margin: EdgeInsets.symmetric(vertical: Dimenssions.height2),
                    child: Row(
                      children: [
                        Expanded(child: _buildSearchBar()),
                        SizedBox(width: Dimenssions.width10),
                        _buildProfileWidget(),
                      ],
                    ),
                  ),
                ),
                if (controller.searchQuery.isEmpty) ...[
                  SliverToBoxAdapter(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        popularProductsTitle(),
                        popularProducts(),
                        SizedBox(height: Dimenssions.height10),
                      ],
                    ),
                  ),
                ],
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    minHeight: Dimenssions.height45,
                    maxHeight: Dimenssions.height45,
                    child: Container(
                      color: backgroundColor1,
                      alignment: Alignment.center,
                      child: const CategoryWidget(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: merchantListTitle(),
                ),
                ..._buildMerchantSlivers(),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
