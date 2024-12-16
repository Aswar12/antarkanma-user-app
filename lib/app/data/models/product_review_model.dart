import 'package:antarkanma/app/data/models/user_model.dart';

class ProductReviewModel {
  final int? id;
  final int userId;
  final int productId;
  final int rating;
  final String comment;
  final UserModel? user;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductReviewModel({
    this.id,
    required this.userId,
    required this.productId,
    required this.rating,
    required this.comment,
    this.user,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    return ProductReviewModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int,
      productId: json['product_id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'rating': rating,
      'comment': comment,
      'user': user?.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProductReviewModel &&
        other.id == id &&
        other.userId == userId &&
        other.productId == productId &&
        other.rating == rating &&
        other.comment == comment &&
        other.user == user;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        productId.hashCode ^
        rating.hashCode ^
        comment.hashCode ^
        user.hashCode;
  }

  ProductReviewModel copyWith({
    int? id,
    int? userId,
    int? productId,
    int? rating,
    String? comment,
    UserModel? user,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductReviewModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      user: user ?? this.user,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
