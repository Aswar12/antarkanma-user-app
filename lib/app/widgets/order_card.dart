import 'package:antarkanma/app/data/models/order_item_model.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/widgets/order_status_badge.dart';
import 'package:antarkanma/app/widgets/rating_dialog.dart';
import 'package:antarkanma/app/services/rating_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:get/get.dart';

class OrderCard extends StatelessWidget {
  final TransactionModel transaction;
  final Function(TransactionModel) onTap;

  const OrderCard({
    Key? key,
    required this.transaction,
    required this.onTap,
  }) : super(key: key);

  Future<void> _openWhatsApp(String phoneNumber, String message) async {
    String formattedPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '+62${formattedPhone.substring(1)}';
    } 
    else if (!formattedPhone.startsWith('+62')) {
      formattedPhone = '+62$formattedPhone';
    }
    
    final whatsappUrl = Uri.parse(
      'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}'
    );

    if (await url_launcher.canLaunchUrl(whatsappUrl)) {
      await url_launcher.launchUrl(whatsappUrl);
    }
  }

  String _buildOrderItemsMessage(List<OrderItemModel> items) {
    return items.map((item) => 
      '${item.quantity}x ${item.product.name}'
    ).join('\n');
  }

  Widget _buildContactButtons(String name, String phoneNumber, String role, {String? orderInfo, List<OrderItemModel>? items, bool isCourier = false}) {
    if (phoneNumber.isEmpty) return const SizedBox.shrink();

    final color = isCourier ? logoColor : logoColorSecondary;

    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton.icon(
        onPressed: () {
          String message = 'Halo, saya pembeli\n\n';
          message += 'No. Transaksi: #${transaction.id}\n';
          if (orderInfo != null) {
            message += 'No. Order: $orderInfo\n';
          }
          if (items != null && items.isNotEmpty) {
            message += '\nDetail Pesanan:\n${_buildOrderItemsMessage(items)}';
          }
          _openWhatsApp(phoneNumber, message);
        },
        icon: Icon(Icons.chat_outlined, color: color, size: 20),
        label: Text(
          'Chat $role',
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font14,
            fontWeight: medium,
            color: color,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: EdgeInsets.symmetric(vertical: Dimenssions.height12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimenssions.radius12),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingButton(OrderItemModel item, int orderId) {
    return OutlinedButton.icon(
      onPressed: () async {
        final ratingService = Get.find<RatingService>();
        final hasRated = await ratingService.hasRatedProduct(orderId, item.product.id);
        
        if (!hasRated) {
          Get.dialog(
            RatingDialog(
              productName: item.product.name,
              productImage: item.product.firstImageUrl,
              onSubmit: (rating, review) {
                ratingService.submitProductRating(
                  productId: item.product.id,
                  orderId: orderId,
                  rating: rating,
                  review: review,
                );
              },
            ),
          );
        } else {
          Get.snackbar(
            'Info',
            'Anda sudah memberikan rating untuk produk ini',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.grey[800],
            colorText: Colors.white,
          );
        }
      },
      icon: Icon(Icons.star_outline, color: logoColor, size: 20),
      label: Text(
        'Beri Rating',
        style: primaryTextStyle.copyWith(
          fontSize: Dimenssions.font14,
          fontWeight: medium,
          color: logoColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: logoColor,
        side: BorderSide(color: logoColor),
        padding: EdgeInsets.symmetric(vertical: Dimenssions.height12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimenssions.radius12),
        ),
      ),
    );
  }

  bool get _hasCourierApproved {
    return transaction.status.toUpperCase() == 'SHIPPED' || 
           transaction.status.toUpperCase() == 'DELIVERED' ||
           transaction.status.toUpperCase() == 'COMPLETED';
  }

  bool get _canRate {
    return transaction.status.toUpperCase() == 'COMPLETED';
  }

  Widget _buildCourierInfo() {
    if (transaction.courier == null || !_hasCourierApproved) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: Dimenssions.height12),
        Divider(height: 1, color: backgroundColor3.withValues(alpha: 51)),
        SizedBox(height: Dimenssions.height12),
        Row(
          children: [
            Icon(
              Icons.delivery_dining,
              size: Dimenssions.iconSize20,
              color: logoColorSecondary,
            ),
            SizedBox(width: Dimenssions.width8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kurir',
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font12,
                      fontWeight: medium,
                    ),
                  ),
                  SizedBox(height: Dimenssions.height4),
                  Text(
                    transaction.courier!.fullDetails,
                    style: secondaryTextStyle.copyWith(
                      fontSize: Dimenssions.font12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: Dimenssions.height8),
        _buildContactButtons(
          transaction.courier!.name,
          transaction.courier!.fullDetails.split('(').last.split(')').first.trim(),
          'Kurir',
          isCourier: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(transaction),
      child: Container(
        margin: EdgeInsets.only(bottom: Dimenssions.height15),
        padding: EdgeInsets.all(Dimenssions.height12),
        decoration: BoxDecoration(
          color: backgroundColor1,
          borderRadius: BorderRadius.circular(Dimenssions.radius8),
          border: Border.all(color: backgroundColor3.withValues(alpha: 26)),
        ),
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
                      'Transaction #${transaction.id}',
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font14,
                        fontWeight: medium,
                      ),
                    ),
                    if (transaction.createdAt != null) ...[
                      SizedBox(height: Dimenssions.height4),
                      Text(
                        DateFormat('dd MMM yyyy HH:mm').format(transaction.createdAt!),
                        style: secondaryTextStyle.copyWith(
                          fontSize: Dimenssions.font12,
                        ),
                      ),
                    ],
                  ],
                ),
                OrderStatusBadge(status: transaction.status),
              ],
            ),
            SizedBox(height: Dimenssions.height12),
            Divider(height: 1, color: backgroundColor3.withValues(alpha: 51)),
            SizedBox(height: Dimenssions.height12),
            ...transaction.orders.map((order) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.merchantName,
                            style: primaryTextStyle.copyWith(
                              fontSize: Dimenssions.font14,
                              fontWeight: semiBold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: Dimenssions.height4),
                          Text(
                            'Order #${order.id}',
                            style: secondaryTextStyle.copyWith(
                              fontSize: Dimenssions.font12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OrderStatusBadge(status: order.orderStatus),
                  ],
                ),
                SizedBox(height: Dimenssions.height8),
                ...order.orderItems.take(2).map((item) => Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: Dimenssions.height8),
                      child: Row(
                        children: [
                          Container(
                            width: Dimenssions.height40,
                            height: Dimenssions.height40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimenssions.radius4),
                              border: Border.all(
                                color: backgroundColor3.withValues(alpha: 51),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Dimenssions.radius4),
                              child: Image.network(
                                item.product.firstImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: backgroundColor3.withValues(alpha: 26),
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: secondaryTextColor,
                                    size: Dimenssions.font16,
                                  ),
                                ),
                              ),
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
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${item.quantity}x ${item.formattedPrice}',
                                  style: secondaryTextStyle.copyWith(
                                    fontSize: Dimenssions.font12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_canRate) ...[
                      SizedBox(height: Dimenssions.height8),
                      _buildRatingButton(item, order.id ?? 0),
                      SizedBox(height: Dimenssions.height8),
                    ],
                  ],
                )),
                if (order.orderItems.length > 2)
                  Text(
                    '+${order.orderItems.length - 2} item lainnya',
                    style: secondaryTextStyle.copyWith(
                      fontSize: Dimenssions.font12,
                    ),
                  ),
                if (order.orderItems.isNotEmpty) ...[
                  SizedBox(height: Dimenssions.height8),
                  _buildContactButtons(
                    order.merchantName,
                    order.orderItems.first.merchant.phoneNumber,
                    'Penjual',
                    orderInfo: '#${order.id}',
                    items: order.orderItems,
                  ),
                ],
                if (order != transaction.orders.last) ...[
                  SizedBox(height: Dimenssions.height12),
                  Divider(height: 1, color: backgroundColor3.withValues(alpha: 51)),
                  SizedBox(height: Dimenssions.height12),
                ],
              ],
            )),
            _buildCourierInfo(),
            SizedBox(height: Dimenssions.height12),
            Divider(height: 1, color: backgroundColor3.withValues(alpha: 51)),
            SizedBox(height: Dimenssions.height12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font12,
                    fontWeight: medium,
                  ),
                ),
                Text(
                  transaction.formattedGrandTotal,
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
    );
  }
}
