import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/data/models/order_item_model.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/modules/user/views/user_main_page.dart';
import 'package:flutter/foundation.dart';

class CheckoutSuccessPage extends StatelessWidget {
  const CheckoutSuccessPage({Key? key}) : super(key: key);

  Future<void> _navigateToOrderPage() async {
    debugPrint('Navigating to order page...');
    final controller = Get.put(UserMainController(), permanent: true);
    controller.currentIndex.value = 2;
    await Future.delayed(const Duration(milliseconds: 100));
    await Get.offAll(
      () => const UserMainPage(),
      transition: Transition.noTransition,
      duration: const Duration(milliseconds: 0),
    );
    debugPrint('Navigation to order page complete');
  }

  void _navigateToHome() {
    debugPrint('Navigating to home...');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAll(() => const UserMainPage());
    });
  }

  void _showErrorAndNavigate(String message) {
    debugPrint('Showing error and navigating: $message');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showCustomSnackbar(
        title: 'Error',
        message: message,
        isError: true,
      );
      Get.offAll(() => const UserMainPage());
    });
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

  Widget _buildOrderDetail(String label, String value, Color? valueColor) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimenssions.height10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: secondaryTextStyle,
            ),
          ),
          SizedBox(width: Dimenssions.width10),
          Text(
            value,
            style: primaryTextStyle.copyWith(
              color: valueColor,
              fontWeight: medium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
      TransactionModel transaction, UserLocationModel deliveryAddress) {
    String? merchantName;
    try {
      if (transaction.items.isNotEmpty &&
          transaction.items.first.merchant != null) {
        merchantName = transaction.items.first.merchant.name;
      }
    } catch (e) {
      debugPrint('Error getting merchant name: $e');
    }

    return Card(
      color: backgroundColor1,
      child: Padding(
        padding: EdgeInsets.all(Dimenssions.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order ID: ${transaction.orderId}',
                    style: primaryTextStyle.copyWith(
                      fontWeight: semiBold,
                    ),
                  ),
                ),
                SizedBox(width: Dimenssions.width10),
                Text(
                  transaction.statusDisplay,
                  style: primaryTextStyle.copyWith(
                    color: transaction.status.toUpperCase() == 'PENDING'
                        ? priceColor
                        : logoColorSecondary,
                    fontWeight: medium,
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimenssions.height10),
            if (merchantName != null) ...[
              Text(
                'Merchant: $merchantName',
                style: secondaryTextStyle,
              ),
              SizedBox(height: Dimenssions.height10),
            ],
            _buildOrderDetail(
              'Total Pembayaran',
              transaction.formattedGrandTotal,
              logoColorSecondary,
            ),
            // Display product details
            for (var item in transaction.items) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.product.firstImageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: primaryTextStyle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.quantity}x ${item.formattedPrice}',
                                style: primaryTextStyle,
                              ),
                              Text(
                                item.formattedTotalPrice,
                                style: primaryTextStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check arguments before building UI
    if (Get.arguments == null) {
      _showErrorAndNavigate('Data transaksi tidak ditemukan');
      return const SizedBox.shrink();
    }

    final args = Get.arguments as Map<String, dynamic>;
    final List<TransactionModel> allTransactions =
        args['allTransactions'] ?? [];
    final List<OrderItemModel>? orderItems = args['orderItems'];
    final double? total = args['total'];
    final UserLocationModel? deliveryAddress = args['deliveryAddress'];

    if (allTransactions.isEmpty ||
        orderItems == null ||
        total == null ||
        deliveryAddress == null) {
      _showErrorAndNavigate('Data transaksi tidak lengkap');
      return const SizedBox.shrink();
    }

    return WillPopScope(
      onWillPop: () async {
        _navigateToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: backgroundColor8,
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
                          child: _buildTransactionCard(
                              transaction, deliveryAddress),
                        ))
                    .toList(),

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
