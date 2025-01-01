import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final StatusInfo statusInfo = _getStatusInfo(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimenssions.width10,
        vertical: Dimenssions.height5,
      ),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
        border: Border.all(
          color: statusInfo.color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        statusInfo.text,
        style: primaryTextStyle.copyWith(
          color: statusInfo.color,
          fontSize: Dimenssions.font12,
          fontWeight: semiBold,
        ),
      ),
    );
  }

  StatusInfo _getStatusInfo(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return StatusInfo(
          color: priceColor,
          text: 'Menunggu Konfirmasi',
        );
      case 'ACCEPTED':
        return StatusInfo(
          color: Colors.green,
          text: 'Diterima',
        );
      case 'REJECTED':
        return StatusInfo(
          color: Colors.red,
          text: 'Ditolak',
        );
      case 'PROCESSING':
        return StatusInfo(
          color: logoColorSecondary,
          text: 'Sedang Diproses',
        );
      case 'SHIPPED':
        return StatusInfo(
          color: Colors.blue,
          text: 'Dalam Pengiriman',
        );
      case 'DELIVERED':
        return StatusInfo(
          color: Colors.purple,
          text: 'Terkirim',
        );
      case 'ON_DELIVERY':
        return StatusInfo(
          color: Colors.blue,
          text: 'Dalam Pengiriman',
        );
      case 'COMPLETED':
        return StatusInfo(
          color: primaryColor,
          text: 'Selesai',
        );
      case 'CANCELED':
        return StatusInfo(
          color: alertColor,
          text: 'Dibatalkan',
        );
      default:
        return StatusInfo(
          color: secondaryTextColor,
          text: status,
        );
    }
  }
}

class StatusInfo {
  final Color color;
  final String text;

  StatusInfo({
    required this.color,
    required this.text,
  });
}
