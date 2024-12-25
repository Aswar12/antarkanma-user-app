import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme.dart';
import '../controllers/courier_controller.dart';

class CourierDeliveryPage extends GetView<CourierController> {
  const CourierDeliveryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor3,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Pengantaran',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeliveryStatusSummary(),
                const SizedBox(height: 20),
                _buildActiveDeliveries(),
                const SizedBox(height: 20),
                _buildCompletedDeliveries(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryStatusSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Hari Ini',
              style: primaryTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Obx(() => _buildStatusItem(
                      'Menunggu',
                      controller.pendingOrders.value.toString(),
                      Colors.orange,
                    )),
                Obx(() => _buildStatusItem(
                      'Aktif',
                      controller.inProgressOrders.value.toString(),
                      Colors.blue,
                    )),
                Obx(() => _buildStatusItem(
                      'Selesai',
                      controller.completedOrders.value.toString(),
                      Colors.green,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveDeliveries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengantaran Aktif',
          style: primaryTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => controller.activeDeliveries.isEmpty
            ? _buildEmptyState('Tidak ada pengantaran aktif')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.activeDeliveries.length,
                itemBuilder: (context, index) {
                  final delivery = controller.activeDeliveries[index];
                  return _buildDeliveryCard(delivery, isActive: true);
                },
              )),
      ],
    );
  }

  Widget _buildCompletedDeliveries() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengantaran Selesai',
          style: primaryTextStyle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => controller.completedDeliveries.isEmpty
            ? _buildEmptyState('Tidak ada pengantaran selesai')
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.completedDeliveries.length,
                itemBuilder: (context, index) {
                  final delivery = controller.completedDeliveries[index];
                  return _buildDeliveryCard(delivery, isActive: false);
                },
              )),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 48, color: primaryColor.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            style: subtitleTextStyle.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(Map<String, dynamic> delivery,
      {required bool isActive}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pesanan #${delivery['orderId']}',
                  style: primaryTextStyle.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? primaryColor : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'Sedang Diantar' : 'Selesai',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDeliveryInfo(
              Icons.store,
              'Pengambilan: ${delivery['pickupAddress']}',
            ),
            const SizedBox(height: 8),
            _buildDeliveryInfo(
              Icons.location_on,
              'Pengantaran: ${delivery['deliveryAddress']}',
            ),
            if (isActive) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => controller
                          .navigateToLocation(delivery['deliveryAddress']),
                      icon: const Icon(Icons.map),
                      label: const Text('Navigasi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          controller.completeDelivery(delivery['orderId']),
                      icon: const Icon(Icons.check),
                      label: const Text('Selesai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: subtitleTextStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: primaryTextStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: subtitleTextStyle.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
