import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/widgets/order_status_badge.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final TransactionModel transaction;
  final Function(TransactionModel) onTap;

  const OrderCard({
    Key? key,
    required this.transaction,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(transaction),
      child: Container(
        margin: EdgeInsets.only(bottom: Dimenssions.height15),
        padding: EdgeInsets.all(Dimenssions.height12),
        decoration: BoxDecoration(
          color: backgroundColor1,
          borderRadius: BorderRadius.circular(Dimenssions.radius8),
          border: Border.all(color: backgroundColor3.withValues(alpha: 26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction ID and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction #${transaction.id}',
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font14,
                        fontWeight: medium,
                      ),
                    ),
                    if (transaction.createdAt != null) ...[
                      SizedBox(height: Dimenssions.height4),
                      Text(
                        DateFormat('dd MMM yyyy HH:mm').format(transaction.createdAt!),
                        style: secondaryTextStyle.copyWith(
                          fontSize: Dimenssions.font12,
                        ),
                      ),
                    ],
                  ],
                ),
                OrderStatusBadge(status: transaction.status),
              ],
            ),
            SizedBox(height: Dimenssions.height12),
            Divider(height: 1, color: backgroundColor3.withValues(alpha: 51)),
            SizedBox(height: Dimenssions.height12),
            // Orders from different merchants
            ...transaction.orders.map((order) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Merchant name and Order ID
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.merchantName,
                            style: primaryTextStyle.copyWith(
                              fontSize: Dimenssions.font14,
                              fontWeight: semiBold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: Dimenssions.height4),
                          Text(
                            'Order #${order.id}',
                            style: secondaryTextStyle.copyWith(
                              fontSize: Dimenssions.font12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OrderStatusBadge(status: order.orderStatus),
                  ],
                ),
                SizedBox(height: Dimenssions.height8),
                // Order items preview
                ...order.orderItems.take(2).map((item) => Padding(
                  padding: EdgeInsets.only(bottom: Dimenssions.height8),
                  child: Row(
                    children: [
                      Container(
                        width: Dimenssions.height40,
                        height: Dimenssions.height40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Dimenssions.radius4),
                          border: Border.all(
                            color: backgroundColor3.withValues(alpha: 51),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Dimenssions.radius4),
                          child: Image.network(
                            item.product.firstImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: backgroundColor3.withValues(alpha: 26),
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: secondaryTextColor,
                                size: Dimenssions.font16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: Dimenssions.width8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${item.quantity}x ${item.formattedPrice}',
                              style: secondaryTextStyle.copyWith(
                                fontSize: Dimenssions.font12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
                // Show more items indicator if needed
                if (order.orderItems.length > 2)
                  Text(
                    '+${order.orderItems.length - 2} item lainnya',
                    style: secondaryTextStyle.copyWith(
                      fontSize: Dimenssions.font12,
                    ),
                  ),
                // Add divider between orders
                if (order != transaction.orders.last) ...[
                  SizedBox(height: Dimenssions.height12),
                  Divider(height: 1, color: backgroundColor3.withValues(alpha: 51)),
                  SizedBox(height: Dimenssions.height12),
                ],
              ],
            )),
            SizedBox(height: Dimenssions.height12),
            Divider(height: 1, color: backgroundColor3.withValues(alpha: 51)),
            SizedBox(height: Dimenssions.height12),
            // Total amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font12,
                    fontWeight: medium,
                  ),
                ),
                Text(
                  transaction.formattedGrandTotal,
                  style: priceTextStyle.copyWith(
                    fontSize: Dimenssions.font14,
                    fontWeight: semiBold,
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
