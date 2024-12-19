import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:antarkanma/app/data/models/order_model.dart';
import 'package:antarkanma/app/data/models/order_item_model.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';

class TransactionModel {
  final int? id;
  final int? orderId; // Foreign Key ke Orders
  final int userId; // Foreign Key ke Users
  final int userLocationId; // Foreign Key ke User_Locations
  final double totalPrice;
  final double shippingPrice;
  final DateTime? paymentDate;
  final String status; // PENDING, COMPLETED, CANCELED
  final String paymentMethod; // MANUAL, ONLINE
  final String paymentStatus; // PENDING, COMPLETED, FAILED
  final double? rating;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<OrderItemModel> items; // Changed to non-nullable
  // Relasi
  OrderModel? order;
  UserLocationModel? userLocation;

  TransactionModel({
    this.id,
    this.orderId,
    required this.userId,
    required this.userLocationId,
    required this.totalPrice,
    required this.shippingPrice,
    this.paymentDate,
    this.status = 'PENDING',
    required this.paymentMethod,
    this.paymentStatus = 'PENDING',
    this.rating,
    this.note,
    this.createdAt,
    this.updatedAt,
    required this.items,
    this.order,
    this.userLocation,
  });

  // Getter untuk total harga (termasuk ongkir)
  double get grandTotal => totalPrice + shippingPrice;

  // Formatter untuk harga dalam Rupiah
  String get formattedTotalPrice {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(totalPrice);
  }

  String get formattedShippingPrice {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(shippingPrice);
  }

  String get formattedGrandTotal {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(grandTotal);
  }

  // Getter untuk mendapatkan detail produk dari items
  List<Map<String, dynamic>> get productDetails {
    return items.map((item) {
      return {
        'name': item.product.name,
        'price': item.product.formattedPrice,
        'quantity': item.quantity,
        'total': item.formattedTotalPrice,
        'image': item.product.firstImageUrl,
        'merchant': item.merchant.name,
        'status': item.statusDisplay,
      };
    }).toList();
  }

  // Getter untuk menampilkan status dalam format yang lebih user-friendly
  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELED':
        return 'Dibatalkan';
      case 'PROCESSING':
        return 'Diproses';
      case 'SHIPPING':
        return 'Dikirim';
      case 'DELIVERED':
        return 'Diterima';
      default:
        return status;
    }
  }

  // Metode untuk menghasilkan payload checkout
  Map<String, dynamic> toCheckoutPayload() {
    return {
      "user_location_id": userLocationId,
      "total_price": totalPrice,
      "shipping_price": shippingPrice,
      "payment_method": paymentMethod,
      "items": items
          .map((item) => {
                "product_id": item.product.id,
                "merchant_id": item.merchant.id,
                "quantity": item.quantity,
                "price": item.price,
              })
          .toList(),
      "order_id": orderId,
      "user_id": userId,
    };
  }

  // Konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id?.toString(),
      'order_id': orderId?.toString(),
      'user_id': userId.toString(),
      'user_location_id': userLocationId.toString(),
      'total_price': totalPrice,
      'shipping_price': shippingPrice,
      'payment_date': paymentDate?.toIso8601String(),
      'status': status,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'order': order?.toJson(),
      'rating': rating,
      'items': items.map((item) => item.toJson()).toList(),
      'note': note,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Membuat instance dari JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    try {
      return TransactionModel(
        id: json['id'] != null ? int.parse(json['id'].toString()) : null,
        orderId: json['order_id'] != null
            ? int.parse(json['order_id'].toString())
            : null,
        userId: int.parse(json['user_id'].toString()),
        userLocationId: int.parse(json['user_location_id'].toString()),
        totalPrice: double.parse(json['total_price'].toString()),
        shippingPrice: double.parse(json['shipping_price'].toString()),
        paymentDate: json['payment_date'] != null
            ? DateTime.tryParse(json['payment_date'].toString())
            : null,
        status: json['status']?.toString() ?? 'PENDING',
        paymentMethod: json['payment_method']?.toString() ?? 'MANUAL',
        paymentStatus: json['payment_status']?.toString() ?? 'PENDING',
        rating: json['rating'] != null
            ? double.parse(json['rating'].toString())
            : null,
        note: json['note']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
        items: json['order'] != null && json['order']['order_items'] != null
            ? (json['order']['order_items'] as List).map((item) {
                // Ensure product data is properly included in the order item
                if (item['product'] == null) {
                  item['product'] = json['order']['product'] ?? {};
                }
                return OrderItemModel.fromJson(item);
              }).toList()
            : [],
        order:
            json['order'] != null ? OrderModel.fromJson(json['order']) : null,
        userLocation: json['user_location'] != null
            ? UserLocationModel.fromJson(json['user_location'])
            : null,
      );
    } catch (e) {
      print('Error parsing transaction JSON: $e');
      return TransactionModel(
        userId: 0,
        userLocationId: 0,
        totalPrice: 0.0,
        shippingPrice: 0.0,
        paymentMethod: 'MANUAL',
        items: [],
      );
    }
  }
}
