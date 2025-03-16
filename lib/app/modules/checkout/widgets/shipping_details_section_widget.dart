import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/shipping_details_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/modules/checkout/widgets/shipping_details_widget.dart';

class ShippingDetailsSectionWidget extends StatelessWidget {
  final ShippingDetails? shippingDetails;

  const ShippingDetailsSectionWidget({
    super.key,
    required this.shippingDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (shippingDetails == null) {
      return const SizedBox.shrink();
    }

    final merchantCount = shippingDetails!.routeSummary.totalMerchants;

    // For single merchant, don't show the section at all
    if (merchantCount <= 1) {
      return const SizedBox.shrink();
    }

    // For multiple merchants, show the full section
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor1,
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
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: logoColorSecondary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backgroundColor1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping_outlined,
                    size: 24,
                    color: logoColorSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informasi Pengiriman',
                        style: primaryTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$merchantCount merchant dalam satu pengiriman',
                        style: secondaryTextStyle.copyWith(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ShippingDetailsWidget(shippingDetails: shippingDetails!),
          ),
        ],
      ),
    );
  }
}
