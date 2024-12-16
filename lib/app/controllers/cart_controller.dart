// ignore_for_file: constant_identifier_names, avoid_print

import 'package:antarkanma/app/data/models/cart_item_model.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/variant_model.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class CartController extends GetxController {
  static const String CART_STORAGE_KEY = 'cart_items';
  static const int MAX_QUANTITY = 99;
  final storage = GetStorage();
  final RxMap<int, List<CartItemModel>> merchantItems =
      <int, List<CartItemModel>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCartFromStorage();
  }

  void _loadCartFromStorage() {
    try {
      final cartData = storage.read(CART_STORAGE_KEY);
      if (cartData != null) {
        final Map<String, dynamic> decodedData =
            Map<String, dynamic>.from(cartData);
        merchantItems.value = decodedData.map((key, value) {
          return MapEntry(
            int.parse(key),
            (value as List)
                .map((item) => CartItemModel.fromJson(item))
                .toList(),
          );
        });
      }
    } catch (e) {
      print('Error loading cart: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal memuat data keranjang',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _saveCartToStorage() {
    try {
      final cartData = merchantItems.map((key, value) {
        return MapEntry(
          key.toString(),
          value.map((item) => item.toJson()).toList(),
        );
      });
      storage.write(CART_STORAGE_KEY, cartData);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  void addToCart(
    ProductModel product,
    int quantity, {
    VariantModel? selectedVariant,
    required MerchantModel merchant,
  }) {
    try {
      if (!merchant.isActive) {
        showCustomSnackbar(
          title: 'Merchant Tidak Aktif',
          message: 'Merchant ini sedang tidak aktif',
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final merchantId = merchant.id;
      if (merchantId == null) {
        throw Exception('ID Merchant tidak valid');
      }

      if (!isQuantityValid(quantity)) {
        showCustomSnackbar(
          title: 'Jumlah Tidak Valid',
          message: 'Jumlah harus antara 1 dan $MAX_QUANTITY',
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
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
          showCustomSnackbar(
            title: 'Melebihi Batas',
            message: 'Total jumlah tidak boleh melebihi $MAX_QUANTITY',
            backgroundColor: Colors.red,
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }

        merchantItems[merchantId]![existingItemIndex] = CartItemModel(
          product: existingItem.product,
          quantity: newQuantity,
          selectedVariant: existingItem.selectedVariant,
          merchant: merchant,
        );
      } else {
        merchantItems[merchantId]!.add(CartItemModel(
          product: product,
          quantity: quantity,
          selectedVariant: selectedVariant,
          merchant: merchant,
        ));
      }

      _saveCartToStorage();
      update();

      showCustomSnackbar(
        title: 'Berhasil',
        message: 'Produk berhasil ditambahkan ke keranjang',
        backgroundColor: logoColorSecondary,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('Error adding to cart: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal menambahkan produk ke keranjang',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
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
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal menghapus produk dari keranjang',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void clearCart() {
    try {
      merchantItems.clear();
      _saveCartToStorage();
      update();
    } catch (e) {
      print('Error clearing cart: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal mengosongkan keranjang',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
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
          );
          _saveCartToStorage();
          update();
        }
      }
    } catch (e) {
      print('Error updating quantity: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal mengupdate jumlah produk',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
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
        showCustomSnackbar(
          title: 'Batas Maksimum',
          message: 'Jumlah maksimum telah tercapai',
          backgroundColor: Colors.orange,
          snackPosition: SnackPosition.BOTTOM,
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
        showCustomSnackbar(
          title: 'Batas Minimum',
          message: 'Jumlah minimum telah tercapai',
          backgroundColor: Colors.orange,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
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
    if (merchantItems.isEmpty) {
      showCustomSnackbar(
        title: 'Keranjang Kosong',
        message: 'Silakan tambahkan produk ke keranjang',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    bool allMerchantsActive = merchantItems.keys.every((merchantId) {
      final merchant = merchantItems[merchantId]!.first.merchant;
      if (!merchant.isActive) {
        showCustomSnackbar(
          title: 'Merchant Tidak Aktif',
          message: 'Merchant ${merchant.name} sedang tidak aktif',
          backgroundColor: Colors.red,
          snackPosition: SnackPosition.BOTTOM,
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
