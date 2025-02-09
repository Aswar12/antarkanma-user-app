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
import 'package:antarkanma/app/modules/checkout/widgets/shipping_details_section_widget.dart';
import 'package:intl/intl.dart';
import 'package:antarkanma/app/widgets/shipping_preview_skeleton_loading.dart';

class CheckoutPage extends GetView<CheckoutController> {
  const CheckoutPage({super.key});

  UserLocationController get locationController => Get.find<UserLocationController>();

  void _initializeCheckout(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final controller = Get.find<CheckoutController>();
        controller.autoSetInitialValues();
      } catch (e) {
        debugPrint('Error initializing checkout: $e');
      }
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

  Widget _buildDeliveryAddressSection() {
    return GetBuilder<UserLocationController>(
      init: Get.find<UserLocationController>(),
      initState: (_) => _initializeCheckout(Get.context!),
      builder: (locationCtrl) => Card(
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
                final selectedLocation = locationCtrl.selectedLocation;
                if (selectedLocation == null) return _buildNoAddressWidget();
                final location = selectedLocation.value;
                return location != null
                    ? _buildAddressCard(location)
                    : _buildNoAddressWidget();
              }),
            ],
          ),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              final merchantItems = controller.merchantItems.value;
              
              if (merchantItems.isEmpty) {
                return Center(
                  child: Text(
                    'Tidak ada pesanan',
                    style: primaryTextStyle.copyWith(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: merchantItems.entries.map((entry) {
                  final items = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          items.first.merchantName,
                          style: primaryTextStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: Dimenssions.font16,
                          ),
                        ),
                      ),
                      ...items.map((item) => _buildOrderItemCard(item)),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
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
            child: Obx(() {
              final shippingDetails = controller.shippingDetails.value;
              final shouldSplit = shippingDetails?.recommendations.shouldSplit ?? false;

              if (shouldSplit) {
                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange[50]!,
                            Colors.orange[100]!.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.route_rounded,
                                  color: Colors.orange[700],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rute Pengiriman Tidak Optimal',
                                      style: primaryTextStyle.copyWith(
                                        color: Colors.orange[900],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Beberapa merchant berada di arah yang berbeda. Anda dapat memisahkan pesanan untuk pengiriman yang lebih efisien.',
                                      style: primaryTextStyle.copyWith(
                                        color: Colors.orange[800],
                                        fontSize: 14,
                                        height: 1.4,
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
                    Container(
                      width: double.infinity,
                      height: 50,
                      margin: const EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: logoColorSecondary,
                          elevation: 2,
                          shadowColor: Colors.grey.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: logoColorSecondary.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 20,
                              color: logoColorSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kembali ke Keranjang',
                              style: primaryTextStyle.copyWith(
                                color: logoColorSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Container(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isProcessingCheckout.value ||
                          !controller.canCheckout
                      ? null
                      : () => controller.processCheckout(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: logoColorSecondary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: logoColorSecondary.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isProcessingCheckout.value
                      ? SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pesan Sekarang',
                              style: primaryTextStyle.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                ),
              );
            }),
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
        Get.back();
        return false;
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
                  Obx(() {
                    final shippingDetails = controller.shippingDetails.value;
                    if (shippingDetails != null) {
                      return ShippingDetailsSectionWidget(
                        shippingDetails: shippingDetails,
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                  const SizedBox(height: 16),
                  // Add the shipping preview skeleton loading here
                  if (controller.isLoading.value) const ShippingPreviewSkeletonLoading(),
                  const SizedBox(height: 16),
                  _buildOrderItemsSection(),
                  const SizedBox(height: 16),
                  _buildPaymentSection(),
                  const SizedBox(height: 16),
                  _buildTotalSection(),
                  const SizedBox(height: 80),
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
