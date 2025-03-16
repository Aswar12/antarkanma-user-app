import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({
    Key? key,
    required this.status,
  }) : super(key: key);

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu';
      case 'WAITING_APPROVAL':
        return 'Menunggu Konfirmasi';
      case 'PROCESSING':
        return 'Diproses';
      case 'READY_TO_PICKUP':
        return 'Siap Diambil';
      case 'PICKED_UP':
        return 'Dalam Perjalanan';
      case 'DELIVERED':
        return 'Terkirim';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'WAITING_APPROVAL':
        return Colors.orange;
      case 'PROCESSING':
      case 'READY_TO_PICKUP':
        return Colors.blue;
      case 'PICKED_UP':
        return logoColorSecondary;
      case 'DELIVERED':
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELED':
        return alertColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimenssions.width8,
        vertical: Dimenssions.height4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimenssions.radius4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: primaryTextStyle.copyWith(
          fontSize: Dimenssions.font12,
          color: color,
          fontWeight: medium,
        ),
      ),
    );
  }
}
