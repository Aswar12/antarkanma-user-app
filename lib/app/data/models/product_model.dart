import 'package:antarkanma/app/data/models/category_model.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/models/product_gallery_model.dart';
import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/data/models/variant_model.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ProductModel {
  final int? id;
  final String name;
  final String description;
  final List<ProductGalleryModel> galleries;
  final List<VariantModel> variants;
  final double price;
  final String? status;
  final List<ProductReviewModel>? reviews;
  final MerchantModel? merchant;
  final CategoryModel? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    this.id,
    required this.name,
    required this.description,
    this.galleries = const [],
    required this.price,
    this.variants = const [],
    this.reviews = const [],
    this.status,
    this.merchant,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  // Getter untuk mendapatkan daftar URL gambar
  List<String> get imageUrls =>
      galleries.map((gallery) => gallery.url).toList();

  // Tambahan getter yang berguna
  String get firstImageUrl {
    if (galleries.isEmpty) {
      return 'assets/image_shoes.png'; // default image
    }
    return galleries.first.url;
  }

  bool get hasImages => galleries.isNotEmpty;

  // Method untuk validasi URL
  bool isValidImageUrl(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  // Getter untuk mendapatkan URL yang valid
  List<String> get validImageUrls => galleries
      .map((gallery) => gallery.url)
      .where((url) => isValidImageUrl(url))
      .toList();

  // Method untuk mendapatkan URL gambar dengan index tertentu
  String getImageUrl(int index,
      {String defaultImage = 'assets/image_shoes.png'}) {
    if (index < 0 || index >= galleries.length) {
      return defaultImage;
    }
    return galleries[index].url;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String,
      price: double.parse(json['price'].toString()),
      galleries: json['galleries'] != null
          ? (json['galleries'] as List)
              .map((gallery) => ProductGalleryModel.fromJson(gallery))
              .toList()
          : [],
      status: json['status'] as String?,
      variants: json['variants'] != null
          ? (json['variants'] as List)
              .map((variant) => VariantModel.fromJson(variant))
              .toList()
          : [],
      reviews: json['reviews'] != null
          ? (json['reviews'] as List)
              .map((review) => ProductReviewModel.fromJson(review))
              .toList()
          : [],
      merchant: json['merchant'] != null
          ? MerchantModel.fromJson(json['merchant'])
          : null,
      category: json['category'] != null
          ? CategoryModel.fromJson(json['category'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  factory ProductModel.local({
    required String name,
    required String description,
    List<ProductGalleryModel> galleries = const [],
    required double price,
  }) {
    return ProductModel(
      name: name,
      description: description,
      galleries: galleries,
      price: price,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'status': status,
      'reviews': reviews?.map((review) => review.toJson()).toList(),
      'variants': variants.map((variant) => variant.toJson()).toList(),
      'merchant': merchant?.toJson(),
      'category': category?.toJson(),
      'galleries': galleries.map((gallery) => gallery.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ProductModel copyWith({
    int? id,
    String? name,
    String? description,
    List<ProductGalleryModel>? galleries,
    double? price,
    String? status,
    List<VariantModel>? variants,
    List<ProductReviewModel>? reviews,
    MerchantModel? merchant,
    CategoryModel? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      galleries: galleries ?? this.galleries,
      price: price ?? this.price,
      status: status ?? this.status,
      variants: variants ?? this.variants,
      reviews: reviews ?? this.reviews,
      merchant: merchant ?? this.merchant,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is! ProductModel) return false;

    final ProductModel productModel = other;

    return id == productModel.id &&
        name == productModel.name &&
        description == productModel.description &&
        price == productModel.price &&
        listEquals(galleries, productModel.galleries) &&
        listEquals(variants, productModel.variants) &&
        listEquals(reviews, productModel.reviews);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      price,
      Object.hashAll(galleries),
      Object.hashAll(variants),
    );
  }

  List<VariantModel> get activeVariants {
    return variants.where((variant) => variant.status == 'active').toList();
  }

  VariantModel? findVariantByName(String name) {
    try {
      return variants.firstWhere((variant) => variant.name == name);
    } catch (e) {
      return null;
    }
  }

  double calculatePriceWithVariant(VariantModel variant) {
    return price + variant.priceAdjustment;
  }

  String get formattedPrice {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  String getFormattedPriceWithVariant(VariantModel variant) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(calculatePriceWithVariant(variant));
  }

  // Menambahkan getter untuk rating rata-rata
  double get averageRating {
    if (reviews!.isEmpty) return 0.0; // Jika tidak ada review, kembalikan 0.0

    // Hitung total rating
    double totalRating =
        reviews!.fold(0.0, (sum, review) => sum + review.rating);

    // Kembalikan rata-rata
    return totalRating / reviews!.length;
  }

// Menambahkan getter untuk total reviews
  int get totalReviews {
    if (reviews == null) return 0;
    // Sesuaikan dengan struktur reviews Anda
    return 1; // Atau logic perhitungan jumlah review
  }

// Menambahkan getter untuk status aktif
  bool get isActive => status?.toLowerCase() == 'active';

// Menambahkan getter untuk variant names yang unik
  List<String> get uniqueVariantNames {
    return variants.map((v) => v.name).toSet().toList();
  }

// Menambahkan getter untuk variant values berdasarkan name
  Map<String, List<String>> get variantValuesByName {
    final map = <String, List<String>>{};
    for (var variant in variants) {
      if (!map.containsKey(variant.name)) {
        map[variant.name] = [];
      }
      map[variant.name]!.add(variant.value);
    }
    return map;
  }
}

class UninitializedProductModel extends ProductModel {
  UninitializedProductModel()
      : super(
          id: 0,
          name: '',
          description: '',
          galleries: const [],
          variants: const [],
          price: 0.0,
        );
}
