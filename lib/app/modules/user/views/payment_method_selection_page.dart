// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/controllers/checkout_controller.dart';

class PaymentMethodSelectionPage extends GetView<CheckoutController> {
  const PaymentMethodSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor8,
      appBar: AppBar(
        title: Text(
          'Pilih Metode Pembayaran',
          style: primaryTextStyle.copyWith(fontSize: Dimenssions.font20),
        ),
        backgroundColor: backgroundColor8,
        iconTheme: IconThemeData(color: logoColorSecondary),
        elevation: 0,
        // Tambahkan leading untuk kembali
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: logoColorSecondary),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(Dimenssions.width10),
        itemCount: controller.paymentMethods.length,
        itemBuilder: (context, index) {
          final method = controller.paymentMethods[index];
          return _buildPaymentMethodCard(method);
        },
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildPaymentMethodCard(String method) {
    return Obx(() {
      final isSelected = controller.selectedPaymentMethod.value == method;
      return Card(
        elevation: isSelected ? 3 : 1, // Tambahkan sedikit elevasi saat dipilih
        color: isSelected ? backgroundColor1 : backgroundColor8,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? logoColorSecondary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
              horizontal: Dimenssions.width10,
              vertical: Dimenssions.height5 / 3),
          leading: _getPaymentMethodIcon(method),
          title: Text(
            method,
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? logoColorSecondary : null,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: logoColorSecondary)
              : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
          onTap: () {
            controller.setPaymentMethod(method);
          },
        ),
      );
    });
  }

  Widget _getPaymentMethodIcon(String method) {
    final IconData icon;
    final Color iconColor;

    switch (method) {
      case 'COD':
        icon = Icons.handshake_outlined;
        break;
      case 'Transfer Bank':
        icon = Icons.account_balance;
        break;
      case 'DANA':
        icon = Icons.account_balance_wallet;
        break;
      case 'OVO':
        icon = Icons.wallet_giftcard;
        break;
      case 'GoPay':
        icon = Icons.payment;
        break;
      default:
        icon = Icons.payment;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: logoColorSecondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: logoColorSecondary),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: EdgeInsets.all(Dimenssions.width15),
      child: ElevatedButton(
        onPressed: () {
          final selectedMethod = controller.selectedPaymentMethod.value;
          if (selectedMethod != null) {
            // Tambahkan validasi tambahan jika diperlukan
            Get.back(result: selectedMethod);
          } else {
            // Gunakan GetX snackbar untuk konsistensi
            Get.snackbar(
              'Peringatan',
              'Pilih metode pembayaran terlebih dahulu',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange.shade100,
              colorText: Colors.black,
              icon: const Icon(Icons.warning, color: Colors.orange),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: logoColorSecondary,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Simpan',
          style: primaryTextStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
