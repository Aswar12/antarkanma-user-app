import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/widgets/order_card.dart';
import 'package:antarkanma/app/widgets/order_status_badge.dart';
import 'package:antarkanma/app/widgets/order_status_timeline.dart';
import 'package:antarkanma/app/modules/user/views/review_page.dart';

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
        preferredSize: Size.fromHeight(Dimenssions.height95),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [navyColor, navyColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(Dimenssions.radius30),
              bottomRight: Radius.circular(Dimenssions.radius30),
            ),
            boxShadow: [
              BoxShadow(
                color: primaryOrange.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header Title & Tab Bar
                Padding(
                  padding: EdgeInsets.only(
                    left: Dimenssions.width20,
                    right: Dimenssions.width20,
                    top: Dimenssions.height20,
                    bottom: Dimenssions.height12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with icon
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(Dimenssions.height8),
                            decoration: BoxDecoration(
                              color: primaryOrange.withOpacity(0.2),
                              borderRadius:
                                  BorderRadius.circular(Dimenssions.radius12),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: primaryOrange,
                              size: Dimenssions.height20,
                            ),
                          ),
                          SizedBox(width: Dimenssions.width12),
                          Text(
                            'Pesanan Saya',
                            style: primaryTextStyle.copyWith(
                              fontSize: Dimenssions.font22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Dimenssions.height16),
                      // Modern Segmented Tab Bar
                      GetBuilder<OrderController>(
                        builder: (controller) {
                          return ClipRRect(
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius16),
                            child: Container(
                              height: Dimenssions.height50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius:
                                    BorderRadius.circular(Dimenssions.radius16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Animated Background Indicator
                                  AnimatedPositioned(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    left: controller.selectedTabIndex == 0
                                        ? Dimenssions.width4
                                        : null,
                                    right: controller.selectedTabIndex == 1
                                        ? Dimenssions.width4
                                        : null,
                                    top: Dimenssions.height4,
                                    bottom: Dimenssions.height4,
                                    child: AnimatedContainer(
                                      duration: Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                      width:
                                          (MediaQuery.of(context).size.width /
                                                  2) -
                                              Dimenssions.width8,
                                      decoration: BoxDecoration(
                                        color: primaryOrange,
                                        borderRadius: BorderRadius.circular(
                                            Dimenssions.radius12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                primaryOrange.withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Tab Buttons
                                  Row(
                                    children: [
                                      // Aktif Tab
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            _tabController.animateTo(0);
                                          },
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.inventory_2_rounded,
                                                  color: controller
                                                              .selectedTabIndex ==
                                                          0
                                                      ? Colors.white
                                                      : Colors.white
                                                          .withOpacity(0.7),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Aktif',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: controller
                                                                .selectedTabIndex ==
                                                            0
                                                        ? Colors.white
                                                        : Colors.white
                                                            .withOpacity(0.7),
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Riwayat Tab
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            _tabController.animateTo(1);
                                          },
                                          child: Center(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.history_rounded,
                                                  color: controller
                                                              .selectedTabIndex ==
                                                          1
                                                      ? Colors.white
                                                      : Colors.white
                                                          .withOpacity(0.7),
                                                  size: 18,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Riwayat',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: controller
                                                                .selectedTabIndex ==
                                                            1
                                                        ? Colors.white
                                                        : Colors.white
                                                            .withOpacity(0.7),
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
            // Handle bar - Drag indicator
            Container(
              margin: EdgeInsets.symmetric(vertical: Dimenssions.height12),
              width: Dimenssions.width50,
              height: 5,
              decoration: BoxDecoration(
                color: backgroundColor3.withOpacity(0.6),
                borderRadius: BorderRadius.circular(Dimenssions.radius15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
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
                            '#ANTAR-${transaction.id}',
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
                      OrderStatusTimeline(transaction: transaction),
                      SizedBox(height: Dimenssions.height15),

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
            // Bottom Action Buttons (Cancel & Chat Driver)
            Padding(
              padding: EdgeInsets.all(Dimenssions.height15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Chat and Cancel Buttons (Horizontal Row)
                  if (['PENDING', 'ACCEPTED', 'ON_DELIVERY', 'PICKED_UP']
                      .contains(transaction.status.toUpperCase()))
                    Row(
                      children: [
                        // Chat with Courier Button (primary action)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: transaction.canChatWithCourier
                                ? () {
                                    Get.back(); // Close bottom sheet
                                    Get.toNamed(Routes.userChat, arguments: {
                                      'chatId': null,
                                      'orderId': transaction.id,
                                    });
                                  }
                                : null,
                            icon: const Icon(Icons.chat_bubble_outline,
                                color: Colors.white, size: 20),
                            label: Text(
                              transaction.canChatWithCourier
                                  ? 'Chat Kurir'
                                  : 'Kurir Belum Ditugaskan',
                              style: primaryTextStyle.copyWith(
                                color: Colors.white,
                                fontSize: Dimenssions.font13,
                                fontWeight: medium,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: transaction.canChatWithCourier
                                  ? primaryOrange
                                  : primaryOrange.withOpacity(0.5),
                              padding: EdgeInsets.symmetric(
                                  vertical: Dimenssions.height12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(Dimenssions.radius8),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),

                        // Spacer between buttons
                        SizedBox(width: Dimenssions.width10),

                        // Cancel Button (secondary action - outlined style)
                        if (transaction.status.toUpperCase() == 'PENDING')
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _showCancelDialog(transaction),
                              icon: Icon(Icons.cancel_outlined, size: 20),
                              label: Text(
                                'Batalkan',
                                style: primaryTextStyle.copyWith(
                                  color: alertColor,
                                  fontSize: Dimenssions.font13,
                                  fontWeight: medium,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: alertColor,
                                side: BorderSide(color: alertColor, width: 1.5),
                                padding: EdgeInsets.symmetric(
                                    vertical: Dimenssions.height12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      Dimenssions.radius8),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                  // Cancel Button Only (when chat not available)
                  if (transaction.status.toUpperCase() == 'PENDING' &&
                      !['PENDING', 'ACCEPTED', 'ON_DELIVERY', 'PICKED_UP']
                          .contains(transaction.status.toUpperCase()))
                    OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(transaction),
                      icon: Icon(Icons.cancel_outlined, size: 20),
                      label: Text(
                        'Batalkan Pesanan',
                        style: primaryTextStyle.copyWith(
                          color: alertColor,
                          fontSize: Dimenssions.font14,
                          fontWeight: medium,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: alertColor,
                        side: BorderSide(color: alertColor, width: 1.5),
                        padding: EdgeInsets.symmetric(
                            vertical: Dimenssions.height12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimenssions.radius8),
                        ),
                      ),
                    ),

                  // Review Button for completed orders
                  if (['COMPLETED', 'DELIVERED']
                      .contains(transaction.status.toUpperCase()))
                    Padding(
                      padding: EdgeInsets.only(top: Dimenssions.height8),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back(); // Close bottom sheet
                          Get.to(() => ReviewPage(transaction: transaction));
                        },
                        icon: const Icon(Icons.star_rounded, size: 20),
                        label: Text(
                          'Beri Ulasan',
                          style: primaryTextStyle.copyWith(
                            color: Colors.white,
                            fontSize: Dimenssions.font14,
                            fontWeight: medium,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA726),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: Dimenssions.height12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius8),
                          ),
                          elevation: 0,
                          minimumSize: const Size(double.infinity, 0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Merchant: ${order.merchantName}',
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font14,
                      fontWeight: medium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: Dimenssions.height4),
                  InkWell(
                    onTap: () {
                      Get.back(); // Close bottom sheet
                      Get.toNamed(Routes.userChat, arguments: {
                        'chatId': null,
                        'orderId': order.id,
                        'merchantId': order.merchantId,
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: Colors.green, size: Dimenssions.font14),
                        SizedBox(width: Dimenssions.width4),
                        Text(
                          'Chat Merchant',
                          style: primaryTextStyle.copyWith(
                            color: Colors.green,
                            fontSize: Dimenssions.font12,
                            fontWeight: medium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: Dimenssions.width10),
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
