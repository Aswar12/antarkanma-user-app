import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/cart_item_model.dart';

class OrderItemModel {
  final int quantity;
  final double price;
  final ProductInfo product;
  final MerchantInfo merchant;

  OrderItemModel({
    required this.quantity,
    required this.price,
    required this.product,
    required this.merchant,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
      product: ProductInfo.fromJson(json['product']),
      merchant: MerchantInfo.fromJson(json['merchant']),
    );
  }

  factory OrderItemModel.fromCartItem(CartItemModel cartItem, String orderId) {
    return OrderItemModel(
      quantity: cartItem.quantity,
      price: cartItem.price,
      product: ProductInfo(
        id: cartItem.product.id ?? 0,
        name: cartItem.product.name,
        description: cartItem.product.description,
        price: cartItem.product.price,
        galleries: cartItem.product.imageUrls,
        category: CategoryInfo(
          id: cartItem.product.category?.id ?? 0,
          name: cartItem.product.category?.name ?? '',
        ),
      ),
      merchant: MerchantInfo(
        id: cartItem.merchant.id ?? 0,
        name: cartItem.merchant.name,
        address: cartItem.merchant.address,
        phoneNumber: cartItem.merchant.phoneNumber,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'price': price,
      'product_id': product.id,
      'merchant': {
        'id': merchant.id,
        'name': merchant.name,
        'address': merchant.address,
        'phone_number': merchant.phoneNumber,
      },
    };
  }

  String get formattedPrice => 'Rp ${price.toStringAsFixed(0)}';
  double get totalPrice => quantity * price;
  String get formattedTotalPrice => 'Rp ${totalPrice.toStringAsFixed(0)}';
  String get merchantName => merchant.name;

  bool validate() {
    if (quantity <= 0) return false;
    if (price <= 0) return false;
    if (product.id <= 0) return false;
    if (merchant.id <= 0) return false;
    return true;
  }

  OrderItemModel copyWith({
    int? quantity,
    double? price,
    ProductInfo? product,
    MerchantInfo? merchant,
  }) {
    return OrderItemModel(
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      product: product ?? this.product,
      merchant: merchant ?? this.merchant,
    );
  }
}

class ProductInfo {
  final int id;
  final String name;
  final String description;
  final double price;
  final List<String> galleries;
  final CategoryInfo category;

  ProductInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.galleries,
    required this.category,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: ((json['price'] ?? 0) as num).toDouble(),
      galleries: (json['galleries'] as List?)?.cast<String>() ?? [],
      category: CategoryInfo.fromJson(json['category'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'galleries': galleries,
      'category': category.toJson(),
    };
  }

  String get firstImageUrl => galleries.isNotEmpty ? galleries.first : '';
}

class CategoryInfo {
  final int id;
  final String name;

  CategoryInfo({
    required this.id,
    required this.name,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class MerchantInfo {
  final int id;
  final String name;
  final String address;
  final String phoneNumber;

  MerchantInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
  });

  factory MerchantInfo.fromJson(Map<String, dynamic> json) {
    return MerchantInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone_number': phoneNumber,
    };
  }
}
