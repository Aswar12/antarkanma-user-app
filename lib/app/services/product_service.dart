import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/paginated_response.dart';
import 'package:antarkanma/app/data/providers/product_provider.dart';

class ProductService extends GetxService {
  late final ProductProvider _productProvider;
  final RxList<ProductModel> _localProducts = <ProductModel>[].obs;

  ProductService() {
    _productProvider = Get.find<ProductProvider>();
  }

  void addProductToLocal(ProductModel product) {
    if (!_localProducts.contains(product)) {
      _localProducts.add(product);
    }
  }

  List<ProductModel> get localProducts => _localProducts.toList();

  void clearLocalProducts() {
    _localProducts.clear();
  }

  Future<PaginatedResponse<ProductModel>> getAllProducts({
    String? query,
    String? description,
    List<String>? tags,
    double? priceFrom,
    double? priceTo,
    double? rateFrom,
    double? rateTo,
    int? categoryId,
    String? token,
    String? cursor,
    int? page,
    int pageSize = 10,
  }) async {
    try {
      debugPrint('📤 Getting all products');
      final response = await _productProvider.getAllProducts(
        query: query,
        priceFrom: priceFrom,
        priceTo: priceTo,
        categoryId: categoryId,
        token: token,
        cursor: cursor,
        pageSize: pageSize,
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('📥 Response received successfully');
        return PaginatedResponse<ProductModel>.fromJson(
          response.data,
          (json) => ProductModel.fromJson(json),
        );
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      debugPrint('❌ Error fetching products: $e');
      rethrow;
    }
  }

  Future<ProductModel> getProductById(int id, {String? token}) async {
    try {
      final response = await _productProvider.getProductById(id, token: token);

      if (response.data != null && response.data['data'] != null) {
        return ProductModel.fromJson(response.data['data']);
      }
      throw Exception('Product data not found');
    } catch (e) {
      debugPrint('Error fetching product: $e');
      rethrow;
    }
  }

  Future<PaginatedResponse<ProductModel>> getProductsByCategory(
    int categoryId, {
    String? token,
    String? cursor,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _productProvider.getProductsByCategory(
        categoryId,
        token: token,
        cursor: cursor,
        pageSize: pageSize,
      );

      return PaginatedResponse<ProductModel>.fromJson(
        response.data,
        (json) => ProductModel.fromJson(json),
      );
    } catch (e) {
      debugPrint('Error fetching products by category: $e');
      rethrow;
    }
  }

  Future<void> clearLocalStorage() async {
    clearLocalProducts();
    debugPrint('Local storage cleared');
  }
}
