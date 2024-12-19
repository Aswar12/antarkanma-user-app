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
    final items = transaction.items;
    final orderId = transaction.orderId ?? transaction.id;
    final status = transaction.status ?? 'UNKNOWN';
    final date = transaction.createdAt != null
        ? DateFormat('dd MMM yyyy HH:mm').format(transaction.createdAt!)
        : '-';

    return GestureDetector(
      onTap: () => _showOrderDetails(transaction),
      child: Container(
        margin: EdgeInsets.only(bottom: Dimenssions.height15),
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
          children: [
            // Header with order ID and status
            Container(
              padding: EdgeInsets.all(Dimenssions.height15),
              decoration: BoxDecoration(
                color: backgroundColor3.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Dimenssions.radius15),
                  topRight: Radius.circular(Dimenssions.radius15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: Dimenssions.font20,
                        color: logoColorSecondary,
                      ),
                      SizedBox(width: Dimenssions.width10),
                      Text(
                        'Order #$orderId',
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font16,
                          fontWeight: semiBold,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(status),
                ],
              ),
            ),
            // Order content
            Container(
              padding: EdgeInsets.all(Dimenssions.height15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (items.isNotEmpty) ...[
                    // Products list
                    ...items.take(2).map((item) => Container(
                          margin: EdgeInsets.only(bottom: Dimenssions.height12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Product Image with border
                              Container(
                                width: Dimenssions.height60,
                                height: Dimenssions.height60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(
                                      Dimenssions.radius8),
                                  border: Border.all(
                                    color: backgroundColor3.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      Dimenssions.radius8),
                                  child: Image.network(
                                    item.product.firstImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Image.asset(
                                                'assets/image_shop_logo.png'),
                                  ),
                                ),
                              ),
                              SizedBox(width: Dimenssions.width10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: primaryTextStyle.copyWith(
                                            fontSize: Dimenssions.font14,
                                            fontWeight: medium,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: Dimenssions.height4),
                                        Text(
                                          'Toko: ${item.merchant.name}',
                                          style: secondaryTextStyle.copyWith(
                                            fontSize: Dimenssions.font12,
                                          ),
                                        ),
                                        SizedBox(height: Dimenssions.height4),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: Dimenssions.width5,
                                            vertical: Dimenssions.height2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: logoColorSecondary
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                                Dimenssions.radius8),
                                          ),
                                          child: Text(
                                            '${item.quantity} item',
                                            style: primaryTextStyle.copyWith(
                                              fontSize: Dimenssions.font12,
                                              color: logoColorSecondary,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: Dimenssions.width10),
                                        Text(
                                          item.formattedPrice,
                                          style: priceTextStyle.copyWith(
                                            fontSize: Dimenssions.font12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (items.length > 2)
                      Padding(
                        padding: EdgeInsets.only(bottom: Dimenssions.height12),
                        child: Text(
                          '+ ${items.length - 2} item lainnya',
                          style: secondaryTextStyle.copyWith(
                            fontSize: Dimenssions.font12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    // Divider before total
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: backgroundColor3.withOpacity(0.1),
                    ),
                    SizedBox(height: Dimenssions.height12),
                  ],
                  // Total and date row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: secondaryTextStyle.copyWith(
                              fontSize: Dimenssions.font12,
                            ),
                          ),
                          SizedBox(height: Dimenssions.height4),
                          Text(
                            transaction.formattedGrandTotal,
                            style: priceTextStyle.copyWith(
                              fontSize: Dimenssions.font16,
                              fontWeight: semiBold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: Dimenssions.font14,
                                color: secondaryTextColor,
                              ),
                              SizedBox(width: Dimenssions.width5),
                              Text(
                                date,
                                style: secondaryTextStyle.copyWith(
                                  fontSize: Dimenssions.font12,
                                ),
                              ),
                            ],
                          ),
                          if (_canBeCancelled(status)) ...[
                            SizedBox(height: Dimenssions.height10),
                            TextButton(
                              onPressed: () {
                                if (transaction.id != null) {
                                  _showCancelConfirmation(transaction);
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: alertColor.withOpacity(0.1),
                                padding: EdgeInsets.symmetric(
                                  horizontal: Dimenssions.width10,
                                  vertical: Dimenssions.height5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      Dimenssions.radius8),
                                  side: BorderSide(color: alertColor),
                                ),
                              ),
                              child: Text(
                                'Batalkan',
                                style: primaryTextStyle.copyWith(
                                  color: alertColor,
                                  fontSize: Dimenssions.font12,
                                  fontWeight: medium,
                                ),
                              ),
                            ),
                          ],
                        ],
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
      confirmTextColor: logoColor,
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
    Get.dialog(
      Dialog(
        backgroundColor: backgroundColor1,
        insetPadding: EdgeInsets.symmetric(
          horizontal: Dimenssions.width10,
          vertical: Dimenssions.height20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
        ),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxHeight: Dimenssions.screenHeight * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(Dimenssions.height15),
                decoration: BoxDecoration(
                  color: backgroundColor2,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Dimenssions.radius15),
                    topRight: Radius.circular(Dimenssions.radius15),
                  ),
                ),
                child: Row(
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
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(Dimenssions.height15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID and Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${transaction.orderId ?? transaction.id}',
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font16,
                                fontWeight: medium,
                              ),
                            ),
                            _buildStatusBadge(transaction.status),
                          ],
                        ),
                        SizedBox(height: Dimenssions.height15),
                        // Date
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: Dimenssions.font16,
                              color: secondaryTextColor,
                            ),
                            SizedBox(width: Dimenssions.width5),
                            Text(
                              transaction.createdAt != null
                                  ? DateFormat('dd MMM yyyy HH:mm')
                                      .format(transaction.createdAt!)
                                  : '-',
                              style: secondaryTextStyle.copyWith(
                                fontSize: Dimenssions.font14,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Dimenssions.height20),
                        // Products
                        Text(
                          'Detail Produk',
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font16,
                            fontWeight: semiBold,
                          ),
                        ),
                        SizedBox(height: Dimenssions.height10),
                        if (transaction.items?.isNotEmpty ?? false) ...[
                          ...transaction.items!.map((item) => Container(
                                margin: EdgeInsets.only(
                                    bottom: Dimenssions.height10),
                                padding: EdgeInsets.all(Dimenssions.height10),
                                decoration: BoxDecoration(
                                  color: backgroundColor3.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(
                                      Dimenssions.radius8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Product Image
                                        Container(
                                          width: Dimenssions.height60,
                                          height: Dimenssions.height60,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                Dimenssions.radius8),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  item.product.firstImageUrl),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: Dimenssions.width10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.product.name,
                                                    style: primaryTextStyle
                                                        .copyWith(
                                                      fontSize:
                                                          Dimenssions.font14,
                                                      fontWeight: medium,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          Dimenssions.height5),
                                                  Text(
                                                    'Toko: ${item.merchant.name}',
                                                    style: secondaryTextStyle
                                                        .copyWith(
                                                      fontSize:
                                                          Dimenssions.font12,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          Dimenssions.height5),
                                                ],
                                              ),
                                              Text(
                                                '${item.quantity}x ${NumberFormat.currency(
                                                  locale: 'id',
                                                  symbol: 'Rp ',
                                                  decimalDigits: 0,
                                                ).format(item.price)}',
                                                style:
                                                    secondaryTextStyle.copyWith(
                                                  fontSize: Dimenssions.font12,
                                                ),
                                              ),
                                              Text(
                                                'Subtotal: ${NumberFormat.currency(
                                                  locale: 'id',
                                                  symbol: 'Rp ',
                                                  decimalDigits: 0,
                                                ).format(item.price * item.quantity)}',
                                                style: priceTextStyle.copyWith(
                                                  fontSize: Dimenssions.font12,
                                                  fontWeight: medium,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              )),
                        ] else
                          Text(
                            'Tidak ada produk',
                            style: secondaryTextStyle.copyWith(
                              fontSize: Dimenssions.font14,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        SizedBox(height: Dimenssions.height20),
                        // Price Details
                        Text(
                          'Rincian Pembayaran',
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font16,
                            fontWeight: semiBold,
                          ),
                        ),
                        SizedBox(height: Dimenssions.height10),
                        Container(
                          padding: EdgeInsets.all(Dimenssions.height10),
                          decoration: BoxDecoration(
                            color: backgroundColor3.withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Harga:',
                                    style: secondaryTextStyle,
                                  ),
                                  Text(
                                    transaction.formattedTotalPrice,
                                    style: priceTextStyle.copyWith(
                                      fontWeight: medium,
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
                                    'Ongkos Kirim:',
                                    style: secondaryTextStyle,
                                  ),
                                  Text(
                                    transaction.formattedShippingPrice,
                                    style: priceTextStyle.copyWith(
                                      fontWeight: medium,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                height: Dimenssions.height20,
                                thickness: 0.5,
                                color: secondaryTextColor.withOpacity(0.3),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Pembayaran:',
                                    style: primaryTextStyle.copyWith(
                                      fontWeight: semiBold,
                                    ),
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Cancel Button at bottom if applicable
              if (_canBeCancelled(transaction.status))
                SizedBox(
                  width: double.infinity,
                  height: Dimenssions.height45,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimenssions.width15,
                      vertical: Dimenssions.height5,
                    ),
                    child: TextButton(
                      onPressed: () {
                        Get.back();
                        if (transaction.id != null) {
                          _showCancelConfirmation(transaction);
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: alertColor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimenssions.radius8),
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
                ),
            ],
          ),
        ),
      ),
    );
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
