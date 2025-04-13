import 'package:antarkanma/app/data/models/order_item_model.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/app/data/models/user_model.dart';
import 'package:antarkanma/app/data/models/courier_model.dart';

class OrderModel {
  final dynamic id;
  final String orderStatus;
  final double totalAmount;
  final DateTime? createdAt;
  final List<OrderItemModel> orderItems;
  final int merchantId;

  OrderModel({
    this.id,
    required this.orderStatus,
    required this.totalAmount,
    this.createdAt,
    required this.orderItems,
    required this.merchantId,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<OrderItemModel> orderItems = [];
    if (json['order_items'] != null) {
      try {
        var items = json['order_items'];
        // Handle case where items might be a List<List>
        if (items is List) {
          if (items.isNotEmpty && items[0] is List) {
            // Flatten the nested list structure
            items = items.expand((i) => i is List ? i : [i]).toList();
          }
          orderItems = items.map((item) {
            try {
              return OrderItemModel.fromJson(item);
            } catch (e) {
              print('Error parsing individual order item: $e');
              print('Item data: $item');
              return null;
            }
          }).where((item) => item != null).cast<OrderItemModel>().toList();
        }
      } catch (e) {
        print('Error parsing order items: $e');
        print('Order items data: ${json['order_items']}');
      }
    }

    // Handle total_amount that could be string or number
    double amount = 0.0;
    if (json['total_amount'] != null) {
      if (json['total_amount'] is num) {
        amount = (json['total_amount'] as num).toDouble();
      } else if (json['total_amount'] is String) {
        amount = double.tryParse(json['total_amount']) ?? 0.0;
      }
    }

    return OrderModel(
      id: json['id'],
      orderStatus: json['order_status']?.toString() ?? 'PENDING',
      totalAmount: amount,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      orderItems: orderItems,
      merchantId: json['merchant_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_status': orderStatus,
      'total_amount': totalAmount,
      'created_at': createdAt?.toIso8601String(),
      'order_items': orderItems.map((item) => item.toJson()).toList(),
      'merchant_id': merchantId,
    };
  }

  // Get merchant name from the first order item
  String get merchantName {
    if (orderItems.isEmpty) return 'Unknown Merchant';
    return orderItems.first.merchant.name;
  }
}

class TransactionModel {
  final dynamic id;
  final dynamic orderId;
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
  final List<OrderModel> orders;
  final UserModel? user;
  final CourierModel? courier;

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
    required this.orders,
    this.user,
    this.courier,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    try {
      // Handle both old and new JSON structures
      final transactionData = json['data'] ?? json;
      
      // Parse order items
      List<OrderItemModel> orderItems = [];
      if (transactionData['order'] != null && transactionData['order']['order_items'] != null) {
        if (transactionData['order']['order_items'] is List) {
          var items = transactionData['order']['order_items'];
          // Handle case where items might be a List<List>
          if (items.isNotEmpty && items[0] is List) {
            // Flatten the nested list structure
            items = items.expand((i) => i is List ? i : [i]).toList();
          }
          orderItems = items.map((item) {
            try {
              return OrderItemModel.fromJson(item);
            } catch (e) {
              print('Error parsing order item: $e');
              print('Item data: $item');
              return null;
            }
          }).where((item) => item != null).cast<OrderItemModel>().toList();
        }
      } else if (transactionData['items'] != null) {
        orderItems = _parseItems(transactionData['items']);
      }

      // Parse user location
      UserLocationModel? userLocation;
      if (transactionData['user_location'] != null) {
        userLocation = UserLocationModel.fromJson(transactionData['user_location']);
      }

      // Parse orders with new structure
      List<OrderModel> orders = [];
      if (transactionData['orders'] != null) {
        if (transactionData['orders'] is List) {
          orders = (transactionData['orders'] as List)
              .map((order) {
                try {
                  if (order is List) {
                    // If order is a List, take the first item
                    order = order[0];
                  }
                  return OrderModel.fromJson(order);
                } catch (e) {
                  print('Error parsing order: $e');
                  print('Order data: $order');
                  return null;
                }
              })
              .where((order) => order != null)
              .cast<OrderModel>()
              .toList();
        }
      } else if (transactionData['order'] != null) {
        // Backward compatibility: if single order, wrap in list
        try {
          var order = transactionData['order'];
          if (order is List) {
            // If order is a List, take the first item
            order = order[0];
          }
          orders = [OrderModel.fromJson(order)];
        } catch (e) {
          print('Error parsing single order: $e');
          print('Order data: ${transactionData['order']}');
        }
      }

      // Parse user
      UserModel? user;
      if (transactionData['user'] != null) {
        user = UserModel.fromJson(transactionData['user']);
      }

      // Parse courier
      CourierModel? courier;
      if (transactionData['courier'] != null) {
        courier = CourierModel.fromJson(transactionData['courier']);
      }

      // Parse prices that could be string or number
      double totalPrice = 0.0;
      if (transactionData['total_price'] != null || transactionData['total_amount'] != null) {
        var priceValue = transactionData['total_price'] ?? transactionData['total_amount'];
        if (priceValue is num) {
          totalPrice = priceValue.toDouble();
        } else if (priceValue is String) {
          totalPrice = double.tryParse(priceValue) ?? 0.0;
        }
      }

      double shippingPrice = 0.0;
      if (transactionData['shipping_price'] != null) {
        var shipValue = transactionData['shipping_price'];
        if (shipValue is num) {
          shippingPrice = shipValue.toDouble();
        } else if (shipValue is String) {
          shippingPrice = double.tryParse(shipValue) ?? 0.0;
        }
      }

      return TransactionModel(
        id: transactionData['id'],
        orderId: transactionData['order_id'],
        userId: _parseId(transactionData['user_id']) ?? 0,
        userLocationId: _parseId(transactionData['user_location_id']) ?? 0,
        totalPrice: totalPrice,
        shippingPrice: shippingPrice,
        paymentMethod: transactionData['payment_method']?.toString() ?? 'MANUAL',
        status: transactionData['status']?.toString() ?? 'PENDING',
        paymentStatus: transactionData['payment_status']?.toString() ?? 'PENDING',
        createdAt: transactionData['created_at'] != null
            ? DateTime.tryParse(transactionData['created_at'].toString())
            : null,
        note: transactionData['note']?.toString(),
        items: orderItems,
        userLocation: userLocation,
        orders: orders,
        user: user,
        courier: courier,
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

  static List<OrderItemModel> _parseItems(dynamic items) {
    if (items == null) return [];
    if (items is! List) return [];

    // Handle case where items might be a List<List>
    if (items.isNotEmpty && items[0] is List) {
      // Flatten the nested list structure
      items = items.expand((i) => i is List ? i : [i]).toList();
    }

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
      'orders': orders.map((order) => order.toJson()).toList(),
      'user': user?.toJson(),
      'courier': courier?.toJson(),
    };
  }

  // Getters for formatted values
  double get subtotal => totalPrice;
  String get formattedSubtotal => 'Rp ${subtotal.toStringAsFixed(0)}';
  double get shippingCost => shippingPrice;
  String get formattedShippingCost => 'Rp ${shippingCost.toStringAsFixed(0)}';
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
      case 'READYTOPICKUP':
        return 'Siap Antar';
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
    dynamic id,
    dynamic orderId,
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
    List<OrderModel>? orders,
    UserModel? user,
    CourierModel? courier,
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
      orders: orders ?? this.orders,
      user: user ?? this.user,
      courier: courier ?? this.courier,
    );
  }
}
