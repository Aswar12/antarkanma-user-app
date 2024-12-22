import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/data/models/product_review_model.dart';
import 'package:antarkanma/app/data/providers/product_provider.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ProductService extends GetxService {
  final ProductProvider _productProvider = ProductProvider();
  final _storage = GetStorage();
  static const String _productsKey = 'products';
  static const String _lastRefreshKey = 'last_refresh';
  static const String _popularProductsKey = 'popular_products';
  static const String _reviewsKey = 'product_reviews';

  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;
      final storedProducts = _storage.read(_productsKey);
      final lastRefresh = _storage.read(_lastRefreshKey);

      final shouldRefresh = lastRefresh == null ||
          DateTime.now().difference(DateTime.parse(lastRefresh)).inHours > 1;

      if (storedProducts != null && !shouldRefresh) {
        try {
          final List<dynamic> productList = storedProducts;
          products.value = productList
              .map(
                  (json) => ProductModel.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          print('Error parsing stored products: $e');
          await refreshProducts();
        }
      } else {
        await refreshProducts();
      }
    } catch (e) {
      print('Error in fetchProducts: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to load products: ${e.toString()}',
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshProducts() async {
    try {
      final response = await _productProvider.getAllProducts();

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        // Convert to List<ProductModel> and ensure rating info is included
        final List<ProductModel> updatedProducts = [];
        for (var json in productList) {
          // Make sure rating info is properly parsed from the API response
          if (json['rating_info'] == null) {
            if (json['average_rating'] != null) {
              json['rating_info'] = {
                'average_rating':
                    double.tryParse(json['average_rating'].toString()) ?? 0.0,
                'total_reviews': json['total_reviews'] ?? 0,
              };
            } else {
              // If no rating info at all, fetch it
              final product =
                  ProductModel.fromJson(json as Map<String, dynamic>);
              if (product.id != null) {
                final reviewData = await getProductWithReviews(product.id!);
                json['rating_info'] = reviewData['rating_info'];
                json['average_rating'] =
                    reviewData['rating_info']['average_rating'].toString();
                json['total_reviews'] =
                    reviewData['rating_info']['total_reviews'];
              }
            }
          }

          final product = ProductModel.fromJson(json as Map<String, dynamic>);
          updatedProducts.add(product);
        }

        products.value = updatedProducts;

        // Save to local storage with rating info
        await _storage.write(
            _productsKey, updatedProducts.map((p) => p.toJson()).toList());
        await _storage.write(_lastRefreshKey, DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Error in refreshProducts: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to refresh products: ${e.toString()}',
        isError: true,
      );
    }
  }

  List<ProductModel> get productsList => products;

  Future<void> getProductsByCategory(int categoryId) async {
    try {
      isLoading.value = true;
      final response = await _productProvider.getProductsByCategory(categoryId);

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        // Convert to List<ProductModel> and ensure rating info is included
        final List<ProductModel> updatedProducts = [];
        for (var json in productList) {
          final product = ProductModel.fromJson(json as Map<String, dynamic>);

          // If rating info is not included in the response, fetch it
          if (product.ratingInfo == null && product.id != null) {
            final reviewData = await getProductWithReviews(product.id!);
            final updatedProduct = product.copyWith(
              averageRatingRaw:
                  reviewData['rating_info']['average_rating'].toString(),
              totalReviewsRaw:
                  reviewData['rating_info']['total_reviews'] as int,
              ratingInfo: reviewData['rating_info'] as Map<String, dynamic>,
              reviews:
                  (reviewData['reviews'] as List).cast<ProductReviewModel>(),
            );
            updatedProducts.add(updatedProduct);
          } else {
            updatedProducts.add(product);
          }
        }

        products.value = updatedProducts;

        // Save to local storage with rating info
        await _storage.write(
            _productsKey, updatedProducts.map((p) => p.toJson()).toList());
      }
    } catch (e) {
      print('Error in getProductsByCategory: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to load products by category: ${e.toString()}',
        isError: true,
      );

      // If API call fails, try to use filtered products from local storage
      final storedProducts = _storage.read(_productsKey);
      if (storedProducts != null) {
        try {
          final List<dynamic> allProducts = storedProducts;
          final allProductsList = allProducts
              .map(
                  (json) => ProductModel.fromJson(json as Map<String, dynamic>))
              .toList();

          // Filter stored products by category
          products.value = allProductsList
              .where((product) => product.category?.id == categoryId)
              .toList();
        } catch (e) {
          print('Error parsing stored products: $e');
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Get all products from local storage
  List<ProductModel> getAllProductsFromStorage() {
    try {
      final storedProducts = _storage.read(_productsKey);
      if (storedProducts != null) {
        final List<dynamic> productList = storedProducts;
        return productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error getting products from storage: $e');
    }
    return [];
  }

  Future<List<ProductModel>> getPopularProducts({
    int? limit,
    int? categoryId,
    double minRating = 4.0,
    int minReviews = 5,
  }) async {
    try {
      final response = await _productProvider.getPopularProducts(
        limit: limit,
        categoryId: categoryId,
        minRating: minRating,
        minReviews: minReviews,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> productList =
            data is Map ? data['data'] as List : data as List;

        // Save raw data to storage
        await _storage.write(_popularProductsKey, productList);

        // Convert to models and ensure rating info is included
        final List<ProductModel> products = [];
        for (var json in productList) {
          // Make sure rating info is properly parsed from the API response
          if (json['rating_info'] == null && json['average_rating'] != null) {
            json['rating_info'] = {
              'average_rating':
                  double.tryParse(json['average_rating'].toString()) ?? 0.0,
              'total_reviews': json['total_reviews'] ?? 0,
            };
          }
          final product = ProductModel.fromJson(json as Map<String, dynamic>);
          products.add(product);
        }

        // Save to storage with rating info
        await _storage.write(
            _popularProductsKey, products.map((p) => p.toJson()).toList());

        return products;
      }
      return _getPopularProductsFromStorage();
    } catch (e) {
      print('Error in getPopularProducts: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to load popular products: ${e.toString()}',
        isError: true,
      );
      return _getPopularProductsFromStorage();
    }
  }

  // Review management methods
  Future<bool> submitReview({
    required int productId,
    required int rating,
    required String comment,
    required String token,
  }) async {
    try {
      final response = await _productProvider.submitProductReview({
        'product_id': productId,
        'rating': rating,
        'comment': comment,
      }, token);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // After successful submission, refresh the product's reviews
        await refreshProductReviews(
          ProductModel(
            id: productId,
            name: '',
            description: '',
            price: 0,
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error submitting review: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to submit review: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  Future<bool> updateReview({
    required int reviewId,
    required int rating,
    required String comment,
    required String token,
  }) async {
    try {
      final response = await _productProvider.updateProductReview(
        reviewId,
        {
          'rating': rating,
          'comment': comment,
        },
        token,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating review: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to update review: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  Future<bool> deleteReview({
    required int reviewId,
    required String token,
  }) async {
    try {
      final response =
          await _productProvider.deleteProductReview(reviewId, token);
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting review: $e');
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to delete review: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  // Get reviews for a specific product
  Future<List<ProductReviewModel>> getProductReviews(int productId) async {
    try {
      final response = await _productProvider.getProductReviews(productId);

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> reviewList =
            data is Map ? data['data'] as List : data as List;

        return reviewList
            .map((json) => ProductReviewModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting product reviews: $e');
      return [];
    }
  }

  // Get detailed product reviews with rating statistics
  Future<Map<String, dynamic>> getProductWithReviews(int productId) async {
    try {
      final response = await _productProvider.getProductReviews(productId);

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final List<dynamic> reviewList =
            data is Map ? data['data'] as List : data as List;

        // Calculate rating distribution
        Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        double totalRating = 0;

        final reviews = reviewList.map((json) {
          final review = ProductReviewModel.fromJson(json);
          distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
          totalRating += review.rating;
          return review;
        }).toList();

        final averageRating =
            reviews.isEmpty ? 0.0 : totalRating / reviews.length;

        // Calculate percentages
        Map<int, double> percentages = {};
        for (var rating in distribution.keys) {
          percentages[rating] = reviews.isEmpty
              ? 0.0
              : (distribution[rating]! / reviews.length) * 100;
        }

        return {
          'reviews': reviews,
          'rating_info': {
            'average_rating': double.parse(averageRating.toStringAsFixed(1)),
            'total_reviews': reviews.length,
            'distribution': distribution,
            'percentages': percentages,
          }
        };
      }
      return {
        'reviews': <ProductReviewModel>[],
        'rating_info': {
          'average_rating': 0.0,
          'total_reviews': 0,
          'distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
          'percentages': {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0},
        }
      };
    } catch (e) {
      print('Error getting product reviews: $e');
      return {
        'reviews': <ProductReviewModel>[],
        'rating_info': {
          'average_rating': 0.0,
          'total_reviews': 0,
          'distribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
          'percentages': {5: 0.0, 4: 0.0, 3: 0.0, 2: 0.0, 1: 0.0},
        }
      };
    }
  }

  // Update product with latest reviews
  Future<ProductModel?> refreshProductReviews(ProductModel product) async {
    if (product.id == null) return product;

    try {
      // Get both reviews and rating info
      final reviewData = await getProductWithReviews(product.id!);

      return product.copyWith(
        reviews: reviewData['reviews'] as List<ProductReviewModel>,
        averageRatingRaw:
            reviewData['rating_info']['average_rating'].toString(),
        totalReviewsRaw: reviewData['rating_info']['total_reviews'] as int,
        ratingInfo: reviewData['rating_info'] as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error refreshing product reviews: $e');
      return product;
    }
  }

  List<ProductModel> _getPopularProductsFromStorage() {
    try {
      final storedProducts = _storage.read('popular_products');
      if (storedProducts != null) {
        final List<dynamic> productList = storedProducts;
        return productList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error getting popular products from storage: $e');
    }
    return [];
  }

  bool hasLocalData() {
    return _storage.hasData(_productsKey);
  }

  Future<void> clearLocalStorage() async {
    await _storage.remove(_productsKey);
    await _storage.remove(_lastRefreshKey);
    products.clear();
  }
}
