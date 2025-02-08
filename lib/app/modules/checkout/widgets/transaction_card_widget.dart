import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/app/data/models/shipping_details_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/modules/checkout/widgets/order_items_widget.dart';
import 'package:antarkanma/app/modules/checkout/widgets/shipping_details_section_widget.dart';

class TransactionCardWidget extends StatelessWidget {
  final TransactionModel transaction;
  final UserLocationModel deliveryAddress;
  final ShippingDetails? shippingDetails;

  const TransactionCardWidget({
    super.key,
    required this.transaction,
    required this.deliveryAddress,
    this.shippingDetails,
  });

  Widget _buildOrderDetail(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: secondaryTextStyle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: primaryTextStyle.copyWith(
              color: valueColor,
              fontWeight: medium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order ID: ${transaction.orderId}',
                    style: primaryTextStyle.copyWith(
                      fontWeight: semiBold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: transaction.status.toUpperCase() == 'PENDING'
                        ? priceColor.withOpacity(0.1)
                        : logoColorSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.statusDisplay,
                    style: primaryTextStyle.copyWith(
                      color: transaction.status.toUpperCase() == 'PENDING'
                          ? priceColor
                          : logoColorSecondary,
                      fontWeight: medium,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Orders List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transaction.orders.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) => OrderItemsWidget(
                order: transaction.orders[index],
              ),
            ),
            // Add Shipping Details Section if available
            if (shippingDetails != null) ...[
              const SizedBox(height: 16),
              ShippingDetailsSectionWidget(shippingDetails: shippingDetails),
            ],
            const SizedBox(height: 16),
            // Display subtotal
            _buildOrderDetail(
              'Subtotal',
              'Rp ${transaction.totalPrice.toStringAsFixed(0)}',
              Colors.grey[700],
            ),
            // Display shipping cost
            _buildOrderDetail(
              'Biaya Pengiriman',
              'Rp ${shippingDetails?.totalShippingPrice.toStringAsFixed(0) ?? transaction.shippingPrice.toStringAsFixed(0)}',
              Colors.grey[700],
            ),
            const Divider(),
            // Display total payment (subtotal + shipping)
            _buildOrderDetail(
              'Total Pembayaran',
              'Rp ${(transaction.totalPrice + (shippingDetails?.totalShippingPrice ?? transaction.shippingPrice)).toStringAsFixed(0)}',
              logoColorSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
