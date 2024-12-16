import 'package:antarkanma/app/data/models/order_item_model.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderModel {
  final String? id;
  final String userId;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String orderStatus; // PENDING, PROCESSING, COMPLETED, CANCELED
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Tambahan field untuk relasi dengan Transaction
  TransactionModel? transaction;

  OrderModel({
    this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    this.orderStatus = 'PENDING',
    this.createdAt,
    this.updatedAt,
    this.transaction,
  });

  // Getter untuk total items
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  // Getter untuk formatted total amount
  String get formattedTotalAmount {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(totalAmount);
  }

  // Konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'total_amount': totalAmount,
      'order_status': orderStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Membuat instance dari JSON
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['user_id'],
      items: (json['items'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
      totalAmount: json['total_amount'].toDouble(),
      orderStatus: json['order_status'] ?? 'PENDING',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Method untuk mendapatkan items berdasarkan merchant
  Map<String, List<OrderItemModel>> getItemsByMerchant() {
    return groupBy(items, (OrderItemModel item) => item.merchant.id.toString());
  }

  // Method untuk mengupdate status order
  OrderModel updateStatus(String newStatus) {
    return copyWith(
      orderStatus: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  // Copy with method
  OrderModel copyWith({
    String? id,
    String? userId,
    List<OrderItemModel>? items,
    double? totalAmount,
    String? orderStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    TransactionModel? transaction,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      orderStatus: orderStatus ?? this.orderStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transaction: transaction ?? this.transaction,
    );
  }

  // Validasi order
  bool validate() {
    return items.isNotEmpty &&
        items.every((item) => item.validate()) &&
        totalAmount > 0;
  }

  // Status-related methods
  String get statusDisplay {
    switch (orderStatus.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Pembayaran';
      case 'PROCESSING':
        return 'Sedang Diproses';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELED':
        return 'Dibatalkan';
      default:
        return 'Status Tidak Dikenal';
    }
  }

  Color getStatusColor() {
    switch (orderStatus.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PROCESSING':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Method untuk mengecek apakah order masih bisa dibatalkan
  bool get canBeCanceled {
    return orderStatus == 'PENDING' || orderStatus == 'PROCESSING';
  }

  // Method untuk mendapatkan ringkasan order
  Map<String, dynamic> getSummary() {
    return {
      'order_id': id,
      'total_items': totalItems,
      'total_amount': totalAmount,
      'status': statusDisplay,
      'created_at': createdAt,
      'merchants_count': getItemsByMerchant().length,
    };
  }
}
