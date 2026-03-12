import 'package:antarkanma/app/data/models/cart_item_model.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/variant_model.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/app/services/cart_sync_service.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CartController extends GetxController {
  static const String cartStorageKey = 'cart_items';
  static const int MAX_QUANTITY = 99;
  final storage = GetStorage();
  final RxMap<int, List<CartItemModel>> merchantItems = <int, List<CartItemModel>>{}.obs;
  final CartSyncService _cartSyncService = Get.find<CartSyncService>();
  final RxBool isSyncing = false.obs;
  final RxBool hasSynced = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCartFromStorage();
    // Sync with server after loading local cart
    _syncWithServer();
  }

  void _loadCartFromStorage() {
    try {
      final cartData = storage.read(cartStorageKey);
      if (cartData != null) {
        final Map<String, dynamic> decodedData = Map<String, dynamic>.from(cartData);
        
        // Clear existing items
        merchantItems.clear();
        
        // Process each merchant's items
        decodedData.forEach((key, value) {
          try {
            final merchantId = int.parse(key);
            final items = (value as List).map((item) {
              final cartItem = CartItemModel.fromJson(item);
              return cartItem;
            }).toList();
            
            if (items.isNotEmpty) {
              merchantItems[merchantId] = items;
            }
          } catch (e) {
            print('Error processing merchant $key: $e');
          }
        });
      }
    } catch (e) {
      print('Error loading cart: $e');
      CustomSnackbarX.showError(
        message: 'Gagal memuat data keranjang',
      );
      merchantItems.clear();
    }
  }

  void _saveCartToStorage() {
    try {
      final validItems = merchantItems.map((key, value) {
        return MapEntry(key.toString(), value.map((item) => item.toJson()).toList());
      });

      if (validItems.isNotEmpty) {
        storage.write(cartStorageKey, validItems);
      } else {
        storage.remove(cartStorageKey);
      }
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  Future<void> _syncWithServer() async {
    try {
      isSyncing.value = true;
      
      // Convert local cart to server format
      final cartData = _convertToServerFormat();
      
      if (cartData.isEmpty) {
        // If local cart is empty, fetch from server
        await _fetchCartFromServer();
      } else {
        // Sync local cart to server
        await _cartSyncService.syncCart(cartData);
        hasSynced.value = true;
        // After syncing, fetch latest from server
        await _fetchCartFromServer();
      }
    } catch (e) {
      print('Error syncing cart with server: $e');
      // Continue with local cart - don't show error to user
    } finally {
      isSyncing.value = false;
    }
  }

  Future<void> _fetchCartFromServer() async {
    try {
      final cartData = await _cartSyncService.getCart();
      final serverItems = _cartSyncService.parseCartItems(cartData);
      
      // Convert server items to local format
      merchantItems.clear();
      for (var item in serverItems) {
        final merchantId = item.merchant.id;
        if (merchantId != null) {
          if (!merchantItems.containsKey(merchantId)) {
            merchantItems[merchantId] = [];
          }
          merchantItems[merchantId]!.add(item);
        }
      }
      
      hasSynced.value = true;
      update();
      print('✅ Cart synced from server: ${serverItems.length} items');
    } catch (e) {
      print('Error fetching cart from server: $e');
      // Continue with local cart
    }
  }

  List<Map<String, dynamic>> _convertToServerFormat() {
    final List<Map<String, dynamic>> cartData = [];
    
    merchantItems.forEach((merchantId, items) {
      if (items.isEmpty) return;
      
      final itemData = <Map<String, dynamic>>[];
      for (var item in items) {
        itemData.add({
          'product_id': item.product.id,
          'variant_id': item.selectedVariant?.id,
          'quantity': item.quantity,
          'is_selected': item.isSelected,
        });
      }
      
      cartData.add({
        'merchant_id': merchantId,
        'items': itemData,
      });
    });
    
    return cartData;
  }

  void addToCart(
    ProductModel product,
    int quantity, {
    VariantModel? selectedVariant,
    required MerchantModel merchant,
  }) {
    try {
      if (!merchant.isActive) {
        CustomSnackbarX.showError(
          title: 'Merchant Tidak Aktif',
          message: 'Merchant ini sedang tidak aktif',
          position: SnackPosition.BOTTOM,
        );
        return;
      }

      final merchantId = merchant.id;
      if (merchantId == null) {
        CustomSnackbarX.showError(
          title: 'Error',
          message: 'Merchant harus memiliki id yang valid',
          position: SnackPosition.BOTTOM,
        );
        return;
      }

      if (!isQuantityValid(quantity)) {
        CustomSnackbarX.showError(
          title: 'Jumlah Tidak Valid',
          message: 'Jumlah harus antara 1 dan $MAX_QUANTITY',
          position: SnackPosition.BOTTOM,
        );
        return;
      }

      if (!merchantItems.containsKey(merchantId)) {
        merchantItems[merchantId] = [];
      }

      final existingItemIndex = merchantItems[merchantId]!.indexWhere((item) =>
          item.product.id == product.id &&
          item.selectedVariant?.id == selectedVariant?.id);

      if (existingItemIndex != -1) {
        final existingItem = merchantItems[merchantId]![existingItemIndex];
        final newQuantity = existingItem.quantity + quantity;

        if (!isQuantityValid(newQuantity)) {
          CustomSnackbarX.showError(
            title: 'Melebihi Batas',
            message: 'Total jumlah tidak boleh melebihi $MAX_QUANTITY',
            position: SnackPosition.BOTTOM,
          );
          return;
        }

        merchantItems[merchantId]![existingItemIndex] = CartItemModel(
          product: existingItem.product,
          quantity: newQuantity,
          selectedVariant: existingItem.selectedVariant,
          merchant: merchant,
          isSelected: existingItem.isSelected,
        );
      } else {
        merchantItems[merchantId]!.add(CartItemModel(
          product: product,
          quantity: quantity,
          selectedVariant: selectedVariant,
          merchant: merchant,
          isSelected: true, // Set new items as selected by default
        ));
      }

      _saveCartToStorage();
      update();

      // Sync to server in background
      _syncWithServer();

      CustomSnackbarX.showSuccess(
        title: 'Berhasil',
        message: 'Produk berhasil ditambahkan ke keranjang',
        position: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error adding to cart: $e');
      CustomSnackbarX.showError(
        title: 'Error',
        message: 'Gagal menambahkan produk ke keranjang',
        position: SnackPosition.BOTTOM,
      );
    }
  }

  void removeFromCart(int merchantId, int index) {
    try {
      if (merchantItems.containsKey(merchantId)) {
        merchantItems[merchantId]!.removeAt(index);
        if (merchantItems[merchantId]!.isEmpty) {
          merchantItems.remove(merchantId);
        }
        _saveCartToStorage();
        update();
      }
    } catch (e) {
      print('Error removing from cart: $e');
      CustomSnackbarX.showError(
        title: 'Error',
        message: 'Gagal menghapus produk dari keranjang',
        position: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> clearCart() async {
    try {
      merchantItems.clear();
      _saveCartToStorage();
      update();
      
      // Clear from server too
      await _cartSyncService.clearCart();
      
      CustomSnackbarX.showSuccess(
        title: 'Berhasil',
        message: 'Keranjang berhasil dikosongkan',
        position: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error clearing cart: $e');
      CustomSnackbarX.showError(
        title: 'Error',
        message: 'Gagal mengosongkan keranjang',
        position: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> markCartAsCheckedOut() async {
    try {
      final merchantIds = merchantItems.keys.toList();
      await _cartSyncService.markAsCheckedOut(merchantIds: merchantIds);
      print('✅ Cart marked as checked out');
    } catch (e) {
      print('Error marking cart as checked out: $e');
      // Don't show error - this is analytics only
    }
  }

  void updateQuantity(int merchantId, int index, int newQuantity) {
    try {
      if (!isQuantityValid(newQuantity)) {
        throw Exception('Quantity tidak valid');
      }

      if (merchantItems.containsKey(merchantId) &&
          index >= 0 &&
          index < merchantItems[merchantId]!.length) {
        final items = merchantItems[merchantId];
        if (items != null) {
          final item = items[index];
          items[index] = CartItemModel(
            product: item.product,
            quantity: newQuantity,
            selectedVariant: item.selectedVariant,
            merchant: item.merchant,
            isSelected: item.isSelected,
          );
          _saveCartToStorage();
          update();
        }
      }
    } catch (e) {
      print('Error updating quantity: $e');
      CustomSnackbarX.showError(
        title: 'Error',
        message: 'Gagal mengupdate jumlah produk',
        position: SnackPosition.BOTTOM,
      );
    }
  }

  void incrementQuantity(int merchantId, int index) {
    if (merchantItems.containsKey(merchantId) &&
        index >= 0 &&
        index < merchantItems[merchantId]!.length) {
      final items = merchantItems[merchantId];
      if (items != null && isQuantityValid(items[index].quantity + 1)) {
        updateQuantity(merchantId, index, items[index].quantity + 1);
      } else {
        CustomSnackbarX.showWarning(
          title: 'Batas Maksimum',
          message: 'Jumlah maksimum telah tercapai',
          position: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void decrementQuantity(int merchantId, int index) {
    if (merchantItems.containsKey(merchantId) &&
        index >= 0 &&
        index < merchantItems[merchantId]!.length) {
      final items = merchantItems[merchantId];
      if (items != null && items[index].quantity > 1) {
        updateQuantity(merchantId, index, items[index].quantity - 1);
      } else {
        CustomSnackbarX.showWarning(
          title: 'Batas Minimum',
          message: 'Jumlah minimum telah tercapai',
          position: SnackPosition.BOTTOM,
        );
      }
    }
  }

  void toggleItemSelection(int merchantId, int index) {
    if (merchantItems.containsKey(merchantId) &&
        index >= 0 &&
        index < merchantItems[merchantId]!.length) {
      final items = merchantItems[merchantId];
      if (items != null) {
        final item = items[index];
        items[index] = CartItemModel(
          product: item.product,
          quantity: item.quantity,
          selectedVariant: item.selectedVariant,
          merchant: item.merchant,
          isSelected: !item.isSelected,
        );
        _saveCartToStorage();
        update();
      }
    }
  }

  double get selectedItemsTotal {
    double total = 0;
    merchantItems.forEach((merchantId, items) {
      total += items
          .where((item) => item.isSelected)
          .fold(0.0, (sum, item) => sum + item.totalPrice);
    });
    return total;
  }

  int get selectedItemCount {
    return merchantItems.values.fold(
        0, (sum, items) => sum + items.where((item) => item.isSelected).length);
  }

  List<CartItemModel> get selectedItems {
    List<CartItemModel> selected = [];
    merchantItems.forEach((merchantId, items) {
      selected.addAll(items.where((item) => item.isSelected));
    });
    return selected;
  }

  Map<int, List<CartItemModel>> get selectedItemsByMerchant {
    final Map<int, List<CartItemModel>> result = {};
    merchantItems.forEach((merchantId, items) {
      final selectedItems = items.where((item) => item.isSelected).toList();
      if (selectedItems.isNotEmpty) {
        result[merchantId] = selectedItems;
      }
    });
    return result;
  }

  double get totalPrice {
    double total = 0;
    merchantItems.forEach((merchantId, items) {
      total += getMerchantTotal(merchantId);
    });
    return total;
  }

  int get itemCount {
    return merchantItems.values.fold(0, (sum, items) => sum + items.length);
  }

  double getMerchantTotal(int merchantId) {
    if (!merchantItems.containsKey(merchantId)) return 0;
    return merchantItems[merchantId]!
        .fold(0, (sum, item) => sum + item.totalPrice);
  }

  int getMerchantItemCount(int merchantId) {
    if (!merchantItems.containsKey(merchantId)) return 0;
    return merchantItems[merchantId]!
        .fold(0, (sum, item) => sum + item.quantity);
  }

  bool validateCart() {
    if (selectedItems.isEmpty) {
      CustomSnackbarX.showError(
        title: 'Tidak Ada Item Dipilih',
        message: 'Silakan pilih produk yang ingin dicheckout',
        position: SnackPosition.BOTTOM,
      );
      return false;
    }

    bool allMerchantsActive = merchantItems.keys.every((merchantId) {
      final merchant = merchantItems[merchantId]!.first.merchant;
      if (!merchant.isActive) {
        CustomSnackbarX.showError(
          title: 'Merchant Tidak Aktif',
          message: 'Merchant ${merchant.name} sedang tidak aktif',
          position: SnackPosition.BOTTOM,
        );
        return false;
      }
      return true;
    });

    return allMerchantsActive;
  }

  bool isQuantityValid(int quantity) {
    return quantity > 0 && quantity <= MAX_QUANTITY;
  }

  void undoRemove(int merchantId, int index, CartItemModel item) {
    if (merchantItems.containsKey(merchantId)) {
      merchantItems[merchantId]!.insert(index, item);
    } else {
      merchantItems[merchantId] = [item];
    }
    update();
  }

  @override
  void onClose() {
    _saveCartToStorage();
    super.onClose();
  }
}
