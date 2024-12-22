// ignore_for_file: use_full_hex_values_for_flutter_colors, unused_element, deprecated_member_use

import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/widgets/profile_image.dart';
import 'package:antarkanma/app/widgets/category_widget.dart';
import 'package:antarkanma/app/widgets/search_input_field.dart';
import 'package:antarkanma/app/widgets/cached_image_view.dart';
import 'package:antarkanma/theme.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = Get.find<AuthService>();
  final CarouselController carouselController = CarouselController();
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

  Widget _buildCarouselItem(int index) {
    if (index < 0 || index >= controller.popularProducts.length) {
      return Container();
    }
    var product = controller.popularProducts[index];
    return GestureDetector(
      onTap: () {
        Get.toNamed(Routes.productDetail, arguments: product);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: Dimenssions.width5),
        decoration: BoxDecoration(
          color: backgroundColor1,
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (product.galleries.isNotEmpty &&
                  product.imageUrls[0].isNotEmpty)
                CachedImageView(
                  imageUrl: product.imageUrls[0],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else
                Image.asset(
                  'assets/image_shoes.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: Dimenssions.height15,
                left: Dimenssions.width15,
                right: Dimenssions.width15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: primaryTextStyle.copyWith(
                        color: backgroundColor1,
                        fontSize: Dimenssions.font16,
                        fontWeight: semiBold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: Dimenssions.height5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(product.price),
                          style: primaryTextStyle.copyWith(
                            color: backgroundColor1,
                            fontSize: Dimenssions.font14,
                            fontWeight: medium,
                          ),
                        ),
                        Row(
                          children: [
                            _buildStarRating(product.ratingInfo != null
                                ? (product.ratingInfo!['average_rating'] as num)
                                    .toDouble()
                                : product.averageRating),
                            SizedBox(width: Dimenssions.width5),
                            Text(
                              '(${product.ratingInfo != null ? product.ratingInfo!['total_reviews'] : product.totalReviews})',
                              style: primaryTextStyle.copyWith(
                                color: backgroundColor1,
                                fontSize: Dimenssions.font14,
                              ),
                            ),
                          ],
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
          Row(
            children: [
              TextButton(
                onPressed: () {},
                child: Text(
                  'Lihat Semua',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font14,
                    color: logoColorSecondary,
                  ),
                ),
              ),
              IconButton(
                onPressed: controller.forceRefreshFromServer,
                icon: Icon(
                  Icons.refresh,
                  color: logoColorSecondary,
                  size: Dimenssions.height22,
                ),
                tooltip: 'Perbarui data dari server',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget popularProducts() {
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
            return _buildCarouselItem(index);
          },
        ),
        SizedBox(height: Dimenssions.height10),
        Obx(() => controller.popularProducts.isNotEmpty
            ? AnimatedSmoothIndicator(
                activeIndex: controller.currentIndex.value <
                        controller.popularProducts.length
                    ? controller.currentIndex.value
                    : 0,
                count: controller.popularProducts.length,
                effect: WormEffect(
                  activeDotColor: logoColorSecondary,
                  dotColor: secondaryTextColor.withOpacity(0.2),
                  dotHeight: Dimenssions.height10,
                  dotWidth: Dimenssions.height10,
                  type: WormType.thin,
                ),
              )
            : const SizedBox()),
      ],
    );
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
            controller.searchQuery.isEmpty
                ? 'Daftar Produk'
                : 'Hasil Pencarian',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font18,
              fontWeight: semiBold,
            ),
          ),
          if (controller.searchQuery.isEmpty)
            Row(
              children: [
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Lihat Semua',
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font14,
                      color: logoColorSecondary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget listProducts() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          mainAxisSpacing: Dimenssions.height10,
          crossAxisSpacing: Dimenssions.width10,
        ),
        itemCount: controller.filteredProducts.length,
        itemBuilder: (context, index) {
          final product = controller.filteredProducts[index];
          return GestureDetector(
            onTap: () => Get.toNamed(Routes.productDetail, arguments: product),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor2,
                borderRadius: BorderRadius.circular(Dimenssions.radius15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: ClipRRect(
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
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimenssions.width8,
                        vertical: Dimenssions.height8,
                      ),
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
                          Row(
                            children: [
                              Icon(
                                Icons.store,
                                color: logoColorSecondary,
                                size: Dimenssions.height15,
                              ),
                              SizedBox(width: Dimenssions.width5),
                              Expanded(
                                child: Text(
                                  product.merchant?.name ?? 'Unknown',
                                  style: secondaryTextStyle.copyWith(
                                    fontSize: Dimenssions.font12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              _buildStarRating(product.ratingInfo != null
                                  ? (product.ratingInfo!['average_rating']
                                          as num)
                                      .toDouble()
                                  : product.averageRating),
                              SizedBox(width: Dimenssions.width5),
                              Text(
                                '(${product.ratingInfo != null ? product.ratingInfo!['total_reviews'] : product.totalReviews})',
                                style: secondaryTextStyle.copyWith(
                                  fontSize: Dimenssions.font12,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Dimenssions.height5),
                          Text(
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(product.price),
                            style: priceTextStyle.copyWith(
                              fontSize: Dimenssions.font14,
                              fontWeight: medium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStarRating(double? rating) {
    final double actualRating = rating ?? 0.0;
    int fullStars = actualRating.floor();
    bool hasHalfStar = (actualRating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star,
              color: Colors.amber, size: Dimenssions.height18);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half,
              color: Colors.amber, size: Dimenssions.height18);
        } else {
          return Icon(Icons.star_border,
              color: Colors.amber, size: Dimenssions.height18);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Only show loading for initial data load, not during search
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
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: backgroundColor1,
                  floating: true,
                  snap: true,
                  pinned: false,
                  elevation: 0,
                  toolbarHeight: 60,
                  title: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: Dimenssions.width5),
                    child: SearchInputField(
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
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: EdgeInsets.only(right: Dimenssions.width15),
                      child: Obx(() {
                        final user = _authService.getUser();
                        if (user == null) {
                          return Container(
                            width: 40,
                            height: 40,
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
                              size: 20,
                            ),
                          );
                        }
                        return ProfileImage(
                          user: user,
                          size: 40,
                        );
                      }),
                    ),
                  ],
                ),
              ];
            },
            body: CustomScrollView(
              controller: _scrollController,
              slivers: [
                if (controller.searchQuery.isEmpty) ...[
                  SliverList(
                    delegate: SliverChildListDelegate([
                      popularProductsTitle(),
                      popularProducts(),
                      SizedBox(height: Dimenssions.height10),
                    ]),
                  ),
                ],
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    minHeight: Dimenssions.height45,
                    maxHeight: Dimenssions.height45,
                    child: Container(
                      color: backgroundColor1,
                      child: _buildCategories(),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    listProductsTitle(),
                    listProducts(),
                    SizedBox(height: Dimenssions.height20),
                  ]),
                ),
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
