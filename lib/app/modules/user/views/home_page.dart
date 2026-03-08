import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:antarkanma/app/widgets/merchant_card.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/widgets/product_card.dart';

// import 'package:antarkanma/app/widgets/merchant_skeleton_loading.dart';
import 'package:antarkanma/app/modules/user/views/widgets/home_app_bar_widget.dart';
import 'package:antarkanma/app/modules/user/views/widgets/service_grid_widget.dart';
import 'package:antarkanma/app/modules/user/views/widgets/saved_places_widget.dart';
// import 'package:antarkanma/app/modules/user/views/widgets/promo_banner_widget.dart';
import 'package:antarkanma/app/modules/user/views/widgets/merchant_horizontal_list.dart';
import 'package:antarkanma/app/modules/user/views/widgets/popular_products_widget.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/widgets/search_input_field.dart';
import 'package:antarkanma/app/services/merchant_service.dart'; // Ensure these are present
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/app/services/location_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
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
      hintText: 'Cari Apa ki?...',
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

  // List<Widget> _buildMerchantSlivers() {
  //   if (controller.isLoading.value) {
  //     return [
  //       const SliverToBoxAdapter(
  //         child: MerchantSkeletonLoading(),
  //       ),
  //     ];
  //   }

  //   if (controller.filteredMerchants.isEmpty) {
  //     return [
  //       SliverFillRemaining(
  //         child: Center(
  //           child: Padding(
  //             padding: EdgeInsets.all(Dimenssions.height20),
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Icon(
  //                   controller.searchQuery.isEmpty
  //                       ? Icons.store_outlined
  //                       : Icons.search_off_outlined,
  //                   size: Dimenssions.iconSize24 * 2,
  //                   color: secondaryTextColor,
  //                 ),
  //                 SizedBox(height: Dimenssions.height10),
  //                 Text(
  //                   controller.searchQuery.isEmpty
  //                       ? 'Tidak ada merchant'
  //                       : 'Tidak ada merchant ditemukan',
  //                   style: primaryTextStyle.copyWith(
  //                     fontSize: Dimenssions.font16,
  //                     color: secondaryTextColor,
  //                   ),
  //                 ),
  //                 if (controller.searchQuery.isEmpty) ...[
  //                   SizedBox(height: Dimenssions.height10),
  //                   TextButton(
  //                     onPressed: () => controller.loadAllMerchants(),
  //                     child: Text(
  //                       'Muat Ulang',
  //                       style: primaryTextStyle.copyWith(
  //                         color: logoColorSecondary,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ];
  //   }

  //   return [
  //     SliverPadding(
  //       padding: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
  //       sliver: SliverGrid(
  //         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
  //           crossAxisCount: 2,
  //           childAspectRatio: 0.8,
  //           mainAxisSpacing: Dimenssions.height10,
  //           crossAxisSpacing: Dimenssions.width10,
  //         ),
  //         delegate: SliverChildBuilderDelegate(
  //           (context, index) {
  //             final merchant = controller.filteredMerchants[index];

  //             if (index >= controller.filteredMerchants.length - 3 &&
  //                 !controller.isLoadingMore.value &&
  //                 controller.hasMoreData.value) {
  //               WidgetsBinding.instance.addPostFrameCallback((_) {
  //                 controller.loadMoreMerchants();
  //               });
  //             }

  //             return MerchantCard(merchant: merchant);
  //           },
  //           childCount: controller.filteredMerchants.length,
  //         ),
  //       ),
  //     ),
  //     if (controller.isLoadingMore.value)
  //       const SliverToBoxAdapter(
  //         child: MerchantSkeletonLoading(),
  //       ),
  //   ];
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: backgroundLight,
      body: Stack(
        children: [
          // Main Content
          Padding(
            padding: EdgeInsets.only(
                top: Dimenssions.height100 * 1.1), // Adjusted for new header
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              color: primaryOrange,
              child: Obx(() => CustomScrollView(
                    controller: controller.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Normal Home Content
                      if (controller.searchQuery.isEmpty) ...[
                        SliverToBoxAdapter(
                            child: SizedBox(
                                height:
                                    Dimenssions.height30)), // Reduced from 45
                        SliverToBoxAdapter(child: const ServiceGridWidget()),
                        SliverToBoxAdapter(
                            child: SizedBox(height: Dimenssions.height20)),
                        SliverToBoxAdapter(child: const SavedPlacesWidget()),
                        SliverToBoxAdapter(
                            child: SizedBox(height: Dimenssions.height20)),
                        SliverToBoxAdapter(
                            child:
                                PopularProductsWidget(controller: controller)),
                        SliverToBoxAdapter(
                            child: SizedBox(height: Dimenssions.height20)),
                        SliverToBoxAdapter(
                            child:
                                MerchantHorizontalList(controller: controller)),
                        SliverToBoxAdapter(
                            child: SizedBox(height: Dimenssions.height20)),
                      ],

                      // Search Results Content
                      if (controller.searchQuery.isNotEmpty) ...[
                        SliverToBoxAdapter(
                            child: SizedBox(height: Dimenssions.height30)),

                        // Merchants Results Header
                        if (controller.merchantSearchResults.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(Dimenssions.width15,
                                  0, Dimenssions.width15, Dimenssions.height10),
                              child: Row(
                                children: [
                                  Icon(Icons.store,
                                      color: navyColor,
                                      size: Dimenssions.iconSize16),
                                  SizedBox(width: Dimenssions.width5),
                                  Text(
                                    'Merchant Ditemukan',
                                    style: primaryTextStyle.copyWith(
                                      fontSize: Dimenssions.font16,
                                      fontWeight: bold,
                                      color: navyColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Merchants Results Grid
                        if (controller.merchantSearchResults.isNotEmpty)
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                                horizontal: Dimenssions.width15),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio:
                                    0.75, // Adjusted for MerchantCard
                                mainAxisSpacing: Dimenssions.height10,
                                crossAxisSpacing: Dimenssions.width10,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  if (index >=
                                      controller.merchantSearchResults.length)
                                    return const SizedBox();
                                  final merchant =
                                      controller.merchantSearchResults[index];
                                  return MerchantCard(merchant: merchant);
                                },
                                childCount:
                                    controller.merchantSearchResults.length,
                              ),
                            ),
                          ),

                        // Divider if both exist
                        if (controller.merchantSearchResults.isNotEmpty &&
                            controller.searchResults.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: Dimenssions.height20),
                              child: Divider(
                                  thickness: 1, color: Colors.grey[200]),
                            ),
                          )
                        else
                          SliverToBoxAdapter(
                              child: SizedBox(height: Dimenssions.height20)),

                        // Products Results Header
                        if (controller.searchResults.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(Dimenssions.width15,
                                  0, Dimenssions.width15, Dimenssions.height10),
                              child: Row(
                                children: [
                                  Icon(Icons.restaurant_menu,
                                      color: navyColor,
                                      size: Dimenssions.iconSize16),
                                  SizedBox(width: Dimenssions.width5),
                                  Text(
                                    'Makanan Ditemukan',
                                    style: primaryTextStyle.copyWith(
                                      fontSize: Dimenssions.font16,
                                      fontWeight: bold,
                                      color: navyColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Products Results List
                        if (controller.searchResults.isNotEmpty)
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index >= controller.searchResults.length)
                                  return const SizedBox();
                                final product = controller.searchResults[index];
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: Dimenssions.width15,
                                      vertical: Dimenssions.height10),
                                  child: ProductCard(
                                    product: product,
                                    onTap: () {
                                      Get.toNamed(Routes.productDetail,
                                          arguments: product);
                                    },
                                  ),
                                );
                              },
                              childCount: controller.searchResults.length,
                            ),
                          ),

                        // Empty State
                        if (!controller.isLoadingMore.value &&
                            controller.merchantSearchResults.isEmpty &&
                            controller.searchResults.isEmpty)
                          SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding:
                                    EdgeInsets.only(top: Dimenssions.height100),
                                child: Column(
                                  children: [
                                    Icon(Icons.search_off,
                                        size: 64, color: Colors.grey),
                                    SizedBox(height: Dimenssions.height10),
                                    Text(
                                        'Tidak ditemukan hasil untuk "${controller.searchQuery.value}"',
                                        style: secondaryTextStyle),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],

                      SliverToBoxAdapter(
                          child: SizedBox(
                              height: Dimenssions
                                  .height20)), // Comfortable bottom space
                    ],
                  )),
            ),
          ),

          // Fixed Header
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeAppBarWidget(),
          ),

          // Floating Search Bar
          Positioned(
            top: Dimenssions.height100 * 0.85,
            left: Dimenssions.width15,
            right: Dimenssions.width15,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _buildSearchBar(),
            ),
          ),
        ],
      ),
    );
  }
}
