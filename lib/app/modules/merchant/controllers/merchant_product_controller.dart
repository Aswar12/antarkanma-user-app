import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/services/merchant_service.dart';

class MerchantProductController extends GetxController {
  var products = <ProductModel>[].obs;
  var filteredProducts = <ProductModel>[].obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var searchQuery = ''.obs;
  var selectedCategory = 'Semua'.obs;
  var selectedSort = 'Baru'.obs;
  var showActiveOnly = false.obs;

  final MerchantService merchantService;

  MerchantProductController({required this.merchantService});

  @override
  void onInit() {
    fetchProducts();
    super.onInit();
  }

  void fetchProducts() async {
    try {
      isLoading(true);
      var fetchedProducts = await merchantService.getMerchantProducts();
      products.assignAll(fetchedProducts);
      _applyFilters();
    } catch (e) {
      errorMessage.value = 'Failed to load products: $e';
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
    selectedSort.value = sortType;
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

    // Apply active only filter
    if (showActiveOnly.value) {
      filtered = filtered.where((product) => product.isActive).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      switch (selectedSort.value) {
        case 'A-Z':
          return a.name.compareTo(b.name);
        case 'Z-A':
          return b.name.compareTo(a.name);
        case '↑':
          return b.price.compareTo(a.price);
        case '↓':
          return a.price.compareTo(b.price);
        default:
          return 0;
      }
    });

    filteredProducts.assignAll(filtered);
  }

  void addProduct(ProductModel product) {
    products.add(product);
    _applyFilters();
  }

  void updateProduct(ProductModel product) {
    var index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product;
      _applyFilters();
    }
  }

  void deleteProduct(int productId) {
    products.removeWhere((p) => p.id == productId);
    _applyFilters();
  }
}
