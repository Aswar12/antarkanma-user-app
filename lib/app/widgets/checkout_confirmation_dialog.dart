import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';
import 'package:intl/intl.dart';
import 'package:antarkanma/app/controllers/checkout_controller.dart';

class CheckoutConfirmationDialog extends StatelessWidget {
  final CheckoutController controller;

  const CheckoutConfirmationDialog({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.65;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 50,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: logoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: 24,
                        color: logoColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konfirmasi Pesanan',
                            style: primaryTextStyle.copyWith(
                              fontSize: 18,
                              fontWeight: semiBold,
                              color: logoColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Periksa kembali detail dan alamat tujuan ini',
                            style: primaryTextStyle.copyWith(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                    icon: Icons.location_on,
                    title: 'Alamat Pengiriman',
                    content: controller.selectedLocation.value?.fullAddress ??
                        'Belum dipilih',
                  ),
                  const SizedBox(height: 14),
                  _buildInfoSection(
                    icon: Icons.payment,
                    title: 'Metode Pembayaran',
                    content: controller.selectedPaymentMethod.value ??
                        'Belum dipilih',
                  ),
                  const SizedBox(height: 14),
                  _buildInfoSection(
                    icon: Icons.monetization_on,
                    title: 'Total Pembayaran',
                    content: NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(controller.total.value),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ),
          // Buttons
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 14, 20, 16 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: backgroundColor1,
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: logoColor.withOpacity(0.5),
                          ),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        'Periksa Kembali',
                        style: primaryTextStyle.copyWith(
                          fontSize: 14,
                          color: logoColor,
                          fontWeight: medium,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: logoColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                        controller.processCheckout();
                      },
                      child: Text(
                        'Konfirmasi',
                        style: primaryTextStyle.copyWith(
                          fontSize: 14,
                          color: backgroundColor3,
                          fontWeight: semiBold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    bool isTotal = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: logoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: logoColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: primaryTextStyle.copyWith(
                  fontWeight: semiBold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: primaryTextStyle.copyWith(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? semiBold : regular,
              color: isTotal ? logoColor : null,
            ),
          ),
        ],
      ),
    );
  }
}
