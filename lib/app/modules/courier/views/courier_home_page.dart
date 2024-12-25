import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme.dart';
import '../controllers/courier_controller.dart';
import '../../../widgets/profile_image.dart';
import '../../../services/auth_service.dart';

class CourierHomePage extends GetView<CourierController> {
  const CourierHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Get.find<AuthService>();

    return Scaffold(
      backgroundColor: backgroundColor1,
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: backgroundColor1,
              floating: true,
              snap: true,
              elevation: 0,
              toolbarHeight: kToolbarHeight,
              title: Container(
                margin: EdgeInsets.symmetric(vertical: Dimenssions.height2),
                child: Obx(() => Text(
                      'Selamat Datang, ${controller.courierName}',
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font16,
                        fontWeight: semiBold,
                      ),
                    )),
              ),
              actions: [
                Container(
                  margin: EdgeInsets.only(
                    top: Dimenssions.height2,
                    right: Dimenssions.width15,
                    bottom: Dimenssions.height2,
                  ),
                  child: Obx(() {
                    final user = authService.getUser();
                    if (user == null) {
                      return Container(
                        width: Dimenssions.height40,
                        height: Dimenssions.height40,
                        decoration: BoxDecoration(
                          color: backgroundColor3,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: logoColorSecondary.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          color: secondaryTextColor,
                          size: Dimenssions.iconSize20,
                        ),
                      );
                    }
                    return ProfileImage(
                      user: user,
                      size: Dimenssions.height40,
                    );
                  }),
                ),
              ],
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: () async {
            await controller.refreshData();
          },
          color: logoColorSecondary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildOnlineStatusBar(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDailySummaryCard(),
                      const SizedBox(height: 16),
                      _buildPerformanceCard(),
                      const SizedBox(height: 16),
                      _buildEarningsCard(),
                      const SizedBox(height: 16),
                      _buildDeliveryStatsCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: backgroundColor2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: subtitleTextStyle.copyWith(fontSize: 12),
              ),
              Obx(() => Text(
                    controller.isOnline.value ? 'Aktif' : 'Tidak Aktif',
                    style: primaryTextStyle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          controller.isOnline.value ? Colors.green : Colors.red,
                    ),
                  )),
            ],
          ),
          Obx(() => Switch(
                value: controller.isOnline.value,
                onChanged: (_) => controller.toggleOnlineStatus(),
                activeColor: primaryColor,
              )),
        ],
      ),
    );
  }

  Widget _buildDailySummaryCard() {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => _buildSummaryItem(
                      'Pengantaran',
                      controller.dailyDeliveries.value.toString(),
                      Icons.local_shipping,
                    )),
                Obx(() => _buildSummaryItem(
                      'Pendapatan',
                      'Rp ${controller.dailyEarnings.value}',
                      Icons.account_balance_wallet,
                    )),
                Obx(() => _buildSummaryItem(
                      'Jarak',
                      '${controller.totalDistance.value} km',
                      Icons.route,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performa',
              style: primaryTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => _buildPerformanceItem(
                      'Penilaian',
                      '${controller.performanceRating.value}',
                      Icons.star,
                      Colors.amber,
                    )),
                Obx(() => _buildPerformanceItem(
                      'Tingkat Sukses',
                      '${controller.successRate.value}%',
                      Icons.check_circle,
                      Colors.green,
                    )),
                Obx(() => _buildPerformanceItem(
                      'Poin',
                      controller.loyaltyPoints.value.toString(),
                      Icons.card_giftcard,
                      Colors.purple,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pendapatan',
              style: primaryTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => _buildEarningsItem(
                      'Mingguan',
                      'Rp ${controller.weeklyEarnings.value}',
                      Icons.calendar_today,
                      Colors.blue,
                    )),
                Obx(() => _buildEarningsItem(
                      'Bulanan',
                      'Rp ${controller.monthlyEarnings.value}',
                      Icons.date_range,
                      Colors.green,
                    )),
                Obx(() => _buildEarningsItem(
                      'Bonus',
                      'Rp ${controller.performanceBonus.value}',
                      Icons.military_tech,
                      Colors.orange,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik Pengantaran',
              style: primaryTextStyle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(() => _buildStatsItem(
                      'Total',
                      controller.totalDeliveries.value.toString(),
                      Icons.delivery_dining,
                      Colors.indigo,
                    )),
                Obx(() => _buildStatsItem(
                      'Rata-rata Waktu',
                      '${controller.averageDeliveryTime.value} min',
                      Icons.timer,
                      Colors.teal,
                    )),
                Obx(() => _buildStatsItem(
                      'Efisiensi Rute',
                      '${controller.routeEfficiency.value}%',
                      Icons.trending_up,
                      Colors.deepPurple,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: primaryTextStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: subtitleTextStyle.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPerformanceItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: primaryTextStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: subtitleTextStyle.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildEarningsItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: primaryTextStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: subtitleTextStyle.copyWith(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildStatsItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: primaryTextStyle.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: subtitleTextStyle.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}
