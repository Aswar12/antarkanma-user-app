import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/modules/checkout/controllers/payment_qris_controller.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/config.dart';

class PaymentQrisPage extends GetView<PaymentQrisController> {
  const PaymentQrisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor1,
      appBar: AppBar(
        backgroundColor: backgroundColor1,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryTextColor),
        title: Text(
          'Pembayaran QRIS',
          style: primaryTextStyle.copyWith(
            fontSize: 18,
            fontWeight: semiBold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Dimenssions.width20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInstructionCard(),
              SizedBox(height: Dimenssions.height20),
              _buildQrisCard(
                title: 'Pembayaran Pesanan',
                amount: controller.transaction.merchantAmount ?? 0,
                qrisUrl: controller.transaction.merchantQrisUrl,
                isPaid: controller.isMerchantPaid,
                isUploading: controller.isUploadingMerchant,
                proofPath: controller.merchantProofPath,
                onUpload: controller.pickMerchantProof,
              ),
              SizedBox(height: Dimenssions.height20),
              _buildQrisCard(
                title: 'Pembayaran Ongkir & Jasa',
                amount: controller.transaction.platformAmount ?? 0,
                qrisUrl: controller.transaction.platformQrisUrl,
                isPaid: controller.isPlatformPaid,
                isUploading: controller.isUploadingPlatform,
                proofPath: controller.platformProofPath,
                onUpload: controller.pickPlatformProof,
              ),
              SizedBox(height: Dimenssions.height30),
              _buildDoneButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: EdgeInsets.all(Dimenssions.width15),
      decoration: BoxDecoration(
        color: backgroundColor2,
        borderRadius: BorderRadius.circular(Dimenssions.radius12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: logoColorSecondary),
              SizedBox(width: Dimenssions.width10),
              Text(
                'Instruksi Pembayaran',
                style: primaryTextStyle.copyWith(
                  fontWeight: semiBold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: Dimenssions.height10),
          Text(
            '1. Simpan barcode QRIS ke galeri atau scan langsung menggunakan aplikasi pembayaran Anda (GoPay, OVO, Dana, M-Banking, dll).',
            style: secondaryTextStyle.copyWith(fontSize: 14),
          ),
          SizedBox(height: Dimenssions.height5),
          Text(
            '2. Lakukan 2 kali pembayaran: untuk Pesanan (ke Merchant) dan untuk Ongkir (ke Platform).',
            style: secondaryTextStyle.copyWith(fontSize: 14),
          ),
          SizedBox(height: Dimenssions.height5),
          Text(
            '3. Upload bukti pembayaran (screenshot) pada masing-masing bagian di bawah ini.',
            style: secondaryTextStyle.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisCard({
    required String title,
    required double amount,
    required String? qrisUrl,
    required RxBool isPaid,
    required RxBool isUploading,
    required RxString proofPath,
    required VoidCallback onUpload,
  }) {
    return Container(
      padding: EdgeInsets.all(Dimenssions.width15),
      decoration: BoxDecoration(
        color: backgroundColor2,
        borderRadius: BorderRadius.circular(Dimenssions.radius12),
        border: Border.all(color: logoColorSecondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: primaryTextStyle.copyWith(
              fontWeight: semiBold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: Dimenssions.height10),
          Text(
            'Jumlah Tagihan:',
            style: secondaryTextStyle,
          ),
          Text(
            'Rp ${amount.toStringAsFixed(0)}',
            style: priceTextStyle.copyWith(
              fontWeight: bold,
              fontSize: 20,
            ),
          ),
          SizedBox(height: Dimenssions.height20),
          if (qrisUrl != null && qrisUrl.isNotEmpty)
            Image.network(
              qrisUrl.startsWith('http') ? qrisUrl : '${Config.baseUrl}$qrisUrl',
              height: 200,
              width: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                width: 200,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.error)),
              ),
            )
          else
            Container(
              height: 200,
              width: 200,
              color: Colors.grey[200],
              child: const Center(child: Text('QRIS belum tersedia')),
            ),
          SizedBox(height: Dimenssions.height20),
          Obx(() {
            if (isPaid.value) {
              return Container(
                padding: EdgeInsets.symmetric(
                  vertical: Dimenssions.height10,
                  horizontal: Dimenssions.width20,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimenssions.radius8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: Dimenssions.width10),
                    Text(
                      'Bukti Diunggah',
                      style: primaryTextStyle.copyWith(
                        color: Colors.green,
                        fontWeight: semiBold,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                onPressed: isUploading.value ? null : onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: logoColorSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimenssions.radius8),
                  ),
                ),
                child: isUploading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Upload Bukti Pembayaran',
                        style: primaryTextStyle.copyWith(
                          color: Colors.white,
                          fontWeight: semiBold,
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => controller.completePayment(),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimenssions.radius12),
          ),
        ),
        child: Text(
          'Selesai',
          style: primaryTextStyle.copyWith(
            fontSize: 16,
            fontWeight: semiBold,
            color: backgroundColor1,
          ),
        ),
      ),
    );
  }
}
