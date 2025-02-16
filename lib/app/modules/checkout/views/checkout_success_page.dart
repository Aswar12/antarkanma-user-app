import 'package:antarkanma/app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/bindings/main_binding.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/modules/checkout/widgets/transaction_card_widget.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/app/routes/app_pages.dart';

class CheckoutSuccessPage extends StatelessWidget {
  const CheckoutSuccessPage({super.key});

  Future<void> _navigateToOrderPage() async {
    debugPrint('Navigating to order page...');
    try {
      // Ensure AuthService is initialized
      await Get.find<AuthService>().ensureInitialized();

      // Navigate directly to userMainPage
      await Get.offAllNamed(
        Routes.userMainPage,
        arguments: {'initialPage': 2},
      );

      // Update the tab index after navigation
      final controller = Get.find<UserMainController>();
      controller.currentIndex.value = 2;

      debugPrint('Navigation to order page complete');
    } catch (e) {
      debugPrint('Error navigating to order page: $e');
      _showErrorAndNavigate('Terjadi kesalahan saat navigasi');
    }
  }

  Future<void> _navigateToHome() async {
    debugPrint('Navigating to home...');
    try {
      // Ensure AuthService is initialized
      await Get.find<AuthService>().ensureInitialized();

      // Navigate directly to userMainPage
      await Get.offAllNamed(
        Routes.userMainPage,
        arguments: {'initialPage': 0},
      );
    } catch (e) {
      debugPrint('Error navigating to home: $e');
      _showErrorAndNavigate('Terjadi kesalahan saat navigasi');
    }
  }

