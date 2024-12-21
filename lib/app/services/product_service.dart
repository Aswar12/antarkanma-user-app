import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/providers/product_provider.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ProductService extends GetxService {
  final ProductProvider _productProvider = ProductProvider();
  final _storage = GetStorage();
  static const String _productsKey = 'products';
  static const String _lastRefreshKey = 'last_refresh';

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final storedProducts = _storage.read(_productsKey);
      final lastRefresh = _storage.read(_lastRefreshKey);

      final shouldRefresh = lastRefresh == null ||
          DateTime.now().difference(DateTime.parse(lastRefresh)).inHours > 1;

      if (storedProducts != null && !shouldRefresh) {
        try {
          final List<dynamic> productList = storedProducts;
          products.value = productList
              .map(
                  (json) => ProductModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          print('Error parsing stored products: $e');
          await refreshProducts();
        }
      } else {
        await refreshProducts();
      }
    } catch (e) {
      print('Error in fetchProducts: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to load products: ${e.toString()}',
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProducts() async {
    try {
      final response = await _productProvider.getAllProducts();

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        // Convert to List<ProductModel>
        products.value = productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Save to local storage
        await _storage.write(_productsKey, productList);
        await _storage.write(_lastRefreshKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Error in refreshProducts: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to refresh products: ${e.toString()}',
        isError: true,
      );
    }
  }

  List<ProductModel> get productsList => products;

  bool hasLocalData() {
    return _storage.hasData(_productsKey);
  }

  Future<void> clearLocalStorage() async {
    await _storage.remove(_productsKey);
    await _storage.remove(_lastRefreshKey);
    products.clear();
  }
}
