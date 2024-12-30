import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/variant_model.dart';
import 'package:antarkanma/app/data/models/product_category_model.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/services/product_category_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:image_picker/image_picker.dart';

class MerchantProductFormController extends GetxController {
  final MerchantService merchantService;
  final ProductCategoryService _categoryService =
      Get.find<ProductCategoryService>();
  final formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();

  final selectedCategoryId = RxnInt();
  final selectedCategoryName = RxnString();
  final categories = <ProductCategory>[].obs;
  final variants = <VariantModel>[].obs;
  final isActive = true.obs;
  final images = <XFile>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  MerchantProductFormController({required this.merchantService});

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.onClose();
  }

  Future<void> loadCategories() async {
    try {
      isLoading(true);
      // Get categories from ProductCategoryService
      final loadedCategories = await _categoryService.getCategories();
      print('Loaded categories: ${loadedCategories.length}'); // Debug print
      categories.assignAll(loadedCategories);
    } catch (e) {
      print('Error loading categories: $e'); // Debug print
      errorMessage.value = 'Failed to load categories: $e';
      CustomSnackbarX.showError(message: 'Failed to load categories');
    } finally {
      isLoading(false);
    }
  }

  void setInitialData(Map<String, dynamic>? product) {
    if (product != null) {
      nameController.text = product['name'] ?? '';
      descriptionController.text = product['description'] ?? '';
      priceController.text = product['price']?.toString() ?? '';

      if (product['category'] != null) {
        selectedCategoryId.value = product['category']['id'];
        selectedCategoryName.value = product['category']['name'];
      }

      if (product['variants'] != null) {
        variants.assignAll(
          (product['variants'] as List)
              .map((v) => VariantModel.fromJson(v))
              .toList(),
        );
      }

      isActive.value = product['status'] ?? true;
    }
  }

  void setCategory(ProductCategory category) {
    print('Setting category: ${category.name}'); // Debug print
    selectedCategoryId.value = category.id;
    selectedCategoryName.value = category.name;
  }

  Future<void> pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> selectedImages = await picker.pickMultiImage();
      if (selectedImages.isNotEmpty) {
        images.addAll(selectedImages);
      }
    } catch (e) {
      print('Error picking images: $e');
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
    }
  }

  void addVariant(VariantModel variant) {
    variants.add(variant);
  }

  void updateVariant(int index, VariantModel variant) {
    if (index >= 0 && index < variants.length) {
      variants[index] = variant;
    }
  }

  void removeVariant(VariantModel variant) {
    variants.remove(variant);
  }

  Future<bool> saveProduct() async {
    if (!formKey.currentState!.validate()) return false;
    if (selectedCategoryId.value == null) {
      errorMessage.value = 'Pilih kategori produk';
      CustomSnackbarX.showError(message: 'Pilih kategori produk');
      return false;
    }
    if (images.isEmpty) {
      errorMessage.value = 'Tambahkan minimal 1 foto produk';
      CustomSnackbarX.showError(message: 'Tambahkan minimal 1 foto produk');
      return false;
    }

    try {
      isLoading(true);
      final productData = {
        'name': nameController.text,
        'description': descriptionController.text,
        'price': double.tryParse(priceController.text) ?? 0,
        'category_id': selectedCategoryId.value,
        'status': isActive.value ? 'ACTIVE' : 'INACTIVE',
        'variants': variants.map((v) => v.toJson()).toList(),
      };

      final result = await merchantService.createProduct(productData, images);

      if (result) {
        CustomSnackbarX.showSuccess(
            title: 'Sukses', message: 'Produk berhasil ditambahkan');
        Get.back(result: true);
        return true;
      } else {
        errorMessage.value = 'Gagal menyimpan produk';
        CustomSnackbarX.showError(
            title: 'Error', message: 'Gagal menyimpan produk');
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Gagal menyimpan produk: $e';
      CustomSnackbarX.showError(
          title: 'Error', message: 'Gagal menyimpan produk: $e');
      return false;
    } finally {
      isLoading(false);
    }
  }
}
