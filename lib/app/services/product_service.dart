// ignore_for_file: dead_code, avoid_print, unrelated_type_equality_checks

import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/providers/product_provider.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import './storage_service.dart';
import 'package:http_parser/http_parser.dart';

import 'package:dio/dio.dart' as dio;

class ProductService extends GetxService {
  final StorageService _storageService = StorageService.instance;
  final ProductProvider _productProvider = ProductProvider();

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final Rx<ProductModel?> selectedProduct = Rx<ProductModel?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;

      final storage = GetStorage();
      final storedProducts = storage.read('products');
      final lastRefresh = storage.read('last_refresh');

      final shouldRefresh = lastRefresh == null ||
          DateTime.now().difference(DateTime.parse(lastRefresh)).inHours > 1;

      if (storedProducts != null && storedProducts is List && !shouldRefresh) {
        products.value = (storedProducts)
            .map((json) => ProductModel.fromJson(json))
            .toList();
      } else {
        await refreshProducts();
      }
    } catch (e) {
      print('Error in fetchProducts: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal mengambil data produk: ${e.toString()}',
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<ProductModel?> getProductById(int id) async {
    try {
      final token = _storageService.getToken();
      final response = await _productProvider.getProductById(id, token: token);

      if (response.statusCode == 200) {
        final productData = response.data['data'];
        return ProductModel.fromJson(productData);
      }
      return null;
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal mengambil detail produk: ${e.toString()}',
        isError: true,
      );
      return null;
    }
  }

  Future<bool> createProduct(Map<String, dynamic> productData) async {
    try {
      final token = _storageService.getToken();
      if (token == null) {
        showCustomSnackbar(
          title: 'Error',
          message: 'Anda harus login terlebih dahulu',
          isError: true,
        );
        return false;
      }

      final response = await _productProvider.createProduct(productData, token);

      if (response.statusCode == 201) {
        showCustomSnackbar(
          title: 'Sukses',
          message: 'Produk berhasil ditambahkan',
        );
        await fetchProducts(); // Refresh product list
        return true;
      }

      showCustomSnackbar(
        title: 'Error',
        message: response.data['message'] ?? 'Gagal menambahkan produk',
        isError: true,
      );
      return false;
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal menambahkan produk: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  Future<void> refreshProducts() async {
    try {
      isLoading.value = true;
      final token = _storageService.getToken();
      final response = await _productProvider.getAllProducts(token: token);

      if (response.statusCode == 200) {
        final productList = response.data['data']['data'] as List;
        products.value =
            productList.map((json) => ProductModel.fromJson(json)).toList();

        // Update local storage
        final storage = GetStorage();
        await storage.write('products', productList);

        // Update last refresh time
        await storage.write('last_refresh', DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Error in refreshProducts: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal memperbarui data produk: ${e.toString()}',
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> productData) async {
    try {
      final token = _storageService.getToken();
      if (token == null) {
        showCustomSnackbar(
          title: 'Error',
          message: 'Anda harus login terlebih dahulu',
          isError: true,
        );
        return false;
      }

      final response =
          await _productProvider.updateProduct(id, productData, token);

      if (response.statusCode == 200) {
        showCustomSnackbar(
          title: 'Sukses',
          message: 'Produk berhasil diperbarui',
        );
        await fetchProducts(); // Refresh product list
        return true;
      }

      showCustomSnackbar(
        title: 'Error',
        message: response.data['message'] ?? 'Gagal memperbarui produk',
        isError: true,
      );
      return false;
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal memperbarui produk: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final token = _storageService.getToken();
      if (token == null) {
        showCustomSnackbar(
          title: 'Error',
          message: 'Anda harus login terlebih dahulu',
          isError: true,
        );
        return false;
      }

      final response = await _productProvider.deleteProduct(id, token);

      if (response.statusCode == 200) {
        showCustomSnackbar(
          title: 'Sukses',
          message: 'Produk berhasil dihapus',
        );
        await fetchProducts(); // Refresh product list
        return true;
      }

      showCustomSnackbar(
        title: 'Error',
        message: response.data['message'] ?? 'Gagal menghapus produk',
        isError: true,
      );
      return false;
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal menghapus produk: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final token = _storageService.getToken();
      final response =
          await _productProvider.searchProducts(query, token: token);

      if (response.statusCode == 200) {
        final List<dynamic> productList = response.data['data'];
        return productList.map((json) => ProductModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal mencari produk: ${e.toString()}',
        isError: true,
      );
      return [];
    }
  }

  Future<List<ProductModel>> getProductsByCategory(int categoryId) async {
    try {
      final token = _storageService.getToken();
      final response = await _productProvider.getProductsByCategory(
        categoryId,
        token: token,
      );

      if (response.statusCode == 200) {
        final List<dynamic> productList = response.data['data'];
        return productList.map((json) => ProductModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal mengambil produk berdasarkan kategori: ${e.toString()}',
        isError: true,
      );
      return [];
    }
  }

  Future<List<ProductModel>> getProductsByMerchant(int merchantId) async {
    try {
      final token = _storageService.getToken();
      final response = await _productProvider.getProductsByMerchant(
        merchantId,
        token: token,
      );

      if (response.statusCode == 200) {
        final List<dynamic> productList = response.data['data'];
        return productList.map((json) => ProductModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal mengambil produk merchant: ${e.toString()}',
        isError: true,
      );
      return [];
    }
  }

  Future<bool> uploadProductImage(int productId, dynamic imageFile) async {
    try {
      final token = _storageService.getToken();
      if (token == null) {
        showCustomSnackbar(
          title: 'Error',
          message: 'Anda harus login terlebih dahulu',
          isError: true,
        );
        return false;
      }

      String fileName = imageFile.path.split('/').last;

      // Buat FormData menggunakan dio.FormData
      final formData = dio.FormData.fromMap({
        'product_id': productId.toString(),
        'image': await dio.MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _productProvider.uploadProductImage(
        productId,
        formData,
        token,
      );

      if (response.statusCode == 200) {
        showCustomSnackbar(
          title: 'Sukses',
          message: 'Gambar produk berhasil diunggah',
        );
        await fetchProducts();
        return true;
      }

      showCustomSnackbar(
        title: 'Error',
        message: response.data['message'] ?? 'Gagal mengunggah gambar produk',
        isError: true,
      );
      return false;
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal mengunggah gambar produk: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  Future<bool> deleteProductImage(int productId, int imageId) async {
    try {
      final token = _storageService.getToken();
      if (token == null) {
        showCustomSnackbar(
          title: 'Error',
          message: 'Anda harus login terlebih dahulu',
          isError: true,
        );
        return false;
      }

      final response = await _productProvider.deleteProductImage(
        productId,
        imageId,
        token,
      );

      if (response.statusCode == 200) {
        showCustomSnackbar(
          title: 'Sukses',
          message: 'Gambar produk berhasil dihapus',
        );
        await fetchProducts(); // Refresh product list
        return true;
      }

      showCustomSnackbar(
        title: 'Error',
        message: response.data['message'] ?? 'Gagal menghapus gambar produk',
        isError: true,
      );
      return false;
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal menghapus gambar produk: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  // Helper methods
  void setSelectedProduct(ProductModel product) {
    selectedProduct.value = product;
  }

  void clearSelectedProduct() {
    selectedProduct.value = null;
  }

  List<ProductModel> get productsList => products;

  ProductModel? get currentProduct => selectedProduct.value;

  void handleProductError(dynamic error) {
    if (error.toString().contains('401')) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Sesi Anda telah berakhir. Silakan login kembali.',
        isError: true,
      );
      // Redirect to login or handle unauthorized access
    }
  }

  // Method untuk validasi data produk
  String? validateProductData(Map<String, dynamic> productData) {
    if (productData['name']?.isEmpty ?? true) {
      return 'Nama produk tidak boleh kosong';
    }
    if (productData['price'] == null || productData['price'] <= 0) {
      return 'Harga produk tidak valid';
    }
    if (productData['description']?.isEmpty ?? true) {
      return 'Deskripsi produk tidak boleh kosong';
    }
    // Tambahkan validasi lain sesuai kebutuhan
    return null;
  }

  // Method untuk filter produk
  List<ProductModel> filterProducts({
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    String? category,
    // Tambahkan parameter filter lainnya
  }) {
    return products.where((product) {
      bool matchesSearch = searchQuery?.isEmpty ??
          true ||
              product.name.toLowerCase().contains(searchQuery!.toLowerCase());
      bool matchesPrice = (minPrice == null || product.price >= minPrice) &&
          (maxPrice == null || product.price <= maxPrice);
      bool matchesCategory =
          category?.isEmpty ?? true || product.category == category;

      return matchesSearch && matchesPrice && matchesCategory;
    }).toList();
  }

  // Method untuk sorting produk
  List<ProductModel> sortProducts({
    required String sortBy,
    bool ascending = true,
  }) {
    List<ProductModel> sortedList = List.from(products);
    switch (sortBy) {
      case 'name':
        sortedList.sort((a, b) =>
            ascending ? a.name.compareTo(b.name) : b.name.compareTo(a.name));
        break;
      case 'price':
        sortedList.sort((a, b) => ascending
            ? a.price.compareTo(b.price)
            : b.price.compareTo(a.price));
        break;
      case 'date':
        sortedList.sort((a, b) => ascending
            ? (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0))
            : (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)));
        break;
      // Tambahkan case sorting lainnya
    }
    return sortedList;
  }

  // Method untuk dispose
  @override
  void onClose() {
    products.close();
    selectedProduct.close();
    isLoading.close();
    super.onClose();
  }
}
