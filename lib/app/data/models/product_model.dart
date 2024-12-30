import 'package:antarkanma/app/data/models/category_model.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/models/product_gallery_model.dart';
import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/data/models/variant_model.dart';
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
  final String? averageRatingRaw;
  final int? totalReviewsRaw;
  final Map<String, dynamic>? ratingInfo;

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
    this.averageRatingRaw,
    this.totalReviewsRaw,
    this.ratingInfo,
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

  // Price formatting methods
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

  double calculatePriceWithVariant(VariantModel variant) {
    return price + variant.priceAdjustment;
  }

  // Rating methods
  double get averageRating {
    if (ratingInfo != null && ratingInfo!.containsKey('average_rating')) {
      return (ratingInfo!['average_rating'] as num).toDouble();
    }
    if (averageRatingRaw != null) {
      return double.tryParse(averageRatingRaw!) ?? 0.0;
    }
    return 0.0;
  }

  int get totalReviews {
    if (ratingInfo != null && ratingInfo!.containsKey('total_reviews')) {
      return ratingInfo!['total_reviews'] as int;
    }
    return totalReviewsRaw ?? 0;
  }

  // JSON conversion methods
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
      'average_rating': averageRatingRaw,
      'total_reviews': totalReviewsRaw,
      'rating_info': ratingInfo,
    };
  }

  // Copy with method
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
    String? averageRatingRaw,
    int? totalReviewsRaw,
    Map<String, dynamic>? ratingInfo,
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
      averageRatingRaw: averageRatingRaw ?? this.averageRatingRaw,
      totalReviewsRaw: totalReviewsRaw ?? this.totalReviewsRaw,
      ratingInfo: ratingInfo ?? this.ratingInfo,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
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

      // Parse rating info
      Map<String, dynamic>? ratingInfo;
      if (json['rating_info'] != null) {
        ratingInfo = json['rating_info'] as Map<String, dynamic>;
      } else if (json['average_rating'] != null ||
          json['total_reviews'] != null) {
        ratingInfo = {
          'average_rating': toDouble(json['average_rating']) ?? 0.0,
          'total_reviews': json['total_reviews'] ?? 0,
        };
      }

      return ProductModel(
        id: json['id'] as int?,
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        price: toDouble(json['price']) ?? 0.0,
        galleries: json['galleries'] != null
            ? (json['galleries'] as List)
                .map((gallery) => ProductGalleryModel.fromJson(gallery))
                .toList()
            : [],
        status: json['status']?.toString(),
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
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
        averageRatingRaw: json['average_rating']?.toString(),
        totalReviewsRaw: json['total_reviews'] as int?,
        ratingInfo: ratingInfo,
      );
    } catch (e) {
      print('Error parsing product JSON: $e');
      print('Problematic JSON: $json');
      return ProductModel(
        name: '',
        description: '',
        price: 0.0,
      );
    }
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
