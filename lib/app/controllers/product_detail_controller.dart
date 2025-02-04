import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/product_gallery_model.dart';
import 'package:antarkanma/app/data/repositories/review_repository.dart';
import 'package:antarkanma/app/data/models/variant_model.dart';
import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:antarkanma/app/services/storage_service.dart';

class ProductDetailController extends GetxController {
  final ReviewRepository reviewRepository;
  final RxList<ProductReviewModel> apiReviews = <ProductReviewModel>[].obs;
  final isLoadingReviews = false.obs;
  final RxInt currentImageIndex = RxInt(0);
  final RxInt selectedRatingFilter = RxInt(0);
  final RxBool isExpanded = RxBool(false);

  List<ProductReviewModel> get visibleReviews =>
      isExpanded.value ? apiReviews : apiReviews.take(3).toList();

  bool get hasMoreReviews => apiReviews.length > 3;

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

  List<ProductReviewModel> get reviews => apiReviews;
  int get reviewCount => apiReviews.length;
  double get averageRating {
    if (apiReviews.isEmpty) return 0.0;
    final total = apiReviews.fold(0, (sum, review) => sum + review.rating);
    return total / apiReviews.length;
  }

  void setRatingFilter(int rating) {
    if (selectedRatingFilter.value == rating) {
      selectedRatingFilter.value = 0;
    } else {
      selectedRatingFilter.value = rating;
    }
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      if (isLoadingReviews.value) return;

      debugPrint('Fetching reviews for product ID: ${product.value.id}');
      if (product.value.id == null) {
        debugPrint('Product ID is null, cannot fetch reviews');
        return;
      }

      isLoadingReviews.value = true;

      // Try to get cached reviews first
      final cachedReviews =
          StorageService.instance.getProductReviews(product.value.id!);
      if (cachedReviews != null) {
        debugPrint('Using cached reviews: ${cachedReviews.length}');
        apiReviews.value = cachedReviews
            .map((json) => ProductReviewModel.fromJson(json))
            .toList();

        if (selectedRatingFilter.value != 0) {
          apiReviews.value = apiReviews
              .where((review) => review.rating == selectedRatingFilter.value)
              .toList();
        }
      }

      // Fetch fresh reviews from API
      final token = StorageService.instance.getToken();
      debugPrint('Token available: ${token != null}');

      final reviews = await reviewRepository.getProductReviews(
        product.value.id!,
        rating: selectedRatingFilter.value == 0 ? null : selectedRatingFilter.value,
        token: token,
      );

      debugPrint('Reviews fetched from API: ${reviews.length}');

      // Update cache with new reviews if rating filter is not applied
      if (selectedRatingFilter.value == 0) {
        await StorageService.instance.saveProductReviews(
          product.value.id!,
          reviews.map((review) => review.toJson()).toList(),
        );
      }

      // Update UI with new reviews
      apiReviews.value = reviews;
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal memuat ulasan',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingReviews.value = false;
    }
  }

  void selectVariant(VariantModel variant) {
    if (selectedVariant.value?.id == variant.id) {
      selectedVariant.value = null;
    } else {
      selectedVariant.value = variant;
    }
  }

  double get totalPrice {
    double basePrice = product.value.price;
    if (selectedVariant.value != null) {
      basePrice = selectedVariant.value!.calculateAdjustedPrice(basePrice);
    }
    return basePrice * quantity.value;
  }

  String get formattedTotalPrice {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(totalPrice);
  }

  void incrementQuantity() {
    if (quantity.value < 99) {
      quantity.value++;
    } else {
      showCustomSnackbar(
        title: 'Maksimal Mi pesananta',
        message: 'Tidak bisaki kalau lebih 50',
        backgroundColor: logoColorSecondary,
        snackPosition: SnackPosition.BOTTOM,
        isError: true,
      );
    }
  }

  void decrementQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  String get currentImageUrl {
    if (product.value.galleries.isEmpty) {
      return 'assets/image_shoes.png';
    }
    return product.value.galleries[currentImageIndex.value].url;
  }

  List<String> get imageUrls => product.value.imageUrls;
  int get imageCount => product.value.galleries.length;

  void updateImageIndex(int index) {
    currentImageIndex.value = index;
  }

  String getVariantDisplayText(VariantModel variant) {
    return '${variant.name}: ${variant.value} (${variant.formattedPriceAdjustment})';
  }

  bool isVariantSelected(VariantModel? variant) {
    if (variant == null) {
      return product.value.variants.isEmpty;
    }
    return selectedVariant.value?.id == variant.id;
  }

  bool validateCheckout() {
    if (product.value.merchant == null) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Data merchant tidak valid',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
        isError: true,
      );
      return false;
    }

    if (product.value.variants.isNotEmpty && selectedVariant.value == null) {
      showCustomSnackbar(
        title: 'Pilih Varian',
        message: 'Silakan pilih varian produk terlebih dahulu',
        backgroundColor: logoColorSecondary,
        snackPosition: SnackPosition.BOTTOM,
        isError: true,
      );
      return false;
    }

    if (!product.value.merchant!.isActive) {
      showCustomSnackbar(
        title: 'Merchant Tidak Aktif',
        message: 'Maaf, merchant ini sedang tidak aktif',
        backgroundColor: logoColorSecondary,
        snackPosition: SnackPosition.BOTTOM,
        isError: true,
      );
      return false;
    }

    if (product.value.status != 'ACTIVE') {
      showCustomSnackbar(
        title: 'Produk Tidak Tersedia',
        message: 'Maaf, produk ini sedang tidak tersedia',
        backgroundColor: logoColorSecondary,
        snackPosition: SnackPosition.BOTTOM,
        isError: true,
      );
      return false;
    }

    return true;
  }

  Map<String, dynamic> getCheckoutData() {
    return {
      'product': product.value,
      'quantity': quantity.value,
      'variant': selectedVariant.value,
      'totalPrice': totalPrice,
      'priceAdjustment': selectedVariant.value?.priceAdjustment ?? 0,
      'variantName': selectedVariant.value?.name,
      'variantValue': selectedVariant.value?.value,
    };
  }

  void setProduct(ProductModel newProduct) {
    product.value = newProduct;
    currentImageIndex.value = 0;
    selectedVariant.value = null;
    quantity.value = 1;
    apiReviews.clear();
    selectedRatingFilter.value = 0;
    isExpanded.value = false;
    fetchReviews();
  }

  ProductGalleryModel? getGalleryAtIndex(int index) {
    if (index >= 0 && index < product.value.galleries.length) {
      return product.value.galleries[index];
    }
    return null;
  }

  bool get isProductValid =>
      product.value.id != null && product.value.status == 'ACTIVE';

  String formatReviewDate(DateTime date) =>
      DateFormat('dd/MM/yyyy').format(date);

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null) {
      setProduct(Get.arguments as ProductModel);
    }
  }

  @override
  void onClose() {
    debugPrint('ProductDetailController: Cleaning up...');
    // Clear all data
    product.value = ProductModel(
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
    );
    currentImageIndex.value = 0;
    quantity.value = 1;
    selectedVariant.value = null;
    apiReviews.clear();
    selectedRatingFilter.value = 0;
    isExpanded.value = false;
    isLoadingReviews.value = false;
    super.onClose();
  }
}
