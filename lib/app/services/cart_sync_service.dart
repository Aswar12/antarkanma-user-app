import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/providers/api_provider.dart';
import 'package:antarkanma/app/data/models/cart_item_model.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/variant_model.dart';

class CartSyncService extends GetxService {
  late final ApiProvider _apiProvider;
  static const String _baseUrl = '/cart';

  CartSyncService() {
    _apiProvider = Get.find<ApiProvider>();
  }

  /// Get synced cart from server
  Future<Map<String, dynamic>> getCart() async {
    try {
      debugPrint('🛒 Fetching synced cart from server');
      final response = await _apiProvider.get(_baseUrl);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          debugPrint('✅ Cart synced successfully: ${data['data']}');
          return data['data'];
        }
      }
      throw Exception('Failed to sync cart');
    } catch (e) {
      debugPrint('❌ Error fetching cart: $e');
      rethrow;
    }
  }

  /// Sync cart to server
  Future<Map<String, dynamic>> syncCart(List<Map<String, dynamic>> cart) async {
    try {
      debugPrint('🛒 Syncing cart to server: ${cart.length} merchants');
      final response = await _apiProvider.post(
        '$_baseUrl/sync',
        data: {'cart': cart},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          debugPrint('✅ Cart synced successfully');
          return data['data'];
        }
      }
      throw Exception('Failed to sync cart');
    } catch (e) {
      debugPrint('❌ Error syncing cart: $e');
      rethrow;
    }
  }

  /// Update cart item
  Future<void> updateItem(int itemId, {int? quantity, bool? isSelected}) async {
    try {
      debugPrint('✏️ Updating cart item $itemId');
      final Map<String, dynamic> updateData = {};
      if (quantity != null) updateData['quantity'] = quantity;
      if (isSelected != null) updateData['is_selected'] = isSelected;

      await _apiProvider.put(
        '$_baseUrl/items/$itemId',
        data: updateData,
      );
      debugPrint('✅ Cart item updated');
    } catch (e) {
      debugPrint('❌ Error updating cart item: $e');
      rethrow;
    }
  }

  /// Remove items from cart
  Future<void> removeFromCart(List<int> itemIds) async {
    try {
      debugPrint('🗑️ Removing ${itemIds.length} items from cart');
      await _apiProvider.post(
        '$_baseUrl/remove',
        data: {'item_ids': itemIds},
      );
      debugPrint('✅ Items removed from cart');
    } catch (e) {
      debugPrint('❌ Error removing items: $e');
      rethrow;
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      debugPrint('🗑️ Clearing entire cart');
      await _apiProvider.post('$_baseUrl/clear');
      debugPrint('✅ Cart cleared');
    } catch (e) {
      debugPrint('❌ Error clearing cart: $e');
      rethrow;
    }
  }

  /// Mark cart as checked out (for analytics)
  Future<void> markAsCheckedOut({List<int>? merchantIds}) async {
    try {
      debugPrint('✅ Marking cart as checked out');
      final Map<String, dynamic> data = {};
      if (merchantIds != null) {
        data['merchant_ids'] = merchantIds;
      }
      await _apiProvider.post(
        '$_baseUrl/mark-checked-out',
        data: data,
      );
      debugPrint('✅ Cart marked as checked out');
    } catch (e) {
      debugPrint('❌ Error marking cart as checked out: $e');
      // Don't throw - this is analytics, shouldn't block checkout
    }
  }

  /// Convert server cart response to local CartItemModel format
  List<CartItemModel> parseCartItems(Map<String, dynamic> cartData) {
    final List<CartItemModel> items = [];

    if (cartData['cart'] == null) return items;

    final List<dynamic> merchants = cartData['cart'];

    for (var merchantData in merchants) {
      final merchant = MerchantModel(
        id: merchantData['merchant_id'],
        name: merchantData['merchant_name'] ?? '',
        address: merchantData['merchant_address'] ?? '',
        phoneNumber: merchantData['merchant_phone'] ?? '',
        logo: merchantData['merchant_logo'],
        status: (merchantData['merchant_is_active'] == true) ? 'active' : 'inactive',
      );

      final List<dynamic> merchantItems = merchantData['items'] ?? [];

      for (var itemData in merchantItems) {
        try {
          final cartItem = CartItemModel(
            product: ProductModel.fromJson(itemData['product'] ?? {}),
            quantity: itemData['quantity'] ?? 1,
            selectedVariant: itemData['variant'] != null
                ? VariantModel.fromJson(itemData['variant'])
                : null,
            merchant: merchant,
            isSelected: itemData['is_selected'] ?? true,
          );
          items.add(cartItem);
        } catch (e) {
          debugPrint('⚠️ Error parsing cart item: $e');
        }
      }
    }

    return items;
  }
}
