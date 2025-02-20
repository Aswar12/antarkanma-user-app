import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/merchant_service.dart';
import '../services/product_service.dart';
import '../data/models/merchant_model.dart';
import '../data/models/product_model.dart';

class MerchantDetailController extends GetxController {
  final MerchantService _merchantService;
  final ProductService _productService;
  
  final searchController = TextEditingController();
  final merchant = Rx<MerchantModel?>(null);
  final products = <ProductModel>[].obs;
  final isLoading = true.obs;

  // Constructor with dependency injection
  MerchantDetailController({
    required MerchantService merchantService,
    required ProductService productService,
  }) : _merchantService = merchantService,
       _productService = productService {
    debugPrint('MerchantDetailController: Constructor called');
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint('MerchantDetailController: onInit');
    _loadMerchantData();
  }

  Future<void> _loadMerchantData() async {
    try {
      final Map<String, dynamic>? args = Get.arguments;
      if (args != null && args.containsKey('merchantId')) {
        final merchantId = args['merchantId'];
        if (merchantId != null) {
          await loadMerchantData(merchantId);
        } else {
          _handleError('Invalid merchant ID');
        }
      } else {
        _handleError('Merchant ID not provided');
      }
    } catch (e) {
      _handleError('Error loading merchant data: $e');
    }
  }

  void _handleError(String message) {
    debugPrint('MerchantDetailController: $message');
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
    Get.back();
  }

  Future<void> loadMerchantData(dynamic merchantId) async {
    try {
      isLoading.value = true;
      debugPrint('Loading merchant data for ID: $merchantId');
      
      final merchantData = await _merchantService.getMerchantById(merchantId as int);
      merchant.value = merchantData;
      debugPrint('Merchant data loaded: ${merchantData.name}');

      if (merchantData.id != null) {
        final productsResponse = await _merchantService.getMerchantProducts(merchantData.id!);
        products.assignAll(productsResponse.data);
        debugPrint('Loaded ${products.length} products for merchant');
      }
    } catch (e) {
      debugPrint('Error loading merchant data: $e');
      Get.snackbar(
        'Error',
        'Failed to load merchant data',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void searchProducts(String query) async {
    if (merchant.value == null || merchant.value?.id == null) return;
    
    try {
      isLoading.value = true;
      if (query.isEmpty) {
        final productsResponse = await _merchantService.getMerchantProducts(merchant.value!.id!);
        products.assignAll(productsResponse.data);
        return;
      }

      final productsResponse = await _merchantService.getMerchantProducts(
        merchant.value!.id!,
        query: query,
      );
      products.assignAll(productsResponse.data);
    } catch (e) {
      debugPrint('Error searching products: $e');
      Get.snackbar(
        'Error',
        'Failed to search products',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
