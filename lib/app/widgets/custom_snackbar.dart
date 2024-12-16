import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';

void showCustomSnackbar({
  required String title,
  required String message,
  bool isError = false,
  Color? backgroundColor,
  SnackPosition? snackPosition,
}) {
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.TOP,
    backgroundColor: isError ? Colors.red : Colors.green,
    colorText: Colors.white,
    borderRadius: Dimenssions.radius15,
    margin: EdgeInsets.all(Dimenssions.width20),
    padding: EdgeInsets.symmetric(
      horizontal: Dimenssions.width20,
      vertical: Dimenssions.height15,
    ),
    icon: Icon(
      isError ? Icons.error_outline : Icons.check_circle_outline,
      color: Colors.white,
    ),
    shouldIconPulse: true,
    duration: const Duration(seconds: 3),
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
    forwardAnimationCurve: Curves.easeOutBack,
  );
}
