import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/widgets/order_card.dart';
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

    // Group transactions by their ID
    Map<String, List<TransactionModel>> groupedTransactions = {};
    for (var transaction in transactions) {
      String transactionId = transaction.id.toString();
      if (!groupedTransactions.containsKey(transactionId)) {
        groupedTransactions[transactionId] = [];
      }
      groupedTransactions[transactionId]!.add(transaction);
    }

    return RefreshIndicator(
      onRefresh: () => _orderController.refreshOrders(),
      color: logoColorSecondary,
      child: ListView.builder(
        padding: EdgeInsets.all(Dimenssions.height15),
        itemCount: groupedTransactions.keys.length,
        itemBuilder: (context, index) {
          String transactionId = groupedTransactions.keys.elementAt(index);
          List<TransactionModel> transactionList = groupedTransactions[transactionId]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...transactionList.map((transaction) {
                return OrderCard(
                  transaction: transaction,
                  onTap: _showOrderDetails,
                );
              }).toList(),
            ],
          );
        },
      ),
    );
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
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: backgroundColor2,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(Dimenssions.radius15),
                    topRight: Radius.circular(Dimenssions.radius15),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detail Transaksi',
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '#${transaction.id}',
                          style: primaryTextStyle.copyWith(
                            color: logoColorSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (transaction.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy HH:mm').format(transaction.createdAt!),
                        style: secondaryTextStyle.copyWith(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product List
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transaction.items.length,
                        itemBuilder: (context, index) {
                          final item = transaction.items[index];
                          return Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.product.firstImageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey[300],
                                          child: Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Product Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.name,
                                        style: primaryTextStyle.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Toko: ${item.merchant.name}',
                                        style: secondaryTextStyle.copyWith(
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${item.quantity}x ${item.formattedPrice}',
                                            style: primaryTextStyle,
                                          ),
                                          Text(
                                            item.formattedTotalPrice,
                                            style: priceTextStyle.copyWith(
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
                          );
                        },
                      ),

                      // Shipping Address
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: backgroundColor2.withOpacity(0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alamat Pengiriman',
                              style: primaryTextStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (transaction.userLocation != null) ...[
                              Text(
                                transaction.userLocation!.address,
                                style: primaryTextStyle,
                              ),
                              Text(
                                '${transaction.userLocation!.city}, ${transaction.userLocation!.postalCode}',
                                style: primaryTextStyle,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Payment Details
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rincian Pembayaran',
                              style: primaryTextStyle.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subtotal', style: primaryTextStyle),
                                Text(
                                  transaction.formattedTotalPrice,
                                  style: primaryTextStyle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Ongkos Kirim', style: primaryTextStyle),
                                Text(
                                  transaction.formattedShippingPrice,
                                  style: primaryTextStyle,
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: primaryTextStyle.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  transaction.formattedGrandTotal,
                                  style: priceTextStyle.copyWith(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
