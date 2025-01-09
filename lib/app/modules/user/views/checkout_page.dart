// ignore_for_file: deprecated_member_use

import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/data/models/order_item_model.dart';
import 'package:antarkanma/app/modules/user/views/address_selection_page.dart';
import 'package:antarkanma/app/modules/user/views/payment_method_selection_page.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/checkout_controller.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:intl/intl.dart';

class CheckoutPage extends GetView<CheckoutController> {
  final UserLocationController locationController =
      Get.find<UserLocationController>();

  CheckoutPage({super.key});

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
                  ? _buildPaymentMethodCard(selectedMethod)
                  : _buildNoPaymentMethodWidget();
            }),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodSelectionModal() {
    if (controller.isProcessingCheckout.value) return;
    
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.7,
        minHeight: Get.height * 0.4,
        maxWidth: Get.width,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      builder: (context) => const PaymentMethodSelectionPage(),
    ).then((selectedMethod) {
      if (selectedMethod != null) {
        controller.setPaymentMethod(selectedMethod);
      }
    });
  }

  Widget _buildNoPaymentMethodWidget() {
    return InkWell(
      onTap: controller.isProcessingCheckout.value ? null : _showPaymentMethodSelectionModal,
      child: Card(
        color: backgroundColor8,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: logoColorSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment,
                  color: logoColorSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Pilih Metode Pembayaran',
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(String method) {
    return Card(
      color: backgroundColor8,
      child: ListTile(
        leading: Icon(
          _getPaymentMethodIcon(method),
          color: logoColorSecondary,
        ),
        title: Text(method, style: primaryTextStyle),
        trailing: TextButton(
          onPressed: controller.isProcessingCheckout.value ? null : _showPaymentMethodSelectionModal,
          child: Text('Ubah', style: primaryTextStyle),
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'COD':
        return Icons.handshake_outlined;
      case 'Transfer Bank':
        return Icons.account_balance;
      case 'DANA':
        return Icons.account_balance_wallet;
      case 'OVO':
        return Icons.wallet_giftcard;
      case 'GoPay':
        return Icons.payment;
      default:
        return Icons.payment;
    }
  }

  Widget _buildDeliveryAddressSection() {
    return Card(
      color: backgroundColor1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddressHeader(),
            const SizedBox(height: 8),
            GetX<UserLocationController>(
              builder: (locationController) {
                final location = locationController.selectedLocation.value;
                return location != null
                    ? _buildAddressCard(location)
                    : _buildNoAddressWidget();
              },
            ),
          ],
        ),
      ),
    );
  }

  Row _buildAddressHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Alamat Pengiriman', style: primaryTextStyle),
        TextButton(
          onPressed: controller.isProcessingCheckout.value ? null : _showAddressSelectionModal,
          child: Text('Ubah', style: primaryTextStyle),
        ),
      ],
    );
  }

  void _showAddressSelectionModal() {
    if (controller.isProcessingCheckout.value) return;
    
    showModalBottomSheet(
      context: Get.context!,
      builder: (context) => AddressSelectionPage(),
    ).then((result) {
      if (result != null) {
        controller.updateSelectedLocation(result as UserLocationModel);
      }
    });
  }

  Widget _buildAddressCard(UserLocationModel location) {
    return Card(
      elevation: 2,
      color: backgroundColor8,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAddressDetails(location),
            if (location.notes?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Catatan: ${location.notes}',
                  style: primaryTextStyle.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressDetails(UserLocationModel location) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(location.addressLabel,
                style: primaryTextStyle.copyWith(fontWeight: FontWeight.bold)),
            if (location.isDefault)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4)),
                child: Text('Utama',
                    style: primaryTextStyle.copyWith(
                        color: logoColor, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(location.customerName ?? '', style: primaryTextStyle),
        Text(location.formattedPhoneNumber, style: primaryTextStyle),
        const SizedBox(height: 4),
        Text(location.fullAddress, style: primaryTextStyle),
      ],
    );
  }

  Widget _buildNoAddressWidget() {
    return InkWell(
      onTap: controller.isProcessingCheckout.value ? null : () => Get.toNamed('/main/select-address'),
      child: Card(
        color: backgroundColor8,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: logoColorSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_location_alt_outlined,
                  color: logoColorSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Pilih Alamat Pengiriman',
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection() {
    return Obx(() {
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
              if (controller.orderItems.isEmpty)
                Center(
                  child: Text(
                    'Tidak ada pesanan',
                    style: primaryTextStyle.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                ...controller.orderItems
                    .map((item) => _buildOrderItemCard(item)),
            ],
          ),
        ),
      );
    });
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    final hasValidImage =
        imageUrl.isNotEmpty && Uri.tryParse(imageUrl)?.isAbsolute == true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: hasValidImage
          ? Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildPlaceholderImage(),
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

  Widget _buildTotalSection() {
    return Card(
      color: backgroundColor1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTotalRow('Subtotal', controller.subtotal.value),
            _buildTotalRow('Biaya Pengiriman', controller.deliveryFee.value),
            const Divider(),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutButton() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(Dimenssions.radius20),
          topLeft: Radius.circular(Dimenssions.radius20),
        ),
      ),
      color: backgroundColor1,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                Text(
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final bool isProcessing = controller.isProcessingCheckout.value;
              final bool canCheckout = controller.canCheckout;
              
              return Column(
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton(
                      onPressed: isProcessing
                          ? null
                          : canCheckout
                              ? () => controller.processCheckout()
                              : () {
                                  Get.snackbar(
                                    'Checkout Tidak Tersedia',
                                    controller.checkoutBlockReason ??
                                        'Lengkapi data checkout',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.red.withOpacity(0.7),
                                    colorText: Colors.white,
                                  );
                                },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: logoColorSecondary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 54),
                        padding: EdgeInsets.zero,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: (!isProcessing && canCheckout)
                              ? LinearGradient(
                                  colors: [
                                    logoColorSecondary,
                                    logoColorSecondary.withOpacity(0.8),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: isProcessing
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Memproses...',
                                        style: primaryTextStyle.copyWith(
                                          fontSize: Dimenssions.font18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Bayar Sekarang',
                                    style: primaryTextStyle.copyWith(
                                      fontSize: Dimenssions.font18,
                                      fontWeight: FontWeight.bold,
                                      color: canCheckout
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!canCheckout && !isProcessing)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        controller.checkoutBlockReason ?? 'Lengkapi data checkout',
                        style: primaryTextStyle.copyWith(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
