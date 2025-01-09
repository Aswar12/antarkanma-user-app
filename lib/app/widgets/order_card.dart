import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/widgets/order_status_badge.dart';
import 'package:antarkanma/app/utils/order_utils.dart';
import 'package:antarkanma/theme.dart';

class OrderCard extends StatelessWidget {
  final TransactionModel transaction;
  final Function(TransactionModel) onTap;

  const OrderCard({
    Key? key,
    required this.transaction,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get items from both direct items and nested order items
    final items = transaction.items.isNotEmpty 
        ? transaction.items 
        : (transaction.order?.orderItems ?? []);
    
    print('OrderCard - Items count: ${items.length}'); // Debug print
    
    final orderId = (transaction.orderId ?? transaction.id)?.toString() ?? 'Unknown';
    final status = transaction.status;
    final date = transaction.createdAt != null
        ? DateFormat('dd MMM yyyy HH:mm').format(transaction.createdAt!)
        : '-';

    return GestureDetector(
      onTap: () => onTap(transaction),
      child: Container(
        margin: EdgeInsets.only(bottom: Dimenssions.height15),
        decoration: BoxDecoration(
          color: backgroundColor2,
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(orderId, status),
            _buildContent(items, date, status),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String orderId, String status) {
    return Container(
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
              Container(
                padding: EdgeInsets.all(Dimenssions.height8),
                decoration: BoxDecoration(
                  color: logoColorSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(Dimenssions.radius8),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: Dimenssions.font20,
                  color: logoColorSecondary,
                ),
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
          OrderStatusBadge(status: status),
        ],
      ),
    );
  }

  Widget _buildContent(List<dynamic> items, String date, String status) {
    return Container(
      padding: EdgeInsets.all(Dimenssions.height15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isNotEmpty) ...[
            ...items.take(2).map((item) => _buildProductItem(item)),
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
            Divider(
              height: 1,
              thickness: 1,
              color: backgroundColor3.withOpacity(0.1),
            ),
            SizedBox(height: Dimenssions.height12),
          ],
          _buildFooter(date, status),
        ],
      ),
    );
  }

  Widget _buildProductItem(dynamic item) {
    print('Building product item: ${item.product.name}'); // Debug print
    return Container(
      margin: EdgeInsets.only(bottom: Dimenssions.height12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: Dimenssions.height60,
            height: Dimenssions.height60,
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
                errorBuilder: (context, error, stackTrace) =>
                    Image.asset('assets/image_shop_logo.png'),
              ),
            ),
          ),
          SizedBox(width: Dimenssions.width10),
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
                SizedBox(height: Dimenssions.height8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: Dimenssions.width8,
                        vertical: Dimenssions.height4,
                      ),
                      decoration: BoxDecoration(
                        color: logoColorSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(Dimenssions.radius8),
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
                      formatPrice(item.price.toDouble()),
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
    );
  }

  Widget _buildFooter(String date, String status) {
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
            if (canOrderBeCancelled(status)) ...[
              SizedBox(height: Dimenssions.height10),
              _buildCancelButton(),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () {
        if (transaction.id != null) {
          _showCancelConfirmation();
        }
      },
      style: TextButton.styleFrom(
        backgroundColor: alertColor.withOpacity(0.1),
        padding: EdgeInsets.symmetric(
          horizontal: Dimenssions.width10,
          vertical: Dimenssions.height5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimenssions.radius8),
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
    );
  }

  void _showCancelConfirmation() {
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
}
