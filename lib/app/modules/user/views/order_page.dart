// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:intl/intl.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
            bottom: TabBar(
              tabs: const [
                Tab(text: 'Aktif'),
                Tab(text: 'Riwayat'),
              ],
              labelColor: logoColorSecondary,
              unselectedLabelColor: secondaryTextColor,
              indicatorColor: logoColorSecondary,
            ),
          ),
        ),
        body: GetBuilder<OrderController>(
          init: OrderController(),
          builder: (controller) {
            return Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: logoColorSecondary,
                  ),
                );
              }

              return TabBarView(
                children: [
                  _buildOrderList(controller.activeOrders),
                  _buildOrderList([
                    ...controller.completedOrders,
                    ...controller.cancelledOrders
                  ]),
                ],
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => Get.find<OrderController>().refreshOrders(),
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
    final items = transaction.items ?? [];
    final orderId = transaction.orderId ?? transaction.id ?? '';
    final status = transaction.status ?? 'UNKNOWN';
    final total = transaction.totalPrice + (transaction.shippingPrice ?? 0);
    final date = transaction.createdAt?.toString().substring(0, 16) ?? '-';

    return Container(
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
            Text(
              '${items.length} item',
              style: secondaryTextStyle.copyWith(
                fontSize: Dimenssions.font14,
              ),
            ),
            SizedBox(height: Dimenssions.height5),
          ],
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
          SizedBox(height: Dimenssions.height5),
          Text(
            'Tanggal: $date',
            style: secondaryTextStyle.copyWith(
              fontSize: Dimenssions.font14,
            ),
          ),
          if (_canBeCancelled(status)) ...[
            SizedBox(height: Dimenssions.height15),
            Container(
              height: Dimenssions.height45,
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  if (transaction.id != null) {
                    Get.find<OrderController>()
                        .cancelOrder(transaction.id.toString());
                  }
                },
                style: TextButton.styleFrom(
                  backgroundColor: alertColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Dimenssions.radius15),
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
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status.toUpperCase()) {
      case 'PENDING':
        color = priceColor;
        text = 'Menunggu';
        break;
      case 'PROCESSING':
        color = logoColorSecondary;
        text = 'Diproses';
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
    return status.toUpperCase() == 'PENDING' ||
        status.toUpperCase() == 'PROCESSING';
  }
}
