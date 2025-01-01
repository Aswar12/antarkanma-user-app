import 'package:antarkanma/app/widgets/quantity_button.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductBottomNav extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final bool isProductActive;

  const ProductBottomNav({
    Key? key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.isProductActive,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(Dimenssions.height15),
      decoration: BoxDecoration(
        color: backgroundColor1,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Row(
              children: [
                QuantityButton(
                  icon: Icons.remove,
                  onTap: onDecrement,
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: Dimenssions.width12),
                  child: Text(
                    quantity.toString(),
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font14,
                      fontWeight: semiBold,
                    ),
                  ),
                ),
                QuantityButton(
                  icon: Icons.add,
                  onTap: onIncrement,
                ),
              ],
            ),
            SizedBox(width: Dimenssions.width12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: quantity > 0 ? onAddToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: logoColorSecondary,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                            vertical: Dimenssions.height16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimenssions.radius12),
                          side: BorderSide(color: logoColorSecondary),
                        ),
                      ),
                      child: Text(
                        'Keranjang',
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font16,
                          fontWeight: semiBold,
                          color: logoColorSecondary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Dimenssions.width12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: quantity > 0
                          ? () {
                              if (!isProductActive) {
                                Get.snackbar(
                                  'Tidak Tersedia',
                                  'Produk ini sedang tidak tersedia',
                                  backgroundColor: Colors.red,
                                  colorText: Colors.white,
                                );
                                return;
                              }
                              onBuyNow();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: logoColorSecondary,
                        padding: EdgeInsets.symmetric(
                            vertical: Dimenssions.height16),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimenssions.radius12),
                        ),
                      ),
                      child: Text(
                        'Beli Sekarang',
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font16,
                          fontWeight: semiBold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
