// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/theme.dart';
import 'package:intl/intl.dart';

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
            if (!Get.find<AuthService>().isLoggedIn.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Silakan login terlebih dahulu',
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font16,
                      ),
                    ),
                    SizedBox(height: Dimenssions.height20),
                    TextButton(
                      onPressed: () => Get.toNamed(Routes.login),
                      child: Text(
                        'Login',
                        style: primaryTextStyle.copyWith(
                          color: logoColorSecondary,
                          fontSize: Dimenssions.font16,
                          fontWeight: medium,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (controller.isLoading.value) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(logoColorSecondary),
                ),
              );
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return _buildErrorState(controller.errorMessage.value);
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
      return _buildEmptyState();
    }

    final controller = Get.find<OrderController>();

    return RefreshIndicator(
      onRefresh: () => controller.refreshOrders(),
      color: logoColorSecondary,
      child: ListView.builder(
        padding: EdgeInsets.all(Dimenssions.height15),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return _buildOrderCard(transaction);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icon_empty_cart.png',
            width: Dimenssions.height80,
          ),
          SizedBox(height: Dimenssions.height20),
          Text(
            'Belum ada pesanan',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font20,
              fontWeight: semiBold,
            ),
          ),
          SizedBox(height: Dimenssions.height10),
          Text(
            'Yuk mulai belanja',
            style: secondaryTextStyle.copyWith(
              fontSize: Dimenssions.font14,
            ),
          ),
          SizedBox(height: Dimenssions.height20),
          Container(
            height: Dimenssions.height45,
            padding: EdgeInsets.symmetric(
              horizontal: Dimenssions.width30,
            ),
            child: TextButton(
              onPressed: () => Get.toNamed('/main/home'),
              style: TextButton.styleFrom(
                backgroundColor: logoColorSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimenssions.radius15),
                ),
              ),
              child: Text(
                'Mulai Belanja',
                style: primaryTextStyle.copyWith(
                  color: backgroundColor1,
                  fontSize: Dimenssions.font16,
                  fontWeight: medium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(TransactionModel transaction) {
    final items = transaction.order?.orderItems ?? [];
    final orderId = transaction.orderId ?? transaction.id;
    final status = transaction.status ?? 'UNKNOWN';
    final total = transaction.totalPrice + transaction.shippingPrice;
    final date = transaction.createdAt != null
        ? DateFormat('dd MMM yyyy HH:mm').format(transaction.createdAt!)
        : '-';

    return GestureDetector(
      onTap: () => _showOrderDetails(transaction),
      child: Container(
        margin: EdgeInsets.only(bottom: Dimenssions.height15),
        padding: EdgeInsets.all(Dimenssions.height15),
        decoration: BoxDecoration(
          color: backgroundColor2,
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #$orderId',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font16,
                    fontWeight: semiBold,
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            SizedBox(height: Dimenssions.height10),
            if (items.isNotEmpty) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...items
                      .take(2)
                      .map((item) => Padding(
                            padding:
                                EdgeInsets.only(bottom: Dimenssions.height5),
                            child: Row(
                              children: [
                                Container(
                                  width: Dimenssions.width30,
                                  height: Dimenssions.height30,
                                  decoration: BoxDecoration(
                                    color: backgroundColor3,
                                    borderRadius: BorderRadius.circular(
                                        Dimenssions.radius8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${item.quantity}x',
                                      style: secondaryTextStyle.copyWith(
                                        fontSize: Dimenssions.font12,
                                        fontWeight: medium,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: Dimenssions.width10),
                                Expanded(
                                  child: Text(
                                    item.product.name,
                                    style: primaryTextStyle.copyWith(
                                      fontSize: Dimenssions.font14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                  if (items.length > 2)
                    Text(
                      '+ ${items.length - 2} item lainnya',
                      style: secondaryTextStyle.copyWith(
                        fontSize: Dimenssions.font12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              SizedBox(height: Dimenssions.height10),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Tanggal: ',
                      style: secondaryTextStyle.copyWith(
                        fontSize: Dimenssions.font14,
                      ),
                    ),
                    Text(
                      date,
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font14,
                      ),
                    ),
                  ],
                ),
                if (_canBeCancelled(status))
                  SizedBox(
                    height: Dimenssions.height25,
                    child: TextButton(
                      onPressed: () {
                        if (transaction.id != null) {
                          _showCancelConfirmation(transaction);
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: alertColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimenssions.width10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimenssions.radius8),
                        ),
                      ),
                      child: Text(
                        'Batalkan',
                        style: primaryTextStyle.copyWith(
                          color: backgroundColor1,
                          fontSize: Dimenssions.font12,
                          fontWeight: medium,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: secondaryTextStyle.copyWith(
                        fontSize: Dimenssions.font14,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'id',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(total),
                      style: priceTextStyle.copyWith(
                        fontSize: Dimenssions.font16,
                        fontWeight: semiBold,
                      ),
                    ),
                  ],
                ),
                if (_canBeCancelled(status)) ...[
                  SizedBox(height: Dimenssions.height10),
                  SizedBox(
                    width: double.infinity,
                    height: Dimenssions.height30,
                    child: TextButton(
                      onPressed: () {
                        if (transaction.id != null) {
                          _showCancelConfirmation(transaction);
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: alertColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimenssions.width10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimenssions.radius8),
                        ),
                      ),
                      child: Text(
                        'Batalkan Pesanan',
                        style: primaryTextStyle.copyWith(
                          color: backgroundColor1,
                          fontSize: Dimenssions.font12,
                          fontWeight: medium,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(TransactionModel transaction) {
    Get.defaultDialog(
      title: 'Konfirmasi Pembatalan',
      middleText: 'Apakah Anda yakin ingin membatalkan pesanan ini?',
      onCancel: () => Get.back(),
      onConfirm: () {
        Get.find<OrderController>().cancelOrder(transaction.id.toString());
        Get.back();
      },
      textConfirm: 'Ya',
      textCancel: 'Tidak',
      confirmTextColor: logoColor, // Use logoColor for confirmation text
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status.toUpperCase()) {
      case 'PENDING':
        color = priceColor;
        text = 'Menunggu Konfirmasi';
        break;
      case 'PROCESSING':
        color = logoColorSecondary;
        text = 'Sedang Diproses';
        break;
      case 'ON_DELIVERY':
        color = Colors.blue;
        text = 'Dalam Pengiriman';
        break;
      case 'COMPLETED':
        color = primaryColor;
        text = 'Selesai';
        break;
      case 'CANCELED':
        color = alertColor;
        text = 'Dibatalkan';
        break;
      default:
        color = secondaryTextColor;
        text = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimenssions.width10,
        vertical: Dimenssions.height5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: primaryTextStyle.copyWith(
          color: color,
          fontSize: Dimenssions.font12,
          fontWeight: semiBold,
        ),
      ),
    );
  }

  bool _canBeCancelled(String status) {
    final upperStatus = status.toUpperCase();
    return upperStatus == 'PENDING' || upperStatus == 'PROCESSING';
  }

  void _showOrderDetails(TransactionModel transaction) {
    Get.dialog(Dialog(
        backgroundColor: backgroundColor1,
        insetPadding: EdgeInsets.symmetric(
          horizontal: Dimenssions.width10,
          vertical: Dimenssions.height20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
        ),
        child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta! < 0) {
                // Dragging up - expand
                Get.back();
                _showOrderDetails(transaction);
              }
            },
            child: Container(
              width: double.infinity,
              height: Dimenssions.screenHeight * 0.9,
              decoration: BoxDecoration(
                color: backgroundColor1,
                borderRadius: BorderRadius.circular(Dimenssions.radius15),
              ),
              child: Column(children: [
                // Drag handle
                Container(
                  width: Dimenssions.width40,
                  height: Dimenssions.height5,
                  margin: EdgeInsets.symmetric(vertical: Dimenssions.height10),
                  decoration: BoxDecoration(
                    color: backgroundColor3,
                    borderRadius: BorderRadius.circular(Dimenssions.radius15),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Detail Pesanan',
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font18,
                                fontWeight: semiBold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Get.back(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text(
                          'Order #${transaction.orderId ?? transaction.id}',
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font16,
                            fontWeight: medium,
                          ),
                        ),
                        SizedBox(height: Dimenssions.height10),
                        if (transaction.items?.isNotEmpty ?? false) ...[
                          Text(
                            'Detail Produk:',
                            style: primaryTextStyle.copyWith(
                              fontWeight: medium,
                              fontSize: Dimenssions.font14,
                            ),
                          ),
                          SizedBox(height: Dimenssions.height10),
                          ...transaction.items!
                              .map((item) => Container(
                                    margin: EdgeInsets.only(
                                        bottom: Dimenssions.height10),
                                    padding:
                                        EdgeInsets.all(Dimenssions.height10),
                                    decoration: BoxDecoration(
                                      color: backgroundColor3.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(
                                          Dimenssions.radius8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: Dimenssions.width25,
                                              height: Dimenssions.height25,
                                              decoration: BoxDecoration(
                                                color: backgroundColor3,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        Dimenssions.radius8),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${item.quantity}x',
                                                  style: secondaryTextStyle
                                                      .copyWith(
                                                    fontSize:
                                                        Dimenssions.font12,
                                                    fontWeight: medium,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                                width: Dimenssions.width10),
                                            Expanded(
                                              child: Text(
                                                item.product.name,
                                                style:
                                                    primaryTextStyle.copyWith(
                                                  fontSize: Dimenssions.font14,
                                                  fontWeight: medium,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: Dimenssions.height5),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Harga Satuan:',
                                              style:
                                                  secondaryTextStyle.copyWith(
                                                fontSize: Dimenssions.font12,
                                              ),
                                            ),
                                            Text(
                                              NumberFormat.currency(
                                                locale: 'id',
                                                symbol: 'Rp ',
                                                decimalDigits: 0,
                                              ).format(item.price),
                                              style: priceTextStyle.copyWith(
                                                fontSize: Dimenssions.font12,
                                                fontWeight: medium,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Subtotal:',
                                              style:
                                                  secondaryTextStyle.copyWith(
                                                fontSize: Dimenssions.font12,
                                              ),
                                            ),
                                            Text(
                                              NumberFormat.currency(
                                                locale: 'id',
                                                symbol: 'Rp ',
                                                decimalDigits: 0,
                                              ).format(
                                                  item.price * item.quantity),
                                              style: priceTextStyle.copyWith(
                                                fontSize: Dimenssions.font12,
                                                fontWeight: medium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          SizedBox(height: Dimenssions.height10),
                          const Divider(),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Harga:',
                              style:
                                  primaryTextStyle.copyWith(fontWeight: medium),
                            ),
                            Text(
                              transaction.formattedTotalPrice,
                              style:
                                  priceTextStyle.copyWith(fontWeight: semiBold),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ongkos Kirim:',
                              style:
                                  primaryTextStyle.copyWith(fontWeight: medium),
                            ),
                            Text(
                              transaction.formattedShippingPrice,
                              style:
                                  priceTextStyle.copyWith(fontWeight: semiBold),
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: primaryTextStyle.copyWith(
                                  fontWeight: semiBold),
                            ),
                            Text(
                              transaction.formattedGrandTotal,
                              style: priceTextStyle.copyWith(
                                fontSize: Dimenssions.font16,
                                fontWeight: semiBold,
                              ),
                            ),
                          ],
                        ),
                        if (transaction.canBeCanceled) ...[
                          SizedBox(height: Dimenssions.height15),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton(
                              onPressed: () {
                                Get.back();
                                if (transaction.id != null) {
                                  Get.find<OrderController>()
                                      .cancelOrder(transaction.id.toString());
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: alertColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      Dimenssions.radius15),
                                ),
                              ),
                              child: Text(
                                'Batalkan Pesanan',
                                style: primaryTextStyle.copyWith(
                                  color: backgroundColor1,
                                  fontSize: Dimenssions.font14,
                                  fontWeight: medium,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              ]),
            ))));
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: Dimenssions.height45,
            color: alertColor,
          ),
          SizedBox(height: Dimenssions.height20),
          Text(
            message,
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font16,
              color: alertColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Dimenssions.height20),
          TextButton(
            onPressed: () => Get.find<OrderController>().refreshOrders(),
            child: Text(
              'Coba Lagi',
              style: primaryTextStyle.copyWith(
                color: logoColorSecondary,
                fontSize: Dimenssions.font16,
                fontWeight: medium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
