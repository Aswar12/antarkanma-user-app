import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/services/merchant_service.dart';

class MerchantProductController extends GetxController {
  final MerchantService merchantService;
  
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var products = <ProductModel>[].obs;
  var filteredProducts = <ProductModel>[].obs;
  var showActiveOnly = false.obs;
  var searchQuery = ''.obs;
  var selectedCategory = 'Semua'.obs;
  var sortBy = 'Baru'.obs;
  var categories = <String>[].obs;

  final searchController = TextEditingController();

  MerchantProductController({required this.merchantService});

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchProducts() async {
    try {
      isLoading(true);
      errorMessage('');
      final fetchedProducts = await merchantService.getMerchantProducts();
      products.assignAll(fetchedProducts);
      
      // Extract unique categories
      final uniqueCategories = fetchedProducts
          .where((p) => p.category != null)
          .map((p) => p.category!.name)
          .toSet()
          .toList();
      categories.assignAll(uniqueCategories);
      
      _applyFilters();
    } catch (e) {
      errorMessage('Gagal memuat produk: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      isLoading(true);
      final result = await merchantService.deleteProduct(productId);
      if (result['success']) {
        // Remove the product from the lists
        products.removeWhere((product) => product.id == productId);
        filteredProducts.removeWhere((product) => product.id == productId);
      }
      return result;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting product: $e'
      };
    } finally {
      isLoading(false);
    }
  }

  void searchProducts(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void filterByCategory(String category) {
    selectedCategory.value = category;
    _applyFilters();
  }

  void sortProducts(String sortType) {
    sortBy.value = sortType;
    _applyFilters();
  }

  void toggleActiveOnly(bool value) {
    showActiveOnly.value = value;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<ProductModel>.from(products);

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((product) =>
          product.name.toLowerCase().contains(searchQuery.value.toLowerCase())).toList();
    }

    // Apply category filter
    if (selectedCategory.value != 'Semua') {
      filtered = filtered.where((product) =>
          product.category?.name == selectedCategory.value).toList();
    }

    // Apply active filter
    if (showActiveOnly.value) {
      filtered = filtered.where((product) => product.isActive).toList();
    }

    // Apply sorting
    switch (sortBy.value) {
      case 'A-Z':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Z-A':
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'price_asc':
        filtered.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
        break;
      case 'price_desc':
        filtered.sort((a, b) => (b.price ?? 0).compareTo(a.price ?? 0));
        break;
      case 'Baru':
      default:
        filtered.sort((a, b) => 
          (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
    }

    filteredProducts.assignAll(filtered);
  }
}
