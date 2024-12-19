import 'package:antarkanma/app/data/models/variant_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/cart_item_model.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';

class OrderItemModel {
  final String? id;
  late final String orderId;
  final ProductModel product;
  final MerchantModel merchant; // Mengganti merchantId dengan MerchantModel
  final int quantity;
  final double price;
  final String? selectedVariantId;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderItemModel({
    this.id,
    required this.orderId,
    required this.product,
    required this.merchant, // Menambahkan parameter merchant
    required this.quantity,
    required this.price,
    this.selectedVariantId,
    this.status = 'PENDING',
    this.createdAt,
    this.updatedAt,
    VariantModel? selectedVariant,
  });

  // Getter untuk total harga
  double get totalPrice => price * quantity;

  // Formatter untuk harga dalam Rupiah
  String get formattedPrice {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  String get formattedTotalPrice {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(totalPrice);
  }

  // Konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product': product.toJson(),
      'merchant': merchant.toJson(), // Menambahkan merchant ke JSON
      'quantity': quantity,
      'price': price,
      'selected_variant_id': selectedVariantId,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Membuat instance dari JSON
  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to safely convert to double
      double? toDouble(dynamic value) {
        if (value == null) return null;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          try {
            return double.parse(value);
          } catch (e) {
            print('Error converting $value to double: $e');
            return null;
          }
        }
        return null;
      }

      // Helper function to safely parse integer
      int? parseInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is String) {
          try {
            return int.parse(value);
          } catch (e) {
            print('Error parsing $value to int: $e');
            return null;
          }
        }
        return null;
      }

      return OrderItemModel(
        id: json['id']?.toString(),
        orderId: json['order_id']?.toString() ?? '',
        product: ProductModel.fromJson(json['product'] ?? {}),
        merchant: MerchantModel.fromJson(json['merchant'] ?? {}),
        quantity: parseInt(json['quantity']) ?? 1,
        price: toDouble(json['price']) ?? 0.0,
        selectedVariantId: json['selected_variant_id']?.toString(),
        status: json['status']?.toString() ?? 'PENDING',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
      );
    } catch (e) {
      print('Error parsing order item JSON: $e');
      print('Problematic JSON: $json');
      // Return a minimal valid order item in case of error
      return OrderItemModel(
        orderId: '',
        product: ProductModel.fromJson({}),
        merchant: MerchantModel.fromJson({}),
        quantity: 1,
        price: 0.0,
      );
    }
  }

  // Membuat OrderItem dari CartItem
  factory OrderItemModel.fromCartItem(CartItemModel cartItem, String orderId) {
    return OrderItemModel(
      orderId: orderId,
      product: cartItem.product,
      merchant: cartItem.merchant, // Mengambil merchant dari CartItem
      quantity: cartItem.quantity,
      price: cartItem.price,
      selectedVariantId: cartItem.selectedVariantId.toString(),
    );
  }

  // Copy with method
  OrderItemModel copyWith({
    String? id,
    String? orderId,
    ProductModel? product,
    MerchantModel? merchant, // Menambahkan merchant ke copyWith
    int? quantity,
    double? price,
    String? selectedVariantId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderItemModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      product: product ?? this.product,
      merchant: merchant ?? this.merchant, // Menjaga merchant tetap sama
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      selectedVariantId: selectedVariantId ?? this.selectedVariantId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Method untuk update status
  OrderItemModel updateStatus(String newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  // Validasi item
  bool validate() {
    return quantity > 0 &&
        price > 0 &&
        product.status == 'ACTIVE' &&
        merchant.status == 'ACTIVE'; // Menambahkan validasi merchant
  }

  // Status-related methods
  bool get isAvailable =>
      product.status == 'ACTIVE' &&
      merchant.status == 'ACTIVE'; // Menambahkan pengecekan merchant

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Proses';
      case 'PROCESSING':
        return 'Sedang Diproses';
      case 'READY_FOR_PICKUP':
        return 'Siap Diambil';
      case 'ON_DELIVERY':
        return 'Dalam Pengiriman';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELED':
        return 'Dibatalkan';
      default:
        return 'Status Tidak Dikenal';
    }
  }

  Color getStatusColor() {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'READY_FOR_PICKUP':
        return Colors.green;
      case 'ON_DELIVERY':
        return Colors.lightBlue;
      case 'COMPLETED':
        return Colors.green[800]!;
      case 'CANCELED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Tambahan method untuk mendapatkan informasi merchant
  String get merchantName => merchant.name;

  String? get merchantAddress => merchant.address;

  String? get merchantPhone => merchant.phoneNumber;

  // Method untuk mengecek apakah order item dari merchant yang sama
  bool isSameMerchant(OrderItemModel other) {
    return merchant.id == other.merchant.id;
  }

  // Method untuk mengecek apakah item masih valid untuk diproses
  bool isValidForProcessing() {
    return isAvailable && status != 'CANCELED' && status != 'COMPLETED';
  }

  // Method untuk mendapatkan estimasi waktu pengiriman (jika ada)
  String? get estimatedDeliveryTime {
    // Implementasi logika estimasi waktu pengiriman
    // Bisa berdasarkan jarak, waktu pemrosesan merchant, dll.
    return null;
  }

  // Method untuk mendapatkan informasi pengiriman
  Map<String, dynamic> getDeliveryInfo() {
    return {
      'merchant_name': merchantName,
      'merchant_address': merchantAddress,
      'merchant_phone': merchantPhone,
      'product_name': product.name,
      'quantity': quantity,
      'status': statusDisplay,
      'estimated_delivery': estimatedDeliveryTime,
    };
  }

  // Method untuk membandingkan dengan order item lain
  bool equals(OrderItemModel other) {
    return id == other.id &&
        orderId == other.orderId &&
        product.id == other.product.id &&
        merchant.id == other.merchant.id &&
        quantity == other.quantity &&
        price == other.price &&
        selectedVariantId == other.selectedVariantId &&
        status == other.status;
  }
}
