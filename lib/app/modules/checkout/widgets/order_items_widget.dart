import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/theme.dart';

class OrderItemsWidget extends StatelessWidget {
  final OrderModel order;

  const OrderItemsWidget({
    super.key,
    required this.order,
  });

  String _getOrderStatusDisplay(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Konfirmasi';
      case 'ACCEPTED':
        return 'Diterima';
      case 'PROCESSING':
        return 'Sedang Diproses';
      case 'READY_FOR_PICKUP':
        return 'Siap Diambil';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Merchant header with status
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor3.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.store,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.merchantName,
                  style: primaryTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: order.orderStatus.toUpperCase() == 'PENDING'
                      ? priceColor.withOpacity(0.1)
                      : logoColorSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getOrderStatusDisplay(order.orderStatus),
                  style: primaryTextStyle.copyWith(
                    color: order.orderStatus.toUpperCase() == 'PENDING'
                        ? priceColor
                        : logoColorSecondary,
                    fontWeight: medium,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: order.orderItems.length,
          separatorBuilder: (context, index) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final item = order.orderItems[index];
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.product.firstImageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: primaryTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.quantity}x ${item.formattedPrice}',
                            style: primaryTextStyle.copyWith(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            item.formattedTotalPrice,
                            style: primaryTextStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: logoColorSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor3.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pesanan',
                style: primaryTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rp ${order.totalAmount.toStringAsFixed(0)}',
                style: primaryTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: logoColorSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
