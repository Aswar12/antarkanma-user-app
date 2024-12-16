// lib/app/data/models/product_gallery_model.dart

class ProductGalleryModel {
  final int? id;
  final int productId;
  final String url;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  ProductGalleryModel({
    this.id,
    required this.productId,
    required this.url,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory ProductGalleryModel.fromJson(Map<String, dynamic> json) {
    return ProductGalleryModel(
      id: json['id'] as int?,
      productId: json['product_id'] as int,
      // Langsung menggunakan URL dari response karena sudah lengkap dari backend
      url: json['url'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'url': url,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProductGalleryModel &&
        other.id == id &&
        other.productId == productId &&
        other.url == url;
  }

  @override
  int get hashCode => id.hashCode ^ productId.hashCode ^ url.hashCode;

  ProductGalleryModel copyWith({
    int? id,
    int? productId,
    String? url,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return ProductGalleryModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      url: url ?? this.url,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
