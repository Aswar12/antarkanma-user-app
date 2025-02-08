import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/repositories/review_repository.dart';
import 'package:antarkanma/app/data/models/variant_model.dart';
import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:flutter/material.dart';

class ProductDetailController extends GetxController {
  final ReviewRepository reviewRepository;
  final MerchantService _merchantService = Get.find<MerchantService>();
  
  final RxList<ProductReviewModel> apiReviews = <ProductReviewModel>[].obs;
  final isLoadingReviews = false.obs;
  final RxInt currentImageIndex = RxInt(0);
  final RxInt selectedRatingFilter = RxInt(0);
  final RxBool isExpanded = RxBool(false);
  final RxBool isLoadingMerchant = false.obs;

  List<ProductReviewModel> get visibleReviews =>
      isExpanded.value ? apiReviews : apiReviews.take(3).toList();

  bool get hasMoreReviews => apiReviews.length > 3;

  List<ProductReviewModel> get reviews => apiReviews;
  int get reviewCount => apiReviews.length;
  double get averageRating {
    if (apiReviews.isEmpty) return 0.0;
    final total = apiReviews.fold(0, (sum, review) => sum + review.rating);
    return total / apiReviews.length;
  }

  void toggleReviews() {
    isExpanded.value = !isExpanded.value;
  }

  ProductDetailController({required this.reviewRepository});

  var product = ProductModel(
    id: null,
    name: 'Unknown Product',
    description: 'No description available',
    galleries: [],
    price: 0.0,
    status: null,
    merchant: null,
    category: null,
    createdAt: null,
    updatedAt: null,
    variants: [],
  ).obs;

  final quantity = 1.obs;
  final Rx<VariantModel?> selectedVariant = Rx<VariantModel?>(null);

  double get totalPrice {
    double basePrice = product.value.price;
    if (selectedVariant.value != null) {
      basePrice = selectedVariant.value!.calculateAdjustedPrice(basePrice);
    }
    return basePrice * quantity.value;
  }

  void incrementQuantity() {
    if (quantity.value < 99) {
      quantity.value++;
    } else {
      showCustomSnackbar(
        title: 'Maksimal Pemesanan',
        message: 'Tidak bisa melebihi 99 item',
        isError: true,
      );
    }
  }

  void decrementQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  void selectVariant(VariantModel variant) {
    if (selectedVariant.value?.id == variant.id) {
      selectedVariant.value = null;
    } else {
      selectedVariant.value = variant;
    }
  }

  void updateImageIndex(int index) {
    currentImageIndex.value = index;
  }

  bool validateCheckout() {
    if (product.value.merchant == null) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Data merchant tidak valid',
        isError: true,
      );
      return false;
    }

    if (product.value.variants.isNotEmpty && selectedVariant.value == null) {
      showCustomSnackbar(
        title: 'Pilih Varian',
        message: 'Silakan pilih varian produk terlebih dahulu',
        isError: true,
      );
      return false;
    }

    if (!product.value.merchant!.isActive) {
      showCustomSnackbar(
        title: 'Merchant Tidak Aktif',
        message: 'Maaf, merchant ini sedang tidak aktif',
        isError: true,
      );
      return false;
    }

    if (product.value.status != 'ACTIVE') {
      showCustomSnackbar(
        title: 'Produk Tidak Tersedia',
        message: 'Maaf, produk ini sedang tidak tersedia',
        isError: true,
      );
      return false;
    }

    return true;
  }

  Future<void> loadMerchantData(int? merchantId) async {
    try {
      // If no merchantId provided, try to get it from product's merchant data
      final actualMerchantId = merchantId ?? product.value.merchant?.id;
      
      if (actualMerchantId == null) {
        debugPrint('No merchant ID available to load merchant data');
        return;
      }

      isLoadingMerchant.value = true;
      final token = StorageService.instance.getToken();
      
      final merchant = await _merchantService.getMerchantById(actualMerchantId, token: token);
      
      // Update the product with merchant data
      final updatedProduct = ProductModel(
        id: product.value.id,
        name: product.value.name,
        description: product.value.description,
        galleries: product.value.galleries,
        price: product.value.price,
        status: product.value.status,
        merchant: merchant,  // Set the loaded merchant
        category: product.value.category,
        createdAt: product.value.createdAt,
        updatedAt: product.value.updatedAt,
        variants: product.value.variants,
        reviews: product.value.reviews,
        averageRatingRaw: product.value.averageRatingRaw,
        totalReviewsRaw: product.value.totalReviewsRaw,
        ratingInfo: product.value.ratingInfo,
      );
      
      product.value = updatedProduct;
      
    } catch (e) {
      debugPrint('Error loading merchant data: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal memuat data merchant',
        isError: true,
      );
    } finally {
      isLoadingMerchant.value = false;
    }
  }

  void setProduct(ProductModel newProduct) async {
    try {
      // Set initial product data
      product.value = newProduct;
      currentImageIndex.value = 0;
      selectedVariant.value = null;
      quantity.value = 1;
      apiReviews.clear();
      selectedRatingFilter.value = 0;
      isExpanded.value = false;

      // Check if we need to load merchant data
      if (newProduct.merchant == null || newProduct.merchant?.id == null) {
        // This is likely from popular products, need to load merchant data
        debugPrint('Product missing merchant data, attempting to load...');
        await loadMerchantData(null);  // Will try to get merchant ID from product data
      } else {
        debugPrint('Product already has merchant data');
        // Even if we have merchant data, let's refresh it to ensure it's up to date
        await loadMerchantData(newProduct.merchant!.id);
      }

      // Load reviews
      fetchReviews();
      
    } catch (e) {
      debugPrint('Error in setProduct: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Terjadi kesalahan saat memuat data produk',
        isError: true,
      );
    }
  }

  Future<void> fetchReviews() async {
    try {
      if (isLoadingReviews.value || product.value.id == null) return;

      isLoadingReviews.value = true;
      final token = StorageService.instance.getToken();

      final reviews = await reviewRepository.getProductReviews(
        product.value.id!,
        rating: selectedRatingFilter.value == 0 ? null : selectedRatingFilter.value,
        token: token,
      );

      apiReviews.value = reviews;
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal memuat ulasan',
        isError: true,
      );
    } finally {
      isLoadingReviews.value = false;
    }
  }

  void setRatingFilter(int rating) {
    if (selectedRatingFilter.value == rating) {
      selectedRatingFilter.value = 0;
    } else {
      selectedRatingFilter.value = rating;
    }
    fetchReviews();
  }

  @override
  void onClose() {
    apiReviews.clear();
    super.onClose();
  }
}
