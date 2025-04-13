import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class EmptyOrderPlaceholder extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyOrderPlaceholder({
    Key? key,
    this.message = 'Tidak ada pesanan untuk ditampilkan.',
    this.icon = Icons.receipt_long_outlined,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: Dimenssions.iconSize24 * 3,
            color: secondaryTextColor.withOpacity(0.5),
          ),
          SizedBox(height: Dimenssions.height15),
          Text(
            message,
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font16,
              color: secondaryTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
