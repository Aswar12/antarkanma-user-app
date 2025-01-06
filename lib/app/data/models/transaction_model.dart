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
    return TransactionModel(
      id: json['id'] is String ? int.tryParse(json['id']) : json['id'],
      orderId: json['order_id'] is String ? int.tryParse(json['order_id']) : json['order_id'],
      userId: json['user_id'] is String ? int.tryParse(json['user_id']) ?? 0 : json['user_id'] ?? 0,
      userLocationId: json['user_location_id'] is String 
          ? int.tryParse(json['user_location_id']) ?? 0 
          : json['user_location_id'] ?? 0,
      totalPrice: json['total_price'] is String
          ? double.tryParse(json['total_price']) ?? 0.0
          : (json['total_price'] as num?)?.toDouble() ?? 0.0,
      shippingPrice: json['shipping_price'] is String
          ? double.tryParse(json['shipping_price']) ?? 0.0
          : (json['shipping_price'] as num?)?.toDouble() ?? 0.0,
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
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => OrderItemModel.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    final data = {
      if (id != null) 'id': id,
      if (orderId != null) 'order_id': orderId,
      'user_id': userId,
      'user_location_id': userLocationId,
      'total_price': totalPrice,
      'shipping_price': shippingPrice,
      'payment_method': paymentMethod,
      'status': status,
      'payment_status': paymentStatus,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
      if (note != null) 'note': note,
      'items': items.map((item) => {
        'quantity': item.quantity,
        'price': item.price,
        'product_id': item.product.id,
        'merchant': {
          'id': item.merchant.id,
          'name': item.merchant.name,
          'address': item.merchant.address,
          'phone_number': item.merchant.phoneNumber,
        },
      }).toList(),
    };

    // Remove any null values
    data.removeWhere((key, value) => value == null);
    return data;
  }

  double get grandTotal => totalPrice + shippingPrice;
  String get formattedGrandTotal => 'Rp ${grandTotal.toStringAsFixed(0)}';
  String get formattedTotalPrice => 'Rp ${totalPrice.toStringAsFixed(0)}';
  String get formattedShippingPrice => 'Rp ${shippingPrice.toStringAsFixed(0)}';
  String get formattedDate => createdAt?.toString() ?? '-';

  // Status display
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

  // Copy with method
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
      orderItems: (json['orderItems'] as List?)
          ?.map((item) => OrderItemModel.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'order_status': orderStatus,
      'orderItems': orderItems.map((item) => item.toJson()).toList(),
    };
  }
}
