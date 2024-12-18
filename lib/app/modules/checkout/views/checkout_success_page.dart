import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/data/models/order_item_model.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/app/routes/app_pages.dart';

class CheckoutSuccessPage extends StatelessWidget {
  const CheckoutSuccessPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      if (Get.arguments == null) {
        Get.snackbar(
          'Error',
          'Data transaksi tidak ditemukan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.offAllNamed(Routes.main);
        return const SizedBox.shrink();
      }

      final args = Get.arguments as Map<String, dynamic>;
      final TransactionModel? transaction = args['transaction'];
      final List<OrderItemModel>? orderItems = args['orderItems'];
      final double? total = args['total'];
      final UserLocationModel? deliveryAddress = args['deliveryAddress'];

      if (transaction == null ||
          orderItems == null ||
          total == null ||
          deliveryAddress == null) {
        Get.snackbar(
          'Error',
          'Data transaksi tidak lengkap',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.offAllNamed(Routes.main);
        return const SizedBox.shrink();
      }

      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 80,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Checkout Berhasil!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Order ID: ${transaction.orderId}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ringkasan Pesanan:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                              'Total Pembayaran: ${transaction.formattedGrandTotal}'),
                          Text('Status: ${transaction.statusDisplay}'),
                          Text(
                              'Metode Pembayaran: ${transaction.paymentMethod}'),
                          const SizedBox(height: 10),
                          const Text(
                            'Alamat Pengiriman:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(deliveryAddress.address),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Get.offAllNamed(Routes.main),
                  child: const Text('Kembali ke Beranda'),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Get.offAllNamed(Routes.main);
      return const SizedBox.shrink();
    }
  }
}
