import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/shipping_details_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:intl/intl.dart';

class ShippingDetailsWidget extends StatelessWidget {
  final ShippingDetails shippingDetails;

  const ShippingDetailsWidget({
    super.key,
    required this.shippingDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text(
          'Detail Pengiriman',
          style: primaryTextStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),

        // Warning message if route should be split
        if (shippingDetails.recommendations.shouldSplit)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shippingDetails.recommendations.reason,
                        style: primaryTextStyle.copyWith(
                          color: Colors.red[700],
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Manfaat split order:',
                  style: primaryTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...shippingDetails.recommendations.benefits.entries.map((benefit) =>
                  Text(
                    '• ${benefit.value}',
                    style: primaryTextStyle.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Cost comparison
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor3.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: backgroundColor3.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perbandingan Biaya',
                style: primaryTextStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Tunggal',
                    style: primaryTextStyle,
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(shippingDetails.costComparison.singleOrderTotal),
                    style: primaryTextStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                shippingDetails.costComparison.singleOrderBreakdown,
                style: secondaryTextStyle.copyWith(fontSize: 12),
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Terpisah',
                    style: primaryTextStyle,
                  ),
                  Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(shippingDetails.costComparison.separateOrdersTotal),
                    style: primaryTextStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                shippingDetails.costComparison.separateOrdersBreakdown,
                style: secondaryTextStyle.copyWith(fontSize: 12),
              ),
              const Divider(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Penghematan',
                      style: primaryTextStyle.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(shippingDetails.costComparison.savingsAmount),
                      style: primaryTextStyle.copyWith(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Direction Groups
        ...shippingDetails.routeSummary.directionGroups.map((group) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor3.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: backgroundColor3.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grup ${group.groupId}',
                      style: primaryTextStyle.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(group.totalCost),
                      style: primaryTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: logoColorSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Merchant:',
                  style: primaryTextStyle.copyWith(fontSize: 12),
                ),
                ...group.merchants.map((merchant) =>
                  Text(
                    '• $merchant',
                    style: primaryTextStyle.copyWith(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.route, size: 16, color: logoColorSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Arah: ${group.baseAngle.toStringAsFixed(1)}°',
                      style: primaryTextStyle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        // Split Order Suggestions
        if (shippingDetails.recommendations.shouldSplit) ...[
          Text(
            'Rekomendasi Split Order',
            style: primaryTextStyle.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          ...shippingDetails.recommendations.suggestedSplits.map((suggestion) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: suggestion.createNewOrder 
                  ? Colors.orange[50] 
                  : Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: suggestion.createNewOrder 
                    ? Colors.orange[100]! 
                    : Colors.green[100]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        suggestion.createNewOrder 
                          ? 'Order Baru' 
                          : 'Order Ini',
                        style: primaryTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: suggestion.createNewOrder 
                            ? Colors.orange[700] 
                            : Colors.green[700],
                        ),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(suggestion.total),
                        style: primaryTextStyle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: suggestion.createNewOrder 
                            ? Colors.orange[700] 
                            : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Merchant:',
                    style: primaryTextStyle.copyWith(fontSize: 12),
                  ),
                  ...suggestion.merchants.map((merchant) =>
                    Text(
                      '• $merchant',
                      style: primaryTextStyle.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],

        // Total Shipping Cost
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: logoColorSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Ongkir',
                style: primaryTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(shippingDetails.totalShippingPrice),
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
