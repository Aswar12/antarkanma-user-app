import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final StatusInfo statusInfo = _getStatusInfo(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimenssions.width8,
        vertical: Dimenssions.height4,
      ),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimenssions.radius12),
        border: Border.all(
          color: statusInfo.color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusInfo.icon != null) ...[
            Icon(
              statusInfo.icon,
              size: Dimenssions.font12,
              color: statusInfo.color,
            ),
            SizedBox(width: Dimenssions.width4),
          ],
          Text(
            statusInfo.text,
            style: primaryTextStyle.copyWith(
              color: statusInfo.color,
              fontSize: 11,
              fontWeight: medium,
            ),
          ),
        ],
      ),
    );
  }

  StatusInfo _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return StatusInfo(
          color: priceColor,
          text: 'Menunggu',
          icon: Icons.hourglass_empty,
        );
      case 'PROCESSING':
        return StatusInfo(
          color: logoColorSecondary,
          text: 'Diproses',
          icon: Icons.sync,
        );
      case 'READYTOPICKUP':
        return StatusInfo(
          color: Colors.orange,
          text: 'Siap Antar',
          icon: Icons.delivery_dining,
        );
      case 'SHIPPED':
      case 'ON_DELIVERY':
        return StatusInfo(
          color: Colors.blue,
          text: 'Dikirim',
          icon: Icons.local_shipping_outlined,
        );
      case 'DELIVERED':
        return StatusInfo(
          color: Colors.purple,
          text: 'Terkirim',
          icon: Icons.done_all,
        );
      case 'COMPLETED':
        return StatusInfo(
          color: primaryColor,
          text: 'Selesai',
          icon: Icons.verified_outlined,
        );
      case 'CANCELED':
        return StatusInfo(
          color: alertColor,
          text: 'Batal',
          icon: Icons.highlight_off,
        );
      default:
        return StatusInfo(
          color: secondaryTextColor,
          text: status,
          icon: Icons.help_outline,
        );
    }
  }
}

class StatusInfo {
  final Color color;
  final String text;
  final IconData? icon;

  StatusInfo({
    required this.color,
    required this.text,
    this.icon,
  });
}