  void _showErrorAndNavigate(String message) {
    debugPrint('Showing error and navigating: $message');
    showCustomSnackbar(
      title: 'Error',
      message: message,
      isError: true,
    );

    // Navigate directly to userMainPage
    Get.offAllNamed(
      Routes.userMainPage,
      arguments: {'initialPage': 0},
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimenssions.height10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: Dimenssions.height24,
            height: Dimenssions.height24,
            decoration: BoxDecoration(
              color: logoColorSecondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(Dimenssions.radius12),
            ),
            child: Center(
              child: Text(
                number,
                style: primaryTextStyle.copyWith(
                  color: logoColorSecondary,
                  fontWeight: semiBold,
                ),
              ),
            ),
          ),
          SizedBox(width: Dimenssions.width10),
          Expanded(
            child: Text(
              text,
              style: primaryTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('\n=== CheckoutSuccessPage Build ===');
    debugPrint('Arguments: ${Get.arguments}');

    // Check arguments before building UI
    if (Get.arguments == null) {
      debugPrint('Error: Arguments are null');
      _showErrorAndNavigate('Data transaksi tidak ditemukan');
      return const SizedBox.shrink();
    }

    final args = Get.arguments as Map<String, dynamic>;
    debugPrint('Arguments content: $args');

    final List<TransactionModel> allTransactions = args['allTransactions'] ?? [];
    final orderItems = args['orderItems'];
    final subtotal = args['subtotal'];
    final shippingFee = args['shippingFee'];
    final total = args['total'];
    final UserLocationModel? deliveryAddress = args['deliveryAddress'];

    if (allTransactions.isEmpty ||
        orderItems == null ||
        subtotal == null ||
        shippingFee == null ||
        total == null ||
        deliveryAddress == null) {
      debugPrint('Error: Missing required data');
      _showErrorAndNavigate('Data transaksi tidak lengkap');
      return const SizedBox.shrink();
    }

    return WillPopScope(
      onWillPop: () async {
        _navigateToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: backgroundColor1,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(Dimenssions.width20),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: logoColorSecondary,
                  size: Dimenssions.height80,
                ),
                SizedBox(height: Dimenssions.height20),
                Text(
                  'Pesanan Berhasil!',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font24,
                    fontWeight: semiBold,
                  ),
                ),
                SizedBox(height: Dimenssions.height10),
                Text(
                  '${allTransactions.length} Transaksi Dibuat',
                  style: secondaryTextStyle.copyWith(
                    fontSize: Dimenssions.font16,
                  ),
                ),
                SizedBox(height: Dimenssions.height30),

                // Important Notice about Order Cancellation
                Card(
                  color: backgroundColor1,
                  child: Padding(
                    padding: EdgeInsets.all(Dimenssions.width16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: alertColor,
                              size: Dimenssions.height24,
                            ),
                            SizedBox(width: Dimenssions.width10),
                            Text(
                              'Penting!',
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font18,
                                fontWeight: semiBold,
                                color: alertColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Dimenssions.height15),
                        Text(
                          'Pesanan tidak dapat dibatalkan setelah status berubah menjadi "Sedang Diproses". Harap perhatikan status pesanan Anda.',
                          style: primaryTextStyle,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Dimenssions.height20),

                // Payment Instructions (if COD)
                if (allTransactions.first.paymentMethod.toUpperCase() ==
                    'MANUAL')
                  Card(
                    color: backgroundColor1,
                    child: Padding(
                      padding: EdgeInsets.all(Dimenssions.width16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: logoColorSecondary,
                                size: Dimenssions.height24,
                              ),
                              SizedBox(width: Dimenssions.width10),
                              Text(
                                'Instruksi Pembayaran COD',
                                style: primaryTextStyle.copyWith(
                                  fontSize: Dimenssions.font18,
                                  fontWeight: semiBold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: Dimenssions.height15),
                          _buildInstructionItem(
                            '1',
                            'Siapkan uang tunai untuk setiap transaksi',
                          ),
                          _buildInstructionItem(
                            '2',
                            'Kurir akan menghubungi Anda saat pesanan tiba',
                          ),
                          _buildInstructionItem(
                            '3',
                            'Lakukan pembayaran tunai kepada kurir saat menerima pesanan',
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: Dimenssions.height20),

                // Transactions List
                ...allTransactions
                    .map((transaction) => Padding(
                          padding:
                              EdgeInsets.only(bottom: Dimenssions.height10),
                          child: TransactionCardWidget(
                            transaction: transaction,
                            deliveryAddress: deliveryAddress,
                          ),
                        ))
                    ,

                SizedBox(height: Dimenssions.height20),

                // Delivery Address
                Card(
                  color: backgroundColor1,
                  child: Padding(
                    padding: EdgeInsets.all(Dimenssions.width16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alamat Pengiriman',
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font18,
                            fontWeight: semiBold,
                          ),
                        ),
                        SizedBox(height: Dimenssions.height15),
                        Text(
                          deliveryAddress.customerName ?? '',
                          style: primaryTextStyle.copyWith(
                            fontWeight: medium,
                          ),
                        ),
                        SizedBox(height: Dimenssions.height5),
                        Text(
                          deliveryAddress.formattedPhoneNumber,
                          style: primaryTextStyle,
                        ),
                        SizedBox(height: Dimenssions.height5),
                        Text(
                          deliveryAddress.fullAddress,
                          style: primaryTextStyle,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Dimenssions.height30),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _navigateToOrderPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: backgroundColor1,
                          foregroundColor: logoColorSecondary,
                          padding: EdgeInsets.symmetric(
                            vertical: Dimenssions.height15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius8),
                            side: BorderSide(color: logoColorSecondary),
                          ),
                        ),
                        child: Text(
                          'Lihat Pesanan',
                          style: primaryTextStyle.copyWith(
                            color: logoColorSecondary,
                            fontWeight: medium,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Dimenssions.width15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _navigateToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: logoColorSecondary,
                          padding: EdgeInsets.symmetric(
                            vertical: Dimenssions.height15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius8),
                          ),
                        ),
                        child: Text(
                          'Kembali ke Beranda',
                          style: primaryTextStyle.copyWith(
                            color: backgroundColor1,
                            fontWeight: medium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
