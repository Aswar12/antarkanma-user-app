import 'package:antarkanma/app/data/models/order_item_model.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';

class OrderModel {
  final List<OrderItemModel> orderItems;

  OrderModel({
    required this.orderItems,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> orderItems = [];
    if (json['order_items'] != null) {
      orderItems = (json['order_items'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList();
    }
    return OrderModel(orderItems: orderItems);
  }

  Map<String, dynamic> toJson() {
    return {
      'order_items': orderItems.map((item) => item.toJson()).toList(),
    };
  }
}

class TransactionModel {
  final int? id;
  final int? orderId;
  final int userId;
  final int userLocationId;
  final double totalPrice;
  final double shippingPrice;
  final String paymentMethod;
  final String status;
  final String paymentStatus;
  final DateTime? createdAt;
  final String? note;
  final List<OrderItemModel> items;
  final UserLocationModel? userLocation;
  final OrderModel? order;

  TransactionModel({
    this.id,
    this.orderId,
    required this.userId,
    required this.userLocationId,
    required this.totalPrice,
    required this.shippingPrice,
    required this.paymentMethod,
    required this.status,
    required this.paymentStatus,
    this.createdAt,
    this.note,
    required this.items,
    this.userLocation,
    this.order,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    print('Creating TransactionModel from JSON: $json');
    try {
      // Parse order items from the nested structure
      List<OrderItemModel> orderItems = [];
      if (json['order'] != null && json['order']['order_items'] != null) {
        orderItems = (json['order']['order_items'] as List)
            .map((item) => OrderItemModel.fromJson(item))
            .toList();
        print('Parsed ${orderItems.length} order items from order');
      } else if (json['items'] != null) {
        orderItems = _parseItems(json['items']);
        print('Parsed ${orderItems.length} order items from items array');
      }

      // Parse user location
      UserLocationModel? userLocation;
      if (json['user_location'] != null) {
        userLocation = UserLocationModel.fromJson(json['user_location']);
      }

      // Parse order
      OrderModel? order;
      if (json['order'] != null) {
        order = OrderModel.fromJson(json['order']);
      }

      return TransactionModel(
        id: _parseId(json['id']),
        orderId: _parseId(json['order_id']),
        userId: _parseId(json['user_id']) ?? 0,
        userLocationId: _parseId(json['user_location_id']) ?? 0,
        totalPrice: _parseDouble(json['total_amount']) ?? 0.0,
        shippingPrice: _parseDouble(json['shipping_price']) ?? 0.0,
        paymentMethod: json['payment_method']?.toString() ?? 'MANUAL',
        status: json['status']?.toString() ?? 'PENDING',
        paymentStatus: json['payment_status']?.toString() ?? 'PENDING',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        note: json['note']?.toString(),
        items: orderItems,
        userLocation: userLocation,
        order: order,
      );
    } catch (e, stackTrace) {
      print('Error parsing TransactionModel: $e');
      print('Stack trace: $stackTrace');
      print('JSON data: $json');
      rethrow;
    }
  }

  static int? _parseId(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<OrderItemModel> _parseItems(dynamic items) {
    if (items == null) return [];
    if (items is! List) return [];

    return items.map((item) {
      try {
        return OrderItemModel.fromJson(item);
      } catch (e) {
        print('Error parsing order item: $e');
        print('Item data: $item');
        rethrow;
      }
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'user_location_id': userLocationId,
      'total_amount': totalPrice,
      'shipping_price': shippingPrice,
      'payment_method': paymentMethod,
      'status': status,
      'payment_status': paymentStatus,
      'created_at': createdAt?.toIso8601String(),
      'note': note,
      'items': items.map((item) => item.toJson()).toList(),
      'user_location': userLocation?.toJson(),
      'order': order?.toJson(),
    };
  }

  double get grandTotal => totalPrice + shippingPrice;
  String get formattedGrandTotal => 'Rp ${grandTotal.toStringAsFixed(0)}';
  String get formattedTotalPrice => 'Rp ${totalPrice.toStringAsFixed(0)}';
  String get formattedShippingPrice => 'Rp ${shippingPrice.toStringAsFixed(0)}';
  String get formattedDate => createdAt?.toString() ?? '-';

  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Konfirmasi';
      case 'ACCEPTED':
        return 'Diterima';
      case 'REJECTED':
        return 'Ditolak';
      case 'PROCESSING':
        return 'Sedang Diproses';
      case 'SHIPPED':
        return 'Dalam Pengiriman';
      case 'DELIVERED':
        return 'Terkirim';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  TransactionModel copyWith({
    int? id,
    int? orderId,
    int? userId,
    int? userLocationId,
    double? totalPrice,
    double? shippingPrice,
    String? paymentMethod,
    String? status,
    String? paymentStatus,
    DateTime? createdAt,
    String? note,
    List<OrderItemModel>? items,
    UserLocationModel? userLocation,
    OrderModel? order,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      userLocationId: userLocationId ?? this.userLocationId,
      totalPrice: totalPrice ?? this.totalPrice,
      shippingPrice: shippingPrice ?? this.shippingPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      items: items ?? this.items,
      userLocation: userLocation ?? this.userLocation,
      order: order ?? this.order,
    );
  }
}
