// ignore_for_file: use_full_hex_values_for_flutter_colors, unused_element, deprecated_member_use

import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/widgets/product_tile.dart';
import 'package:antarkanma/app/widgets/profile_image.dart';
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      return Scaffold(
        backgroundColor: backgroundColor3,
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                backgroundColor: backgroundColor3,
                floating: true,
                snap: true,
                pinned: false,
                title: _buildSearchBar(),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: Dimenssions.width20),
                    child: Obx(() {
                      final user = _authService.getUser();
                      if (user == null) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.grey,
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
              SliverList(
                delegate: SliverChildListDelegate([
                  popularProductsTitle(),
                  popularProducts(),
                  const SizedBox(height: 10),
                ]),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  minHeight: 35,
                  maxHeight: 35,
                  child: Container(
                    color: Colors.white,
                    child: _buildCategories(),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  listProductsTitle(),
                  listProducts(),
                ]),
              ),
            ],
          ),
        ),
      );
    });
  }

// Modifikasi _buildCategories untuk menambahkan shadow
  Widget _buildCategories() {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor3,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: Dimenssions.width10,
          vertical: 2,
        ),
        child: Row(
          children: [
            _buildCategoryItem("All"),
            _buildCategoryItem("Electronics"),
            _buildCategoryItem("Fashion"),
            _buildCategoryItem("Home"),
            _buildCategoryItem("Beauty"),
          ],
        ),
      ),
    );
  }

// Buat widget terpisah untuk search bar

  Widget _buildCategoryItem(String category) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimenssions.width5),
      child: Obx(() {
        bool isSelected = controller.selectedCategory.value == category;
        return GestureDetector(
          onTap: () => controller.selectedCategory.value = category,
          child: Chip(
            label: Text(category),
            backgroundColor: isSelected ? logoColorSecondary : Colors.grey[200],
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: Dimenssions.width10,
              vertical: 2,
            ),
            side: BorderSide(
              // Tambahkan border di sini
              color: isSelected ? Colors.white : logoColorSecondary,
              width: 1,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/search');
      },
      child: Container(
        height: Dimenssions.height40,
        decoration: BoxDecoration(
          border: Border.all(color: backgroundColor6, width: 2),
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10.0),
            Icon(Icons.search_outlined, color: backgroundColor6),
            SizedBox(width: Dimenssions.width10),
            Text(
              'Apa Ku AntarkanKi ?',
              style: subtitleTextStyle.copyWith(
                fontSize: Dimenssions.font14,
                color: backgroundColor6,
              ),
            ),
          ],
        ),
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
        SizedBox(height: Dimenssions.height5),
        Obx(() => AnimatedSmoothIndicator(
              activeIndex: controller.currentIndex.value,
              count: controller.products.length > 4
                  ? 4
                  : controller.products.length,
              effect: const WormEffect(
                activeDotColor: Color(0xfffffff6600),
                dotHeight: 11,
                dotWidth: 11,
                type: WormType.thinUnderground,
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
      child: Stack(
        children: [
          Container(
            height: Dimenssions.pageViewContainer,
            margin: EdgeInsets.symmetric(horizontal: Dimenssions.width10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimenssions.radius30),
              color: index.isEven
                  ? const Color(0xff69c5df)
                  : const Color(0xff9294cc),
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: Dimenssions.pageTextContainer,
              margin: EdgeInsets.symmetric(
                horizontal: Dimenssions.width20,
                vertical: Dimenssions.height5,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimenssions.radius20),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(Dimenssions.height20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: TextStyle(
                                color: primaryTextColor,
                                fontSize: Dimenssions.font16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: Dimenssions.width10),
                          _buildRatingItem(
                              product.averageRating, product.totalReviews),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Rp ${product.price}',
                            style: TextStyle(
                              fontSize: Dimenssions.font14,
                              color: logoColorSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.store,
                                    color: Colors.blue,
                                    size: Dimenssions.iconSize16),
                                SizedBox(width: Dimenssions.width5),
                                Flexible(
                                  child: Text(
                                    product.merchant?.name ??
                                        'Unknown Merchant',
                                    style: TextStyle(
                                      color: primaryTextColor,
                                      fontSize: Dimenssions.font12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget popularProductsTitle() {
    return _buildTitle('Produk Populer');
  }

  Widget listProductsTitle() {
    return _buildTitle('Daftar Produk');
  }

  Widget _buildTitle(String title) {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: Dimenssions.height5,
          left: Dimenssions.height25,
          bottom: Dimenssions.height10,
        ),
        child: Text(
          title,
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font20,
            color: backgroundColor6,
          ),
        ),
      ),
    );
  }

  Widget listProducts() {
    return Container(
      margin: EdgeInsets.only(top: Dimenssions.height10),
      child: Column(
        children: controller.filteredProducts.map((product) {
          return ProductTile(
            imageUrl:
                product.galleries.isNotEmpty && product.imageUrls[0].isNotEmpty
                    ? product.imageUrls[0]
                    : 'assets/image_shoes2.png',
            name: product.name,
            price: product.price,
            merchantName: product.merchant?.name ?? 'Unknown Merchant',
            // Anda perlu menambahkan properti ini di MerchantModel
            rating: product.averageRating,
            reviews: product.totalReviews,
            onTap: () {
              Get.toNamed(Routes.productDetail, arguments: product);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: Dimenssions.iconSize16),
        SizedBox(width: Dimenssions.width5),
        Text(
          text,
          style: TextStyle(
            color: primaryTextColor,
            fontSize: Dimenssions.font12,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingItem(double? rating, int? reviews) {
    return Row(
      children: [
        Icon(Icons.star, color: Colors.amber, size: Dimenssions.iconSize16),
        SizedBox(width: Dimenssions.width5),
        Text(
          '${rating ?? 0} (${reviews ?? 0})',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: Dimenssions.font12,
          ),
        ),
      ],
    );
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
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
