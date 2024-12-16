// lib/app/widgets/logout_confirmation_dialog.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/controllers/auth_controller.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return AlertDialog(
      title: Text('Konfirmasi Logout', style: primaryTextStyle),
      content:
          Text('Apakah Anda yakin ingin keluar?', style: subtitleTextStyle),
      backgroundColor: backgroundColor3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      actions: <Widget>[
        TextButton(
          child: Text('Batal', style: primaryTextStyle),
          onPressed: () => Get.back(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: logoColorSecondary),
          onPressed: () {
            Get.back();
            authController.logout();
          },
          child: Text(
            'KeluarMi',
            style: textwhite,
          ),
        ),
      ],
    );
  }
}
