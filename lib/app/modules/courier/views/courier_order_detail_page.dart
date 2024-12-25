import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/courier_controller.dart';

class CourierOrderDetailPage extends GetView<CourierController> {
  final Map<String, dynamic> order;

  const CourierOrderDetailPage({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<dynamic> merchants = order['merchants'] ?? [];

    return Scaffold(
      backgroundColor: backgroundColor3,
      appBar: AppBar(
        backgroundColor: backgroundColor2,
        title: Text(
          'Detail Orderan',
          style: primaryTextStyle.copyWith(
            fontSize: 18,
            fontWeight: medium,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryTextColor),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Dimenssions.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Earnings
            Container(
              padding: EdgeInsets.all(Dimenssions.width16),
              decoration: BoxDecoration(
                color: backgroundColor2,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${order['orderId']}',
                        style: primaryTextStyle.copyWith(
                          fontSize: 18,
                          fontWeight: semiBold,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimenssions.width12,
                          vertical: Dimenssions.height6,
                        ),
                        decoration: BoxDecoration(
                          color: logoColorSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Rp ${order['earnings']}',
                          style: priceTextStyle.copyWith(
                            fontSize: 16,
                            fontWeight: semiBold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Dimenssions.height16),
                  Row(
                    children: [
                      _buildInfoChip(
                        '${order['distance']} km',
                        Icons.directions_bike,
                      ),
                      SizedBox(width: Dimenssions.width12),
                      _buildInfoChip(
                        '${order['estimatedTime']} min',
                        Icons.access_time,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: Dimenssions.height20),

            // Merchant Details
            Text(
              'Detail Merchant',
              style: primaryTextStyle.copyWith(
                fontSize: 16,
                fontWeight: semiBold,
              ),
            ),
            SizedBox(height: Dimenssions.height12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: merchants.length,
              itemBuilder: (context, index) {
                final merchant = merchants[index];
                return Container(
                  margin: EdgeInsets.only(bottom: Dimenssions.height12),
                  padding: EdgeInsets.all(Dimenssions.width16),
                  decoration: BoxDecoration(
                    color: backgroundColor2,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimenssions.width8,
                              vertical: Dimenssions.height4,
                            ),
                            decoration: BoxDecoration(
                              color: logoColorSecondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Merchant ${index + 1}',
                              style: primaryTextStyle.copyWith(
                                fontSize: 12,
                                color: logoColorSecondary,
                                fontWeight: medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Dimenssions.height8),
                      Text(
                        merchant['name'],
                        style: primaryTextStyle.copyWith(
                          fontSize: 16,
                          fontWeight: semiBold,
                        ),
                      ),
                      SizedBox(height: Dimenssions.height8),
                      _buildLocationInfo(
                        'Alamat Pickup',
                        merchant['address'],
                        Icons.store,
                      ),
                      SizedBox(height: Dimenssions.height12),
                      Text(
                        'Items:',
                        style: primaryTextStyle.copyWith(
                          fontSize: 14,
                          fontWeight: medium,
                        ),
                      ),
                      SizedBox(height: Dimenssions.height8),
                      ...List.generate(
                        merchant['items'].length,
                        (itemIndex) => Padding(
                          padding: EdgeInsets.only(left: Dimenssions.width16),
                          child: Text(
                            '• ${merchant['items'][itemIndex]['name']} (${merchant['items'][itemIndex]['quantity']}x)',
                            style: primaryTextStyle.copyWith(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: Dimenssions.height20),

            // Customer Details
            Text(
              'Detail Pengantaran',
              style: primaryTextStyle.copyWith(
                fontSize: 16,
                fontWeight: semiBold,
              ),
            ),
            SizedBox(height: Dimenssions.height12),
            Container(
              padding: EdgeInsets.all(Dimenssions.width16),
              decoration: BoxDecoration(
                color: backgroundColor2,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerInfo(
                    'Nama',
                    order['customerName'],
                    Icons.person,
                  ),
                  SizedBox(height: Dimenssions.height12),
                  _buildCustomerInfo(
                    'Telepon',
                    order['customerPhone'],
                    Icons.phone,
                  ),
                  SizedBox(height: Dimenssions.height12),
                  _buildLocationInfo(
                    'Alamat Pengantaran',
                    order['deliveryAddress'],
                    Icons.location_on,
                  ),
                  if (order['notes'] != null) ...[
                    SizedBox(height: Dimenssions.height12),
                    _buildCustomerInfo(
                      'Catatan',
                      order['notes'],
                      Icons.note,
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: Dimenssions.height24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      controller.rejectDelivery(order['orderId'].toString());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alertColor,
                      padding: EdgeInsets.symmetric(
                        vertical: Dimenssions.height12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Tolak',
                      style: primaryTextStyle.copyWith(
                        color: Colors.white,
                        fontWeight: medium,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: Dimenssions.width16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      controller.acceptOrder(order['orderId'].toString());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: logoColorSecondary,
                      padding: EdgeInsets.symmetric(
                        vertical: Dimenssions.height12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Terima',
                      style: primaryTextStyle.copyWith(
                        color: Colors.white,
                        fontWeight: medium,
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
  }

  Widget _buildLocationInfo(String title, String address, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: secondaryTextColor,
        ),
        SizedBox(width: Dimenssions.width8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: secondaryTextStyle.copyWith(
                  fontSize: 12,
                ),
              ),
              Text(
                address,
                style: primaryTextStyle.copyWith(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo(String title, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: secondaryTextColor,
        ),
        SizedBox(width: Dimenssions.width8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: secondaryTextStyle.copyWith(
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: primaryTextStyle.copyWith(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimenssions.width12,
        vertical: Dimenssions.height6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor4,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: secondaryTextColor,
          ),
          SizedBox(width: Dimenssions.width4),
          Text(
            text,
            style: secondaryTextStyle.copyWith(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
