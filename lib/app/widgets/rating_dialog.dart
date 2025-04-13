import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';
import 'package:get/get.dart';

class RatingDialog extends StatefulWidget {
  final String productName;
  final String productImage;
  final Function(int rating, String review) onSubmit;

  const RatingDialog({
    Key? key,
    required this.productName,
    required this.productImage,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Widget _buildStar(int index) {
    return IconButton(
      onPressed: () {
        setState(() {
          _rating = index + 1;
        });
      },
      icon: Icon(
        index < _rating ? Icons.star : Icons.star_border,
        color: index < _rating ? Colors.amber : Colors.grey,
        size: 32,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimenssions.radius12),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimenssions.height20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Beri Rating',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font18,
                fontWeight: semiBold,
              ),
            ),
            SizedBox(height: Dimenssions.height20),
            Container(
              width: Dimenssions.height60,
              height: Dimenssions.height60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimenssions.radius8),
                border: Border.all(color: backgroundColor3.withValues(alpha: 51)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimenssions.radius8),
                child: Image.network(
                  widget.productImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: backgroundColor3.withValues(alpha: 26),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: secondaryTextColor,
                      size: Dimenssions.font24,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: Dimenssions.height12),
            Text(
              widget.productName,
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font14,
                fontWeight: medium,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: Dimenssions.height20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: Dimenssions.width4),
                  child: _buildStar(index),
                );
              }),
            ),
            SizedBox(height: Dimenssions.height16),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimenssions.width16,
                vertical: Dimenssions.height12,
              ),
              decoration: BoxDecoration(
                color: backgroundColor2,
                borderRadius: BorderRadius.circular(Dimenssions.radius12),
                border: Border.all(color: backgroundColor3),
              ),
              child: TextField(
                controller: _reviewController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tulis ulasan Anda...',
                  hintStyle: secondaryTextStyle,
                  border: InputBorder.none,
                ),
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font14,
                ),
              ),
            ),
            SizedBox(height: Dimenssions.height20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: logoColorSecondary,
                      side: BorderSide(color: logoColorSecondary),
                      padding: EdgeInsets.symmetric(vertical: Dimenssions.height12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimenssions.radius12),
                      ),
                    ),
                    child: Text(
                      'Batal',
                      style: primaryTextOrange,
                    ),
                  ),
                ),
                SizedBox(width: Dimenssions.width12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _rating == 0
                        ? null
                        : () {
                            widget.onSubmit(_rating, _reviewController.text);
                            Get.back();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: logoColor,
                      padding: EdgeInsets.symmetric(vertical: Dimenssions.height12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimenssions.radius12),
                      ),
                    ),
                    child: Text(
                      'Kirim',
                      style: primaryTextStyle.copyWith(
                        color: Colors.white,
                        fontWeight: medium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
