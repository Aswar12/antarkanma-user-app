import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class RouteOptimizationInfoWidget extends StatelessWidget {
  final List<Map<String, dynamic>> merchantDeliveries;

  const RouteOptimizationInfoWidget({
    super.key,
    required this.merchantDeliveries,
  });

  @override
  Widget build(BuildContext context) {
    if (merchantDeliveries.length <= 1) return const SizedBox.shrink();

    final totalOverlap = merchantDeliveries.fold<double>(
      0.0,
      (sum, delivery) => sum + (delivery['overlap_distance'] as num).toDouble(),
    );

    if (totalOverlap <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: logoColorSecondary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_sharp, 
                size: 18, 
                color: logoColorSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Optimasi Rute',
                style: primaryTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: logoColorSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Pengiriman dari ${merchantDeliveries.length} merchant akan digabung untuk menghemat ongkir',
            style: primaryTextStyle.copyWith(
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total rute yang dihemat: ${totalOverlap.toStringAsFixed(1)} km',
            style: primaryTextStyle.copyWith(
              fontSize: 12,
              color: logoColorSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: logoColorSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.savings, 
                  size: 16, 
                  color: logoColorSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Anda hemat biaya dengan menggabungkan pengiriman dari beberapa merchant',
                    style: primaryTextStyle.copyWith(
                      fontSize: 12,
                      color: logoColorSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
