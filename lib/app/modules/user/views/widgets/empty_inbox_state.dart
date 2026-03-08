import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class EmptyInboxState extends StatelessWidget {
  const EmptyInboxState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: secondaryTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: primaryTextStyle.copyWith(
              fontSize: 18,
              fontWeight: semiBold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifikasi pesanan dan promosi akan\nmuncul di sini',
            style: secondaryTextStyle.copyWith(
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
