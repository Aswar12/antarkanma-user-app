// ignore_for_file: use_full_hex_values_for_flutter_colors, unused_element, deprecated_member_use

import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/widgets/profile_image.dart';
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
  bool _isCategorySticky = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.find<HomePageController>();
    _scrollController.addListener(_onScroll);
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

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Get.toNamed('/search');
      },
      child: Container(
        height: Dimenssions.height45,
        padding: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
        decoration: BoxDecoration(
          color: backgroundColor3,
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
          border: Border.all(
            color: secondaryTextColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_outlined,
              color: secondaryTextColor,
              size: Dimenssions.height22,
            ),
            SizedBox(width: Dimenssions.width10),
            Text(
              'Apa Ku AntarkanKi ?',
              style: secondaryTextStyle.copyWith(
                fontSize: Dimenssions.font14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor1,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: Dimenssions.width15,
          vertical: Dimenssions.height5,
        ),
        child: Row(
          children: [
            _buildCategoryItem("Semua"),
            _buildCategoryItem("Elektronik"),
            _buildCategoryItem("Fashion"),
            _buildCategoryItem("Rumah"),
            _buildCategoryItem("Kecantikan"),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String category) {
    return Container(
      margin: EdgeInsets.only(right: Dimenssions.width10),
      child: Obx(() {
        bool isSelected = controller.selectedCategory.value == category;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.selectedCategory.value = category,
            borderRadius: BorderRadius.circular(Dimenssions.radius15),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimenssions.width15,
                vertical: Dimenssions.height5,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? logoColorSecondary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(Dimenssions.radius15),
                border: Border.all(
                  color: isSelected
                      ? logoColorSecondary
                      : secondaryTextColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                category,
                style: primaryTextStyle.copyWith(
                  color: isSelected ? logoColorSecondary : secondaryTextColor,
                  fontSize: Dimenssions.font14,
                  fontWeight: isSelected ? semiBold : regular,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget popularProductsTitle() {
    return _buildTitle('Produk Populer');
  }

  Widget listProductsTitle() {
    return _buildTitle('Daftar Produk');
  }

  Widget _buildTitle(String title) {
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
            title,
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font18,
              fontWeight: semiBold,
            ),
          ),
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
    );
  }

  Widget popularProducts() {
    return Column(
      key: _carouselKey,
      children: [
        CarouselSlider.builder(
          itemCount:
              controller.products.length > 4 ? 4 : controller.products.length,
          options: CarouselOptions(
            height: Dimenssions.pageView,
            viewportFraction: 0.85,
            enlargeCenterPage: true,
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeStrategy: CenterPageEnlargeStrategy.scale,
            enlargeFactor: 0.15,
            autoPlay: controller.products.length > 1,
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
        Obx(() => AnimatedSmoothIndicator(
              activeIndex: controller.currentIndex.value,
              count: controller.products.length > 4
                  ? 4
                  : controller.products.length,
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
  }

  Widget _buildCarouselItem(int index) {
    if (index < 0 || index >= controller.products.length) {
      return Container();
    }
    var product = controller.products[index];
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
              Image(
                image: product.galleries.isNotEmpty &&
                        product.imageUrls[0].isNotEmpty
                    ? NetworkImage(product.imageUrls[0])
                    : const AssetImage('assets/image_shoes.png')
                        as ImageProvider,
                fit: BoxFit.cover,
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
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimenssions.width10,
                            vertical: Dimenssions.height5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius15),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: Dimenssions.height15,
                              ),
                              SizedBox(width: Dimenssions.width5),
                              Text(
                                '${product.averageRating ?? 0}',
                                style: primaryTextStyle.copyWith(
                                  color: backgroundColor1,
                                  fontSize: Dimenssions.font12,
                                ),
                              ),
                            ],
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
          childAspectRatio: 0.75,
          mainAxisSpacing: Dimenssions.height15,
          crossAxisSpacing: Dimenssions.width15,
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
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(Dimenssions.radius15),
                          topRight: Radius.circular(Dimenssions.radius15),
                        ),
                        image: DecorationImage(
                          image: product.galleries.isNotEmpty &&
                                  product.imageUrls[0].isNotEmpty
                              ? NetworkImage(product.imageUrls[0])
                              : const AssetImage('assets/image_shoes.png')
                                  as ImageProvider,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.all(Dimenssions.height10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product.name,
                            style: primaryTextStyle.copyWith(
                              fontSize: Dimenssions.font14,
                              fontWeight: semiBold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Dimenssions.width5,
                                      vertical: Dimenssions.height2,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          logoColorSecondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(
                                          Dimenssions.radius8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: Dimenssions.height12,
                                        ),
                                        SizedBox(width: Dimenssions.width2),
                                        Text(
                                          '${product.averageRating ?? 0}',
                                          style: primaryTextStyle.copyWith(
                                            fontSize: Dimenssions.font10,
                                            color: logoColorSecondary,
                                          ),
                                        ),
                                      ],
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
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
                  title: _buildSearchBar(),
                  actions: [
                    Padding(
                      padding: EdgeInsets.only(right: Dimenssions.width20),
                      child: Obx(() {
                        final user = _authService.getUser();
                        if (user == null) {
                          return Container(
                            width: Dimenssions.height45,
                            height: Dimenssions.height45,
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
                              size: Dimenssions.height22,
                            ),
                          );
                        }
                        return ProfileImage(
                          user: user,
                          size: Dimenssions.height45,
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
                SliverList(
                  delegate: SliverChildListDelegate([
                    popularProductsTitle(),
                    popularProducts(),
                    SizedBox(height: Dimenssions.height10),
                  ]),
                ),
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
