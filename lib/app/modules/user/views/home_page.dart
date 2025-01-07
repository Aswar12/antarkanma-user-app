import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/widgets/profile_image.dart';
import 'package:antarkanma/app/widgets/category_widget.dart';
import 'package:antarkanma/app/widgets/search_input_field.dart';
import 'package:antarkanma/app/widgets/product_carousel_card.dart';
import 'package:antarkanma/app/widgets/product_grid_card.dart';
import 'package:antarkanma/theme.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = Get.find<AuthService>();
  late HomePageController controller;
  final GlobalKey _carouselKey = GlobalKey();
  final GlobalKey _popularTitleKey = GlobalKey();
  bool _isCategorySticky = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomePageController>();
    _scrollController.addListener(_onScroll);
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (_searchFocusNode.hasFocus) {
      _scrollToHidePopularProducts();
    }
  }

  void _scrollToHidePopularProducts() {
    double carouselHeight =
        _carouselKey.currentContext?.findRenderObject()?.paintBounds?.height ??
            0;
    double titleHeight =
        _popularTitleKey.currentContext?.size?.height ?? Dimenssions.height45;
    double spacingHeight = Dimenssions.height10;
    double totalScrollHeight = carouselHeight + titleHeight + spacingHeight;

    _scrollController.animateTo(
      totalScrollHeight,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _onScroll() {
    final RenderBox? carouselBox =
        _carouselKey.currentContext?.findRenderObject() as RenderBox?;
    if (carouselBox != null) {
      final carouselHeight = carouselBox.size.height;
      setState(() {
        _isCategorySticky = _scrollController.offset > carouselHeight;
      });
    }

    // Schedule the load more check for after the current build phase
    if (!controller.isLoadingMore.value &&
        !controller.isRefreshing.value &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!controller.isLoadingMore.value && !controller.isRefreshing.value) {
          controller.loadMoreProducts();
        }
      });
    }
  }

  Widget _buildSearchBar() {
    return SearchInputField(
      controller: controller.searchController,
      hintText: 'Apa Ku AntarkanKi ?',
      focusNode: _searchFocusNode,
      onClear: () {
        controller.searchController.clear();
        FocusScope.of(context).unfocus();
      },
      onChanged: (value) async {
        if (value.isNotEmpty) {
          await controller.performSearch();
          _scrollToHidePopularProducts();
        }
      },
    );
  }

  Widget _buildCategories() {
    return const CategoryWidget();
  }

  Widget popularProductsTitle() {
    return Container(
      key: _popularTitleKey,
      margin: EdgeInsets.only(
        top: Dimenssions.height15,
        left: Dimenssions.width15,
        right: Dimenssions.width15,
        bottom: Dimenssions.height10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Produk Populer',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font18,
              fontWeight: semiBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget popularProducts() {
    return Obx(() {
      if (controller.isLoading.value) {
        return SizedBox(
          height: Dimenssions.pageView,
          child: Center(
            child: CircularProgressIndicator(
              color: logoColorSecondary,
            ),
          ),
        );
      }

      if (controller.popularProducts.isEmpty) {
        return SizedBox(
          height: Dimenssions.pageView,
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
              ],
            ),
          ),
        );
      }

      return Column(
        key: _carouselKey,
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
                onTap: () =>
                    Get.toNamed(Routes.productDetail, arguments: product),
              );
            },
          ),
          SizedBox(height: Dimenssions.height10),
          AnimatedSmoothIndicator(
            activeIndex: controller.currentIndex.value,
            count: controller.popularProducts.length,
            effect: WormEffect(
              activeDotColor: logoColorSecondary,
              dotColor: secondaryTextColor.withOpacity(0.2),
              dotHeight: Dimenssions.height10,
              dotWidth: Dimenssions.height10,
              type: WormType.thin,
            ),
          ),
        ],
      );
    });
  }

  Widget listProductsTitle() {
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
          Text(
            controller.searchQuery.isEmpty ? 'Semua Produk' : 'Hasil Pencarian',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font18,
              fontWeight: semiBold,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProductSlivers() {
    return [
      if (controller.filteredProducts.isEmpty)
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(Dimenssions.height20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    controller.searchQuery.isEmpty
                        ? Icons.shopping_bag_outlined
                        : Icons.search_off_outlined,
                    size: Dimenssions.iconSize24 * 2,
                    color: secondaryTextColor,
                  ),
                  SizedBox(height: Dimenssions.height10),
                  Text(
                    controller.searchQuery.isEmpty
                        ? 'Tidak ada produk'
                        : 'Tidak ada produk ditemukan',
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font16,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      else ...[
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              mainAxisSpacing: Dimenssions.height10,
              crossAxisSpacing: Dimenssions.width10,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = controller.filteredProducts[index];
                if (index == controller.filteredProducts.length - 3) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    controller.checkAndPreloadNextPage();
                  });
                }
                return ProductGridCard(
                  product: product,
                  onTap: () =>
                      Get.toNamed(Routes.productDetail, arguments: product),
                );
              },
              childCount: controller.filteredProducts.length,
            ),
          ),
        ),
        if (controller.isLoadingMore.value)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(Dimenssions.height10),
              child: Center(
                child: CircularProgressIndicator(
                  color: logoColorSecondary,
                ),
              ),
            ),
          ),
        if (!controller.hasMoreData.value &&
            controller.filteredProducts.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(Dimenssions.height10),
              child: Center(
                child: Text(
                  'Tidak ada produk lagi',
                  style: secondaryTextStyle.copyWith(
                    fontSize: Dimenssions.font14,
                  ),
                ),
              ),
            ),
          ),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.searchQuery.isEmpty) {
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: logoColorSecondary,
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: backgroundColor1,
        body: RefreshIndicator(
          onRefresh: controller.refreshProducts,
          color: logoColorSecondary,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: backgroundColor1,
                floating: true,
                snap: true,
                elevation: 0,
                toolbarHeight: kToolbarHeight,
                title: Container(
                  margin: EdgeInsets.symmetric(vertical: Dimenssions.height2),
                  child: _buildSearchBar(),
                ),
                actions: [
                  Container(
                    margin: EdgeInsets.only(
                      top: Dimenssions.height2,
                      right: Dimenssions.width15,
                      bottom: Dimenssions.height2,
                    ),
                    child: Obx(() {
                      final user = _authService.getUser();
                      if (user == null) {
                        return Container(
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
                      }
                      return ProfileImage(
                        user: user,
                        size: Dimenssions.height40,
                      );
                    }),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    popularProductsTitle(),
                    popularProducts(),
                    SizedBox(height: Dimenssions.height10),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: Dimenssions.height45,
                  maxHeight: Dimenssions.height45,
                  child: Container(
                    color: backgroundColor1,
                    alignment: Alignment.center,
                    child: _buildCategories(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: listProductsTitle(),
              ),
              ..._buildProductSlivers(),
            ],
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
