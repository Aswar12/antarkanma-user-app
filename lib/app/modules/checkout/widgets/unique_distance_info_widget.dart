import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class UniqueDistanceInfoWidget extends StatelessWidget {
  final double uniqueDistance;
  final String merchantName;

  const UniqueDistanceInfoWidget({
    super.key,
    required this.uniqueDistance,
    required this.merchantName,
  });

  @override
  Widget build(BuildContext context) {
    if (uniqueDistance <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor3.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: backgroundColor3.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.route, 
            size: 16, 
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rute Unik $merchantName',
                  style: primaryTextStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${uniqueDistance.toStringAsFixed(1)} km jarak tambahan khusus untuk merchant ini',
                  style: primaryTextStyle.copyWith(
                    fontSize: 12,
                    color: Colors.grey[600],
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
