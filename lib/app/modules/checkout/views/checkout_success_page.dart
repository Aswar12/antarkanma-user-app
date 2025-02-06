// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/data/models/order_item_model.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/modules/user/views/user_main_page.dart';

class CheckoutSuccessPage extends StatelessWidget {
  const CheckoutSuccessPage({super.key});

  Future<void> _navigateToOrderPage() async {
    debugPrint('Navigating to order page...');
    try {
      // Initialize UserMainController if not already initialized
      final controller = Get.isRegistered<UserMainController>() 
          ? Get.find<UserMainController>() 
          : Get.put(UserMainController(), permanent: true);
          
      // Set the index to Orders tab (2)
      controller.currentIndex.value = 2;
      
      // Navigate to UserMainPage with initial page argument
      await Get.offAll(
        () => const UserMainPage(),
        arguments: {'initialPage': 2},
        transition: Transition.noTransition,
      );
      
      debugPrint('Navigation to order page complete');
    } catch (e) {
      debugPrint('Error navigating to order page: $e');
      _showErrorAndNavigate('Terjadi kesalahan saat navigasi');
    }
  }

  void _navigateToHome() {
    debugPrint('Navigating to home...');
    try {
      // Initialize UserMainController if not already initialized
      if (!Get.isRegistered<UserMainController>()) {
        Get.put(UserMainController(), permanent: true);
      }
      
      Get.offAll(
        () => const UserMainPage(),
        arguments: {'initialPage': 0},
        transition: Transition.noTransition,
      );
    } catch (e) {
      debugPrint('Error navigating to home: $e');
      _showErrorAndNavigate('Terjadi kesalahan saat navigasi');
    }
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

  Widget _buildOrderItems(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Merchant header with status
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor3.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.store,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.merchantName,
                  style: primaryTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: order.orderStatus.toUpperCase() == 'PENDING'
                      ? priceColor.withOpacity(0.1)
                      : logoColorSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getOrderStatusDisplay(order.orderStatus),
                  style: primaryTextStyle.copyWith(
                    color: order.orderStatus.toUpperCase() == 'PENDING'
                        ? priceColor
                        : logoColorSecondary,
                    fontWeight: medium,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: order.orderItems.length,
          separatorBuilder: (context, index) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final item = order.orderItems[index];
            return Row(
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
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.quantity}x ${item.formattedPrice}',
                            style: primaryTextStyle.copyWith(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            item.formattedTotalPrice,
                            style: primaryTextStyle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: logoColorSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: backgroundColor3.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pesanan',
                style: primaryTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rp ${order.totalAmount.toStringAsFixed(0)}',
                style: primaryTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                  color: logoColorSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getOrderStatusDisplay(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Konfirmasi';
      case 'ACCEPTED':
        return 'Diterima';
      case 'PROCESSING':
        return 'Sedang Diproses';
      case 'READY_FOR_PICKUP':
        return 'Siap Diambil';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Widget _buildTransactionCard(
      TransactionModel transaction, UserLocationModel deliveryAddress) {
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: transaction.status.toUpperCase() == 'PENDING'
                        ? priceColor.withOpacity(0.1)
                        : logoColorSecondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    transaction.statusDisplay,
                    style: primaryTextStyle.copyWith(
                      color: transaction.status.toUpperCase() == 'PENDING'
                          ? priceColor
                          : logoColorSecondary,
                      fontWeight: medium,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: Dimenssions.height15),
            // Orders List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transaction.orders.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) => _buildOrderItems(transaction.orders[index]),
            ),
            const SizedBox(height: 16),
            // Display subtotal
            _buildOrderDetail(
              'Subtotal',
              'Rp ${transaction.totalPrice.toStringAsFixed(0)}',
              Colors.grey[700],
            ),
            // Display shipping cost
            _buildOrderDetail(
              'Biaya Pengiriman',
              'Rp ${transaction.shippingPrice.toStringAsFixed(0)}',
              Colors.grey[700],
            ),
            const Divider(),
            // Display total payment (subtotal + shipping)
            _buildOrderDetail(
              'Total Pembayaran',
              'Rp ${(transaction.totalPrice + transaction.shippingPrice).toStringAsFixed(0)}',
              logoColorSecondary,
            ),
          ],
        ),
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

    final List<TransactionModel> allTransactions =
        args['allTransactions'] ?? [];
    final List<OrderItemModel>? orderItems = args['orderItems'];
    final double? subtotal = args['subtotal'];
    final double? shippingFee = args['shippingFee'];
    final double? total = args['total'];
    final UserLocationModel? deliveryAddress = args['deliveryAddress'];

    debugPrint('Transactions count: ${allTransactions.length}');
    debugPrint('Order items count: ${orderItems?.length}');
    debugPrint('Subtotal: $subtotal');
    debugPrint('Shipping Fee: $shippingFee');
    debugPrint('Total: $total');
    debugPrint('Delivery address: ${deliveryAddress?.fullAddress}');

    if (allTransactions.isEmpty ||
        orderItems == null ||
        subtotal == null ||
        shippingFee == null ||
        total == null ||
        deliveryAddress == null) {
      debugPrint('Error: Missing required data');
      debugPrint('Transactions empty: ${allTransactions.isEmpty}');
      debugPrint('Order items null: ${orderItems == null}');
      debugPrint('Subtotal null: ${subtotal == null}');
      debugPrint('Shipping Fee null: ${shippingFee == null}');
      debugPrint('Total null: ${total == null}');
      debugPrint('Delivery address null: ${deliveryAddress == null}');
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
