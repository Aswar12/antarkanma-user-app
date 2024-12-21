import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/product_gallery_model.dart';
import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/data/models/variant_model.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ProductDetailController extends GetxController {
  final RxInt currentImageIndex = RxInt(0);
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

  List<String> get imageUrls {
    return product.value.imageUrls;
  }

  int get imageCount {
    return product.value.galleries.length;
  }

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

    // Check variant selection first
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
  }

  ProductGalleryModel? getGalleryAtIndex(int index) {
    if (index >= 0 && index < product.value.galleries.length) {
      return product.value.galleries[index];
    }
    return null;
  }

  List<ProductReviewModel>? get reviews => product.value.reviews;

  bool get isProductValid {
    return product.value.id != null && product.value.status == 'ACTIVE';
  }

  int? get reviewCount => reviews?.length;

  double get averageRating {
    if (reviews == null || reviews!.isEmpty) return 0;
    double total = reviews!.fold(0, (sum, review) => sum + review.rating);
    return total / reviews!.length;
  }

  String formatReviewDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments != null) {
      setProduct(Get.arguments as ProductModel);
    }
  }

  @override
  void onClose() {
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
    super.onClose();
  }
}
