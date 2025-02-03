import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductInfoSection extends StatelessWidget {
  final ProductModel product;
  final double totalPrice; // Changed from int to double

  const ProductInfoSection({
    super.key,
    required this.product,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Dimenssions.height20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font16,
                        fontWeight: semiBold,
                      ),
                    ),
                    SizedBox(height: Dimenssions.height8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimenssions.width12,
                        vertical: Dimenssions.height6,
                      ),
                      decoration: BoxDecoration(
                        color: logoColorSecondary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(Dimenssions.radius20),
                      ),
                      child: Text(
                        product.category?.name ?? 'No Category',
                        style: primaryTextOrange.copyWith(
                          fontWeight: medium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimenssions.width12,
                  vertical: Dimenssions.height6,
                ),
                decoration: BoxDecoration(
                  color: product.status == 'ACTIVE'
                      ? Colors.green.withOpacity(0.1)
                      : alertColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimenssions.radius20),
                ),
                child: Text(
                  product.status ?? 'Habis',
                  style: TextStyle(
                    color:
                        product.status == 'ACTIVE' ? Colors.green : alertColor,
                    fontWeight: medium,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimenssions.height16),
          Text(
            'Rp ${NumberFormat('#,###', 'id_ID').format(totalPrice)}',
            style: priceTextStyle.copyWith(
              fontSize: Dimenssions.font20,
              fontWeight: semiBold,
            ),
          ),
          SizedBox(height: Dimenssions.height24),
          Text(
            'Deskripsi Produk',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font16,
              fontWeight: semiBold,
            ),
          ),
          SizedBox(height: Dimenssions.height8),
          Text(
            product.description,
            style: secondaryTextStyle.copyWith(
              height: 1.5,
              fontSize: Dimenssions.font16,
            ),
          ),
        ],
      ),
    );
  }
}
