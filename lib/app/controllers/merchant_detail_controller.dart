import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
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

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
