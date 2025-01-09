import 'package:antarkanma/app/data/models/order_item_model.dart';

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
  final UserInfo? user;
  final LocationInfo? userLocation;
  final OrderInfo? order;
  final List<OrderItemModel> items;

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
    this.user,
    this.userLocation,
    this.order,
    required this.items,
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

      return TransactionModel(
        id: _parseId(json['id']),
        orderId: _parseId(json['order_id']),
        userId: _parseId(json['user_id']) ?? 0,
        userLocationId: _parseId(json['user_location_id']) ?? 0,
        totalPrice: _parseDouble(json['total_price']) ?? 0.0,
        shippingPrice: _parseDouble(json['shipping_price']) ?? 0.0,
        paymentMethod: json['payment_method']?.toString() ?? 'MANUAL',
        status: json['status']?.toString() ?? 'PENDING',
        paymentStatus: json['payment_status']?.toString() ?? 'PENDING',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        note: json['note']?.toString(),
        user: json['user'] != null ? UserInfo.fromJson(json['user']) : null,
        userLocation: json['user_location'] != null
            ? LocationInfo.fromJson(json['user_location'])
            : null,
        order: json['order'] != null ? OrderInfo.fromJson(json['order']) : null,
        items: orderItems,
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
      'total_price': totalPrice,
      'shipping_price': shippingPrice,
      'payment_method': paymentMethod,
      'status': status,
      'payment_status': paymentStatus,
      'created_at': createdAt?.toIso8601String(),
      'note': note,
      'user': user?.toJson(),
      'user_location': userLocation?.toJson(),
      'order': order?.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
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
    UserInfo? user,
    LocationInfo? userLocation,
    OrderInfo? order,
    List<OrderItemModel>? items,
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
      user: user ?? this.user,
      userLocation: userLocation ?? this.userLocation,
      order: order ?? this.order,
      items: items ?? this.items,
    );
  }
}

class UserInfo {
  final int id;
  final String name;
  final String? email;
  final String? phone;

  UserInfo({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}

class LocationInfo {
  final String address;
  final String city;
  final String postalCode;

  LocationInfo({
    required this.address,
    required this.city,
    required this.postalCode,
  });

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'postal_code': postalCode,
    };
  }
}

class OrderInfo {
  final int id;
  final double totalAmount;
  final String orderStatus;
  final List<OrderItemModel> orderItems;

  OrderInfo({
    required this.id,
    required this.totalAmount,
    required this.orderStatus,
    required this.orderItems,
  });

  factory OrderInfo.fromJson(Map<String, dynamic> json) {
    return OrderInfo(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : json['id'] ?? 0,
      totalAmount: json['total_amount'] is String
          ? double.tryParse(json['total_amount']) ?? 0.0
          : (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      orderStatus: json['order_status']?.toString() ?? '',
      orderItems: (json['order_items'] as List?)
          ?.map((item) => OrderItemModel.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'order_status': orderStatus,
      'order_items': orderItems.map((item) => item.toJson()).toList(),
    };
  }
}
