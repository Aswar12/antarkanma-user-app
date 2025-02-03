// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/data/models/order_item_model.dart';
import 'package:antarkanma/app/modules/user/views/address_selection_page.dart';
import 'package:antarkanma/app/modules/user/views/payment_method_selection_page.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/controllers/checkout_controller.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:intl/intl.dart';

class CheckoutPage extends GetView<CheckoutController> {
  final UserLocationController locationController = Get.find<UserLocationController>();

  CheckoutPage({super.key}) {
    // Initialize the controller when the page is created
    controller.autoSetInitialValues();
  }

  Widget _buildOrderItemCard(OrderItemModel item) {
    return Card(
      color: backgroundColor8,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: primaryTextStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: Dimenssions.font16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Merchant: ${item.merchantName}',
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font14,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        '${item.quantity}x ${item.formattedPrice}',
                        style: primaryTextStyle.copyWith(
                          color: logoColor,
                          fontSize: Dimenssions.font16,
                        ),
                      ),
                      Text(
                        item.formattedTotalPrice,
                        style: primaryTextStyle.copyWith(
                          color: logoColor,
                          fontSize: Dimenssions.font18,
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
    );
  }

  Widget _buildProductImage(OrderItemModel item) {
    final imageUrl = item.product.firstImageUrl;
    final hasValidImage = imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: hasValidImage
          ? Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildLoadingImage();
              },
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey[600],
          size: 40,
        ),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(logoColorSecondary),
        ),
      ),
    );
  }

  Widget _buildDeliveryAddressSection() {
    return Card(
      color: backgroundColor1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Alamat Pengiriman', style: primaryTextStyle),
                TextButton(
                  onPressed: controller.isProcessingCheckout.value
                      ? null
                      : () => Get.to(() => AddressSelectionPage()),
                  child: Text('Ubah', style: primaryTextStyle),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              final location = locationController.selectedLocation.value;
              return location != null
                  ? _buildAddressCard(location)
                  : _buildNoAddressWidget();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(UserLocationModel location) {
    return Card(
      color: backgroundColor8,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  location.addressLabel,
                  style: primaryTextStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                if (location.isDefault)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Utama',
                      style: primaryTextStyle.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(location.customerName ?? '', style: primaryTextStyle),
            Text(location.formattedPhoneNumber, style: primaryTextStyle),
            const SizedBox(height: 4),
            Text(location.fullAddress, style: primaryTextStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAddressWidget() {
    return Card(
      color: backgroundColor8,
      child: InkWell(
        onTap: controller.isProcessingCheckout.value
            ? null
            : () => Get.to(() => AddressSelectionPage()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_location_alt, color: logoColorSecondary),
              const SizedBox(width: 8),
              Text(
                'Pilih Alamat Pengiriman',
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Card(
      color: backgroundColor1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan',
              style: primaryTextStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.orderItems.isEmpty) {
                return Center(
                  child: Text(
                    'Tidak ada pesanan',
                    style: primaryTextStyle.copyWith(color: Colors.grey),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.orderItems.length,
                itemBuilder: (context, index) {
                  return _buildOrderItemCard(controller.orderItems[index]);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Card(
      color: backgroundColor1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Metode Pembayaran',
              style: primaryTextStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final selectedMethod = controller.selectedPaymentMethod.value;
              return selectedMethod != null
                  ? _buildSelectedPaymentMethod(selectedMethod)
                  : _buildNoPaymentMethodWidget();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPaymentMethod(String method) {
    return Card(
      color: backgroundColor8,
      child: ListTile(
        leading: Icon(_getPaymentIcon(method), color: logoColorSecondary),
        title: Text(method, style: primaryTextStyle),
        trailing: TextButton(
          onPressed: controller.isProcessingCheckout.value
              ? null
              : () => Get.to(() => PaymentMethodSelectionPage()),
          child: Text('Ubah', style: primaryTextStyle),
        ),
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'COD':
        return Icons.payments;
      case 'Transfer Bank':
        return Icons.account_balance;
      case 'E-Wallet':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  Widget _buildNoPaymentMethodWidget() {
    return Card(
      color: backgroundColor8,
      child: InkWell(
        onTap: controller.isProcessingCheckout.value
            ? null
            : () => Get.to(() => PaymentMethodSelectionPage()),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment, color: logoColorSecondary),
              const SizedBox(width: 8),
              Text(
                'Pilih Metode Pembayaran',
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Card(
      color: backgroundColor1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTotalRow('Subtotal', controller.subtotal.value),
            _buildTotalRow('Biaya Pengiriman', controller.deliveryFee.value),
            const Divider(height: 16),
            _buildTotalRow('Total', controller.total.value, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: primaryTextStyle.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(amount),
            style: primaryTextStyle.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? logoColorSecondary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Obx(() => Text(
                    NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(controller.total.value),
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font18,
                      fontWeight: FontWeight.bold,
                      color: logoColorSecondary,
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Obx(() => ElevatedButton(
                  onPressed: controller.isProcessingCheckout.value || !controller.canCheckout
                      ? null
                      : () => controller.processCheckout(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: logoColorSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: controller.isProcessingCheckout.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Pesan Sekarang',
                          style: primaryTextStyle.copyWith(
                            color: Colors.white,
                            fontSize: Dimenssions.font16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (controller.isProcessingCheckout.value) {
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: backgroundColor8,
        appBar: AppBar(
          toolbarHeight: Dimenssions.height50,
          backgroundColor: backgroundColor8,
          iconTheme: IconThemeData(color: logoColorSecondary),
          title: Text('Checkout', style: primaryTextStyle),
          leading: controller.isProcessingCheckout.value
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Get.back(),
                ),
        ),
        body: GetX<CheckoutController>(
          builder: (controller) {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: EdgeInsets.all(Dimenssions.width10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeliveryAddressSection(),
                  const SizedBox(height: 16),
                  _buildOrderItemsSection(),
                  const SizedBox(height: 16),
                  _buildPaymentSection(),
                  const SizedBox(height: 16),
                  _buildTotalSection(),
                ],
              ),
            );
          },
        ),
        bottomNavigationBar: _buildCheckoutButton(),
      ),
    );
  }
}
