import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/data/providers/review_provider.dart';
import 'package:dio/dio.dart' as dio;

class ReviewRepository {
  final ReviewProvider provider;

  ReviewRepository({required this.provider});
  
  Future<List<ProductReviewModel>> getProductReviews(
    int productId, {
    int? rating,
    String? token,
  }) async {
    try {
      print(
          'Repository: Fetching reviews for product $productId with rating filter: $rating');
      final response = await provider.getProductReviews(
        productId,
        token: token,
        rating: rating,
      );

      print('Repository: Raw Response: ${response.data}');

      if (response.data == null) {
        print('Repository: Response data is null');
        return [];
      }

      // Handle both direct review objects and nested structures
      List<dynamic> reviewsJson = [];

      if (response.data is Map<String, dynamic>) {
        if (response.data['data']?['reviews']?['data'] != null) {
          // Nested structure
          reviewsJson =
              response.data['data']['reviews']['data'] as List<dynamic>;
          print(
              'Repository: Found ${reviewsJson.length} reviews in nested structure');
        } else if (response.data['data'] is List) {
          // Direct list of reviews
          reviewsJson = response.data['data'] as List<dynamic>;
          print(
              'Repository: Found ${reviewsJson.length} reviews in direct list');
        } else if (response.data['data'] != null) {
          // Single review object in data field
          reviewsJson = [response.data['data']];
          print('Repository: Found single review object in data field');
        } else {
          // Direct single review object
          reviewsJson = [response.data];
          print('Repository: Found direct single review object');
        }
      }

      // Parse reviews
      final List<ProductReviewModel> reviews = [];
      for (var json in reviewsJson) {
        if (json == null) continue;
        try {
          final review = ProductReviewModel.fromJson(json);
          reviews.add(review);
        } catch (e) {
          print('Repository: Error parsing review: $e');
          print('Repository: Problematic JSON: $json');
        }
      }

      print('Repository: Successfully parsed ${reviews.length} reviews');
      return reviews;
    } catch (e) {
      print('Error in getProductReviews: $e');
      return [];
    }
  }

  Future<dio.Response> submitReview(
      int transactionId, Map<String, dynamic> reviewData) async {
    try {
      return await provider.submitReview(transactionId, reviewData);
    } catch (e) {
      throw Exception('Failed to submit review: $e');
    }
  }

  Future<dio.Response> getReviewStatus(int transactionId) async {
    try {
      return await provider.getReviewStatus(transactionId);
    } catch (e) {
      throw Exception('Failed to get review status: $e');
    }
  }

  Future<dio.Response> getMerchantReviews(int merchantId,
      {int? rating, int limit = 10}) async {
    try {
      return await provider.getMerchantReviews(merchantId, rating: rating, limit: limit);
    } catch (e) {
      throw Exception('Failed to get merchant reviews: $e');
    }
  }

  Future<dio.Response> getCourierReviews(int courierId,
      {int limit = 10}) async {
    try {
      return await provider.getCourierReviews(courierId, limit: limit);
    } catch (e) {
      throw Exception('Failed to get courier reviews: $e');
    }
  }
}
