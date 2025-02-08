import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class ShippingSavingsSummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> merchantDeliveries;
  final double totalShippingPrice;

  const ShippingSavingsSummaryWidget({
    super.key,
    required this.merchantDeliveries,
    required this.totalShippingPrice,
  });

  @override
  Widget build(BuildContext context) {
    if (merchantDeliveries.length <= 1) return const SizedBox.shrink();

    final totalOverlap = merchantDeliveries.fold<double>(
      0.0,
      (sum, delivery) => sum + (delivery['overlap_distance'] as num).toDouble(),
    );

    if (totalOverlap <= 0) return const SizedBox.shrink();

    // Estimate savings based on overlap distance
    // Assuming average cost per km is totalShippingPrice / total distance
    final totalDistance = merchantDeliveries.fold<double>(
      0.0,
      (sum, delivery) => sum + (delivery['distance'] as num).toDouble(),
    );
    final costPerKm = totalShippingPrice / totalDistance;
    final estimatedSavings = totalOverlap * costPerKm;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.savings, 
                size: 18, 
                color: Colors.green[700],
              ),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Penghematan',
                style: primaryTextStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jarak yang dihemat:',
                style: primaryTextStyle.copyWith(
                  fontSize: 12,
                ),
              ),
              Text(
                '${totalOverlap.toStringAsFixed(1)} km',
                style: primaryTextStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Estimasi penghematan:',
                style: primaryTextStyle.copyWith(
                  fontSize: 12,
                ),
              ),
              Text(
                'Rp ${estimatedSavings.toStringAsFixed(0)}',
                style: primaryTextStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.eco, 
                  size: 16, 
                  color: Colors.green[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dengan menggabungkan pengiriman, Anda turut membantu mengurangi emisi karbon',
                    style: primaryTextStyle.copyWith(
                      fontSize: 12,
                      color: Colors.green[700],
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
