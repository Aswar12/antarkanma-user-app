import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/widgets/order_card.dart';
import 'package:antarkanma/app/widgets/order_status_badge.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OrderController _orderController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _orderController = Get.put(OrderController());

    // Listen to tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _orderController.onTabChanged(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor3,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(Dimenssions.height70),
        child: AppBar(
          toolbarHeight: Dimenssions.height25,
          title: Text(
            'Pesanan Saya',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font20,
              fontWeight: regular,
            ),
          ),
          centerTitle: true,
          backgroundColor: backgroundColor2,
          foregroundColor: primaryTextColor,
          iconTheme: IconThemeData(
            color: logoColorSecondary,
          ),
          elevation: 0.5,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: GetBuilder<OrderController>(
              builder: (controller) {
                return TabBar(
                  controller: _tabController,
                  onTap: controller.onTabChanged,
                  tabs: const [
                    Tab(text: 'Aktif'),
                    Tab(text: 'Riwayat'),
                  ],
                  labelColor: logoColorSecondary,
                  unselectedLabelColor: secondaryTextColor,
                  indicatorColor: logoColorSecondary,
                );
              },
            ),
          ),
        ),
      ),
      body: GetBuilder<OrderController>(
        builder: (controller) {
          return Obx(() {
            if (controller.isLoading.value) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(logoColorSecondary),
                ),
              );
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return Center(
                child: Text(controller.errorMessage.value),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(controller.activeOrders),
                _buildOrderList(controller.historyOrders),
              ],
            );
          });
        },
      ),
    );
  }

  Widget _buildOrderList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return Center(
        child: Text('Tidak ada pesanan untuk ditampilkan.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _orderController.refreshOrders(),
      color: logoColorSecondary,
      child: ListView.builder(
        padding: EdgeInsets.all(Dimenssions.height15),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return OrderCard(
            transaction: transaction,
            onTap: _showOrderDetails,
          );
        },
      ),
    );
  }

  void _showOrderDetails(TransactionModel transaction) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: backgroundColor1,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Dimenssions.radius20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.symmetric(vertical: Dimenssions.height8),
              width: Dimenssions.width40,
              height: 4,
              decoration: BoxDecoration(
                color: backgroundColor3.withOpacity(0.5),
                borderRadius: BorderRadius.circular(Dimenssions.radius4),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.all(Dimenssions.height15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${transaction.id}',
                            style: primaryTextStyle.copyWith(
                              fontSize: Dimenssions.font16,
                              fontWeight: semiBold,
                            ),
                          ),
                          SizedBox(height: Dimenssions.height4),
                          if (transaction.createdAt != null)
                            Text(
                              DateFormat('dd MMM yyyy HH:mm')
                                  .format(transaction.createdAt!),
                              style: secondaryTextStyle.copyWith(
                                fontSize: Dimenssions.font12,
                              ),
                            ),
                        ],
                      ),
                      OrderStatusBadge(status: transaction.status),
                    ],
                  ),
                  SizedBox(height: Dimenssions.height15),
                  Divider(height: 1, color: backgroundColor3.withOpacity(0.2)),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: Dimenssions.height15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Orders List
                      Text(
                        'Daftar Pesanan',
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font14,
                          fontWeight: semiBold,
                        ),
                      ),
                      SizedBox(height: Dimenssions.height8),
                      ...transaction.orders
                          .map((order) => _buildOrderDetails(order)),
                      SizedBox(height: Dimenssions.height15),
                      Divider(
                          height: 1, color: backgroundColor3.withOpacity(0.2)),
                      SizedBox(height: Dimenssions.height15),

                      // Shipping Address
                      if (transaction.userLocation != null) ...[
                        Text(
                          'Alamat Pengiriman',
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font14,
                            fontWeight: semiBold,
                          ),
                        ),
                        SizedBox(height: Dimenssions.height8),
                        Container(
                          padding: EdgeInsets.all(Dimenssions.height12),
                          decoration: BoxDecoration(
                            color: backgroundColor3.withOpacity(0.05),
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                transaction.userLocation!.address,
                                style: primaryTextStyle.copyWith(
                                  fontSize: Dimenssions.font12,
                                ),
                              ),
                              SizedBox(height: Dimenssions.height4),
                              Text(
                                '${transaction.userLocation!.city}, ${transaction.userLocation!.postalCode}',
                                style: secondaryTextStyle.copyWith(
                                  fontSize: Dimenssions.font12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: Dimenssions.height15),
                        Divider(
                            height: 1,
                            color: backgroundColor3.withOpacity(0.2)),
                        SizedBox(height: Dimenssions.height15),
                      ],

                      // Payment Details
                      Text(
                        'Rincian Pembayaran',
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font14,
                          fontWeight: semiBold,
                        ),
                      ),
                      SizedBox(height: Dimenssions.height8),
                      Container(
                        padding: EdgeInsets.all(Dimenssions.height12),
                        decoration: BoxDecoration(
                          color: backgroundColor3.withOpacity(0.05),
                          borderRadius:
                              BorderRadius.circular(Dimenssions.radius8),
                        ),
                        child: Column(
                          children: [
                            _buildPaymentRow(
                              'Subtotal Produk',
                              transaction.formattedTotalPrice,
                            ),
                            SizedBox(height: Dimenssions.height8),
                            _buildPaymentRow(
                              'Biaya Pengiriman',
                              transaction.formattedShippingPrice,
                            ),
                            SizedBox(height: Dimenssions.height8),
                            Divider(
                                height: 1,
                                color: backgroundColor3.withOpacity(0.2)),
                            SizedBox(height: Dimenssions.height8),
                            _buildPaymentRow(
                              'Total Pembayaran',
                              transaction.formattedGrandTotal,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: Dimenssions.height20),
                    ],
                  ),
                ),
              ),
            ),
            // Cancel Button at Bottom
            if (transaction.status.toUpperCase() == 'PENDING') ...[
              Padding(
                padding: EdgeInsets.all(Dimenssions.height15),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => _showCancelDialog(transaction),
                    style: TextButton.styleFrom(
                      backgroundColor: alertColor.withOpacity(0.1),
                      padding: EdgeInsets.symmetric(
                        vertical: Dimenssions.height12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimenssions.radius8),
                        side: BorderSide(color: alertColor),
                      ),
                    ),
                    child: Text(
                      'Batalkan Pesanan',
                      style: primaryTextStyle.copyWith(
                        color: alertColor,
                        fontSize: Dimenssions.font14,
                        fontWeight: medium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildOrderDetails(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Merchant: ${order.merchantName}',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font14,
                fontWeight: medium,
              ),
            ),
            OrderStatusBadge(status: order.orderStatus),
          ],
        ),
        SizedBox(height: Dimenssions.height8),
        ...order.orderItems.map((item) => _buildDetailProductItem(item)),
        SizedBox(height: Dimenssions.height12),
        Divider(
          height: 1,
          color: backgroundColor3.withOpacity(0.2),
        ),
        SizedBox(height: Dimenssions.height12),
      ],
    );
  }

  void _showCancelDialog(TransactionModel transaction) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
        ),
        backgroundColor: backgroundColor1,
        child: Padding(
          padding: EdgeInsets.all(Dimenssions.height20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Konfirmasi Pembatalan',
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font18,
                  fontWeight: semiBold,
                ),
              ),
              SizedBox(height: Dimenssions.height15),
              Text(
                'Apakah Anda yakin ingin membatalkan pesanan ini?',
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font14,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: Dimenssions.height20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Tidak',
                      style: primaryTextStyle.copyWith(
                        color: logoColorSecondary,
                        fontSize: Dimenssions.font14,
                      ),
                    ),
                  ),
                  SizedBox(width: Dimenssions.width10),
                  TextButton(
                    onPressed: () async {
                      Get.back(); // Close confirmation dialog
                      Get.back(); // Close order details
                      await _orderController
                          .cancelOrder(transaction.id.toString());
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: alertColor,
                    ),
                    child: Text(
                      'Ya, Batalkan',
                      style: primaryTextStyle.copyWith(
                        color: Colors.white,
                        fontSize: Dimenssions.font14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailProductItem(dynamic item) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: Dimenssions.height8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: Dimenssions.height65,
            height: Dimenssions.height65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimenssions.radius8),
              border: Border.all(
                color: backgroundColor3.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimenssions.radius8),
              child: Image.network(
                item.product.firstImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: backgroundColor3.withOpacity(0.1),
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: secondaryTextColor,
                    size: Dimenssions.font20,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: Dimenssions.width12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font14,
                    fontWeight: medium,
                  ),
                ),
                SizedBox(height: Dimenssions.height4),
                Row(
                  children: [
                    Icon(
                      Icons.store_outlined,
                      size: Dimenssions.font14,
                      color: secondaryTextColor,
                    ),
                    SizedBox(width: Dimenssions.width4),
                    Text(
                      item.merchant.name,
                      style: secondaryTextStyle.copyWith(
                        fontSize: Dimenssions.font12,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Dimenssions.height8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.quantity}x ${item.formattedPrice}',
                      style: secondaryTextStyle.copyWith(
                        fontSize: Dimenssions.font12,
                      ),
                    ),
                    Text(
                      item.formattedTotalPrice,
                      style: priceTextStyle.copyWith(
                        fontSize: Dimenssions.font14,
                        fontWeight: semiBold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font14,
                  fontWeight: semiBold,
                )
              : secondaryTextStyle.copyWith(
                  fontSize: Dimenssions.font12,
                ),
        ),
        Text(
          value,
          style: isTotal
              ? priceTextStyle.copyWith(
                  fontSize: Dimenssions.font16,
                  fontWeight: semiBold,
                )
              : priceTextStyle.copyWith(
                  fontSize: Dimenssions.font14,
                ),
        ),
      ],
    );
  }
}
