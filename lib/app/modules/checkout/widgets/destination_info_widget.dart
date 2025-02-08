import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class DestinationInfoWidget extends StatelessWidget {
  final Map<String, dynamic> destination;

  const DestinationInfoWidget({
    super.key,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, 
                size: 16, 
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Tujuan Pengiriman',
                style: primaryTextStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            destination['address'] ?? '',
            style: primaryTextStyle.copyWith(
              fontSize: 12,
            ),
          ),
          Text(
            '${destination['district']}, ${destination['city']}',
            style: primaryTextStyle.copyWith(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (destination['postal_code'] != null)
            Text(
              'Kode Pos: ${destination['postal_code']}',
              style: primaryTextStyle.copyWith(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
}
