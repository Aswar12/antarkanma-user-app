import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/providers/wishlist_provider.dart';
import 'package:antarkanma/app/services/auth_service.dart';

class WishlistController extends GetxController {
  final WishlistProvider _provider = WishlistProvider();
  final AuthService _authService = Get.find<AuthService>();

  final RxList<ProductModel> wishlistProducts = <ProductModel>[].obs;
  final RxList<int> wishlistIds = <int>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWishlist();
  }

  String? get _token => _authService.getToken();

  bool isWishlisted(int productId) => wishlistIds.contains(productId);

  /// Fetch full wishlist from backend
  Future<void> fetchWishlist() async {
    final token = _token;
    if (token == null) return;

    try {
      isLoading.value = true;
      final response = await _provider.getWishlist(token);

      if (response.statusCode == 200 && response.data != null) {
        final meta = response.data['meta'];
        if (meta != null && meta['status'] == 'success') {
          final List data = response.data['data'] ?? [];
          wishlistProducts.value =
              data.map((json) => ProductModel.fromJson(json)).toList();
          wishlistIds.value =
              wishlistProducts.map((p) => p.id).whereType<int>().toList();
          debugPrint('✅ Wishlist loaded: ${wishlistIds.length} items');
        }
      }
    } catch (e) {
      debugPrint('❌ Error fetching wishlist: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Toggle wishlist — optimistic update with rollback on failure
  Future<void> toggleWishlist(int productId, {ProductModel? product}) async {
    final token = _token;
    if (token == null) return;

    // Optimistic update
    final wasWishlisted = wishlistIds.contains(productId);
    if (wasWishlisted) {
      wishlistIds.remove(productId);
      wishlistProducts.removeWhere((p) => p.id == productId);
    } else {
      wishlistIds.add(productId);
      if (product != null) {
        wishlistProducts.insert(0, product);
      }
    }

    try {
      final response = await _provider.toggleWishlist(productId, token);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          final isNowWishlisted = data['is_wishlisted'] == true;
          // Reconcile if server state differs
          if (isNowWishlisted && !wishlistIds.contains(productId)) {
            wishlistIds.add(productId);
          } else if (!isNowWishlisted && wishlistIds.contains(productId)) {
            wishlistIds.remove(productId);
            wishlistProducts.removeWhere((p) => p.id == productId);
          }
        }
      }
    } catch (e) {
      // Rollback on failure
      debugPrint('❌ Toggle wishlist failed, rolling back: $e');
      if (wasWishlisted) {
        wishlistIds.add(productId);
        if (product != null) wishlistProducts.insert(0, product);
      } else {
        wishlistIds.remove(productId);
        wishlistProducts.removeWhere((p) => p.id == productId);
      }
    }
  }

  /// Batch check products (useful when loading a product list)
  Future<void> checkProducts(List<int> productIds) async {
    final token = _token;
    if (token == null || productIds.isEmpty) return;

    try {
      final response = await _provider.checkWishlist(productIds, token);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        if (data != null) {
          final List ids = data['wishlisted_product_ids'] ?? [];
          for (final id in ids) {
            final intId = id is int ? id : int.parse(id.toString());
            if (!wishlistIds.contains(intId)) {
              wishlistIds.add(intId);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking wishlist: $e');
    }
  }
}
