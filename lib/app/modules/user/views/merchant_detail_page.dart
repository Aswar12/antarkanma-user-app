import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/widgets/merchant_detail_section.dart';
import 'package:antarkanma/app/widgets/product_grid_card.dart';
import 'package:antarkanma/app/widgets/search_input_field.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MerchantDetailController extends GetxController {
  final MerchantService _merchantService;

  MerchantDetailController({required MerchantService merchantService})
      : _merchantService = merchantService;

  final merchantId = 0.obs;
  final merchant = Rxn<MerchantModel>();
  final products = <ProductModel>[].obs;
  final isLoading = true.obs;
  final searchController = TextEditingController();
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments is Map) {
      merchantId.value = Get.arguments['merchantId'] as int;
      loadMerchantDetail();
    }
  }

  Future<void> loadMerchantDetail() async {
    try {
      isLoading(true);
      final merchantData =
          await _merchantService.getMerchantById(merchantId.value);
      merchant.value = merchantData;
      await loadMerchantProducts();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat detail merchant',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadMerchantProducts() async {
    try {
      final response = await _merchantService.getMerchantProducts(
        merchantId.value,
        query: searchQuery.value,
      );
      products.value = response.data;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat produk merchant',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> searchProducts(String query) async {
    searchQuery.value = query;
    await loadMerchantProducts();
  }
}

class MerchantDetailPage extends StatelessWidget {
  const MerchantDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      MerchantDetailController(
        merchantService: Get.find<MerchantService>(),
      ),
      tag: Get.arguments?['merchantId']?.toString(),
    );

    Widget buildSearchBar() {
      return Container(
        height: 40,
        margin: EdgeInsets.only(left: Dimenssions.width8),
        child: SearchInputField(
          controller: controller.searchController,
          hintText: 'Cari produk di toko ini',
          onClear: () {
            controller.searchController.clear();
            controller.searchProducts('');
            FocusManager.instance.primaryFocus?.unfocus();
          },
          onChanged: (value) => controller.searchProducts(value),
        ),
      );
    }

    Widget buildProductGrid() {
      return Obx(() {
        if (controller.isLoading.value) {
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                color: logoColorSecondary,
              ),
            ),
          );
        }

        if (controller.products.isEmpty) {
          return SizedBox(
            height: 200,
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
                    'Tidak ada produk',
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

        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            mainAxisSpacing: Dimenssions.height15,
            crossAxisSpacing: Dimenssions.width15,
          ),
          itemCount: controller.products.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final product = controller.products[index];
            return ProductGridCard(
              product: product,
              onTap: () => Get.toNamed('/product-detail', arguments: product),
            );
          },
        );
      });
    }

    return Scaffold(
      backgroundColor: backgroundColor1,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          backgroundColor: backgroundColor1,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: primaryTextColor,
              size: Dimenssions.iconSize24,
            ),
            onPressed: () => Get.back(),
          ),
          titleSpacing: 0,
          title: buildSearchBar(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: logoColorSecondary,
            ),
          );
        }

        if (controller.merchant.value == null) {
          return Center(
            child: Text(
              'Merchant tidak ditemukan',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font16,
                color: secondaryTextColor,
              ),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            if (controller.merchant.value != null)
              SliverToBoxAdapter(
                child:
                    MerchantDetailSection(merchant: controller.merchant.value!),
              ),
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: Dimenssions.width15,
                vertical: Dimenssions.height10,
              ),
              sliver: SliverToBoxAdapter(
                child: buildProductGrid(),
              ),
            ),
          ],
        );
      }),
    );
  }
}
