import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/data/providers/review_provider.dart';
import 'package:antarkanma/app/constants/app_colors.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';

class ReviewPage extends StatefulWidget {
  final TransactionModel transaction;

  const ReviewPage({super.key, required this.transaction});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final ReviewProvider _reviewProvider = ReviewProvider();
  bool _isSubmitting = false;

  // Courier review
  int _courierRating = 0;
  final TextEditingController _courierNoteController = TextEditingController();

  // Merchant reviews: merchantId -> {rating, comment controller}
  final Map<int, int> _merchantRatings = {};
  final Map<int, TextEditingController> _merchantCommentControllers = {};

  // Product reviews: productId -> {rating, comment controller}
  final Map<int, int> _productRatings = {};
  final Map<int, TextEditingController> _productCommentControllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize merchant and product ratings
    for (var order in widget.transaction.orders) {
      _merchantRatings[order.merchantId] = 0;
      _merchantCommentControllers[order.merchantId] = TextEditingController();
      for (var item in order.orderItems) {
        final pid = item.product.id;
        if (pid != null && !_productRatings.containsKey(pid)) {
          _productRatings[pid] = 0;
          _productCommentControllers[pid] = TextEditingController();
        }
      }
    }
  }

  @override
  void dispose() {
    _courierNoteController.dispose();
    for (var c in _merchantCommentControllers.values) {
      c.dispose();
    }
    for (var c in _productCommentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitReview() async {
    // At least one review must be provided
    bool hasAnyRating = _courierRating > 0 ||
        _merchantRatings.values.any((r) => r > 0) ||
        _productRatings.values.any((r) => r > 0);

    if (!hasAnyRating) {
      CustomSnackbarX.showError(
        title: 'Perhatian',
        message: 'Berikan minimal satu rating',
        position: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final Map<String, dynamic> reviewData = {};

      // Courier review
      if (_courierRating > 0) {
        reviewData['courier_review'] = {
          'rating': _courierRating,
          'note': _courierNoteController.text.isNotEmpty
              ? _courierNoteController.text
              : null,
        };
      }

      // Merchant reviews
      final merchantReviews = <Map<String, dynamic>>[];
      for (var order in widget.transaction.orders) {
        final mid = order.merchantId;
        final rating = _merchantRatings[mid] ?? 0;
        if (rating > 0) {
          merchantReviews.add({
            'merchant_id': mid,
            'order_id': order.id,
            'rating': rating,
            'comment': _merchantCommentControllers[mid]?.text.isNotEmpty == true
                ? _merchantCommentControllers[mid]!.text
                : null,
          });
        }
      }
      if (merchantReviews.isNotEmpty) {
        reviewData['merchant_reviews'] = merchantReviews;
      }

      // Product reviews
      final productReviews = <Map<String, dynamic>>[];
      _productRatings.forEach((pid, rating) {
        if (rating > 0) {
          productReviews.add({
            'product_id': pid,
            'rating': rating,
            'comment': _productCommentControllers[pid]?.text.isNotEmpty == true
                ? _productCommentControllers[pid]!.text
                : null,
          });
        }
      });
      if (productReviews.isNotEmpty) {
        reviewData['product_reviews'] = productReviews;
      }

      final response = await _reviewProvider.submitReview(
        int.parse(widget.transaction.id.toString()),
        reviewData,
      );

      if (response.statusCode == 200 &&
          response.data['meta']?['status'] == 'success') {
        CustomSnackbarX.showSuccess(
          title: 'Berhasil',
          message: 'Terima kasih atas review Anda!',
          position: SnackPosition.BOTTOM,
        );
        Get.back(result: true);
      } else {
        final msg =
            response.data['meta']?['message'] ?? 'Gagal menyimpan review';
        CustomSnackbarX.showError(
          title: 'Error',
          message: msg,
          position: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      CustomSnackbarX.showError(
        title: 'Error',
        message: 'Gagal menyimpan review: $e',
        position: SnackPosition.BOTTOM,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Beri Penilaian'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.rate_review_rounded,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  const Text(
                    'Bagaimana pengalaman Anda?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Transaksi #${widget.transaction.id}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Courier Rating Section
            _buildSectionCard(
              icon: Icons.delivery_dining,
              title: 'Rating Kurir',
              child: Column(
                children: [
                  _buildInteractiveStars(_courierRating, (rating) {
                    setState(() => _courierRating = rating);
                  }),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _courierNoteController,
                    maxLines: 2,
                    decoration: _inputDecoration('Catatan untuk kurir...'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Merchant Rating Section
            for (var order in widget.transaction.orders) ...[
              _buildSectionCard(
                icon: Icons.store,
                title: 'Rating ${order.merchantName}',
                child: Column(
                  children: [
                    _buildInteractiveStars(
                      _merchantRatings[order.merchantId] ?? 0,
                      (rating) {
                        setState(
                            () => _merchantRatings[order.merchantId] = rating);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _merchantCommentControllers[order.merchantId],
                      maxLines: 2,
                      decoration:
                          _inputDecoration('Komentar untuk merchant...'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Product Rating Section
            _buildSectionCard(
              icon: Icons.restaurant_menu,
              title: 'Rating Makanan',
              child: Column(
                children: [
                  for (var order in widget.transaction.orders)
                    for (var item in order.orderItems)
                      if (item.product.id != null)
                        _buildProductRatingTile(item),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Kirim Review',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInteractiveStars(int currentRating, ValueChanged<int> onTap) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => onTap(starIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starIndex <= currentRating ? Icons.star : Icons.star_border,
              color:
                  starIndex <= currentRating ? Colors.amber : AppColors.divider,
              size: 36,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProductRatingTile(dynamic item) {
    final pid = item.product.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Product thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 48,
                  height: 48,
                  color: AppColors.background,
                  child: item.product.firstImageUrl != null
                      ? Image.network(
                          item.product.firstImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.fastfood,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : const Icon(Icons.fastfood,
                          color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name ?? 'Produk',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInteractiveStars(
            _productRatings[pid] ?? 0,
            (rating) {
              setState(() => _productRatings[pid] = rating);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _productCommentControllers[pid],
            maxLines: 2,
            decoration: _inputDecoration('Komentar untuk produk ini...'),
          ),
          if (pid != _productRatings.keys.last) const Divider(height: 24),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }
}
