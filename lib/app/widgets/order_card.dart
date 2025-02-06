import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/widgets/order_status_badge.dart';
import 'package:antarkanma/app/utils/order_utils.dart';
import 'package:antarkanma/app/services/image_service.dart';
import 'package:antarkanma/theme.dart';

class OrderCard extends StatelessWidget {
  final TransactionModel transaction;
  final Function(TransactionModel) onTap;

  const OrderCard({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  Future<void> _showCancelDialog() async {
    await showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor1,
        title: Text(
          'Konfirmasi Pembatalan',
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font16,
            fontWeight: semiBold,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini?',
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font14,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
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
          TextButton(
            onPressed: () async {
              Get.back();
              final controller = Get.find<OrderController>();
              await controller.cancelOrder(transaction.id.toString());
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
    );
  }

  Widget _buildHeader(String orderId, String date) {
    return Container(
      padding: EdgeInsets.all(Dimenssions.height12),
      decoration: BoxDecoration(
        color: backgroundColor3.withOpacity(0.13),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Dimenssions.radius15),
          topRight: Radius.circular(Dimenssions.radius15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Dimenssions.height6),
                  decoration: BoxDecoration(
                    color: logoColorSecondary.withOpacity(0.26),
                    borderRadius: BorderRadius.circular(Dimenssions.radius8),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: Dimenssions.font18,
                    color: logoColorSecondary,
                  ),
                ),
                SizedBox(width: Dimenssions.width8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #$orderId',
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font14,
                          fontWeight: semiBold,
                        ),
                      ),
                      SizedBox(height: Dimenssions.height2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: Dimenssions.font12,
                            color: secondaryTextColor,
                          ),
                          SizedBox(width: Dimenssions.width4),
                          Text(
                            date,
                            style: secondaryTextStyle.copyWith(
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
          ),
          SizedBox(width: Dimenssions.width8),
          OrderStatusBadge(status: transaction.status),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (transaction.orders.isEmpty) {
      return Container(
        padding: EdgeInsets.all(Dimenssions.height12),
        child: Text(
          'No order details available',
          style: secondaryTextStyle,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(Dimenssions.height12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...transaction.orders.map((order) => _buildOrderSection(order)),
          Divider(
            height: 1,
            thickness: 1,
            color: backgroundColor3.withOpacity(0.26),
          ),
          SizedBox(height: Dimenssions.height8),
          _buildFooter(transaction.status),
        ],
      ),
    );
  }

  Widget _buildOrderSection(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: Dimenssions.height8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Merchant: ${order.merchantName}',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font14,
                    fontWeight: medium,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: Dimenssions.width8),
              OrderStatusBadge(status: order.orderStatus),
            ],
          ),
        ),
        ...order.orderItems.take(2).map((item) => _buildProductItem(item)),
        if (order.orderItems.length > 2)
          Padding(
            padding: EdgeInsets.only(bottom: Dimenssions.height8),
            child: Text(
              '+ ${order.orderItems.length - 2} item lainnya',
              style: secondaryTextStyle.copyWith(
                fontSize: Dimenssions.font12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Divider(
          height: 16,
          thickness: 1,
          color: backgroundColor3.withOpacity(0.26),
        ),
      ],
    );
  }

  Widget _buildProductItem(dynamic item) {
    return Container(
      margin: EdgeInsets.only(bottom: Dimenssions.height8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: Dimenssions.height65,
            height: Dimenssions.height65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Dimenssions.radius8),
              border: Border.all(
                color: backgroundColor3.withOpacity(0.51),
                width: 1,
              ),
            ),
            child: ImageService.to.buildProductThumbnail(
              item.product.firstImageUrl,
              size: Dimenssions.height65,
            ),
          ),
          SizedBox(width: Dimenssions.width8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font12,
                    fontWeight: medium,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Dimenssions.height4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimenssions.width6,
                              vertical: Dimenssions.height2,
                            ),
                            decoration: BoxDecoration(
                              color: logoColorSecondary.withOpacity(0.26),
                              borderRadius:
                                  BorderRadius.circular(Dimenssions.radius6),
                            ),
                            child: Text(
                              '${item.quantity} item',
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font12,
                                color: logoColorSecondary,
                              ),
                            ),
                          ),
                          SizedBox(width: Dimenssions.width8),
                          Flexible(
                            child: Text(
                              formatPrice(item.price.toDouble()),
                              style: priceTextStyle.copyWith(
                                fontSize: Dimenssions.font12,
                              ),
                              overflow: TextOverflow.ellipsis,
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
        ],
      ),
    );
  }

  Widget _buildFooter(String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
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
            SizedBox(height: Dimenssions.height2),
            Text(
              transaction.formattedGrandTotal,
              style: priceTextStyle.copyWith(
                fontSize: Dimenssions.font14,
                fontWeight: semiBold,
              ),
            ),
          ],
        ),
        if (status.toUpperCase() == 'PENDING')
          TextButton(
            onPressed: _showCancelDialog,
            style: TextButton.styleFrom(
              backgroundColor: alertColor.withOpacity(0.26),
              padding: EdgeInsets.symmetric(
                horizontal: Dimenssions.width8,
                vertical: Dimenssions.height2,
              ),
              minimumSize: Size(0, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimenssions.radius6),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderId = transaction.id?.toString() ?? 'Unknown';
    final date = transaction.createdAt != null
        ? DateFormat('dd MMM yyyy HH:mm').format(transaction.createdAt!)
        : '-';

    return GestureDetector(
      onTap: () => onTap(transaction),
      child: Container(
        margin: EdgeInsets.only(bottom: Dimenssions.height12),
        decoration: BoxDecoration(
          color: backgroundColor2,
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.13),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(orderId, date),
            _buildContent(),
          ],
        ),
      ),
    );
  }
}
