import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class MerchantHomePage extends StatefulWidget {
  const MerchantHomePage({super.key});

  @override
  State<MerchantHomePage> createState() => MerchantHomePageState();
}

class MerchantHomePageState extends State<MerchantHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String merchantName = "Nama Merchant";

  // Sample data for daily sales chart
  final List<DailySalesData> salesData = [
    DailySalesData(DateTime.now().subtract(const Duration(days: 6)), 35000),
    DailySalesData(DateTime.now().subtract(const Duration(days: 5)), 38000),
    DailySalesData(DateTime.now().subtract(const Duration(days: 4)), 42000),
    DailySalesData(DateTime.now().subtract(const Duration(days: 3)), 40000),
    DailySalesData(DateTime.now().subtract(const Duration(days: 2)), 45000),
    DailySalesData(DateTime.now().subtract(const Duration(days: 1)), 48000),
    DailySalesData(DateTime.now(), 50000),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor2,
      appBar: _buildCustomAppBar(),
      body: ListView(
        padding: EdgeInsets.all(Dimenssions.width16),
        children: [
          _buildDashboardStats(),
          SizedBox(height: Dimenssions.height20),
          _buildSalesChart(),
          SizedBox(height: Dimenssions.height20),
          _buildTopProducts(),
          SizedBox(height: Dimenssions.height20),
          _buildQuickActionsSection(),
          SizedBox(height: Dimenssions.height20),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      backgroundColor: transparentColor,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Halo, $merchantName!',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font18,
              fontWeight: semiBold,
              color: logoColor,
            ),
          ),
          Text(
            'Selamat datang di dashboard Anda',
            style: secondaryTextStyle.copyWith(
              fontSize: Dimenssions.font14,
              color: subtitleColor,
            ),
          ),
        ],
      ),
      leading: IconButton(
        icon: Icon(Icons.menu, color: logoColor, size: Dimenssions.iconSize24),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined,
              color: logoColor, size: Dimenssions.iconSize20),
          onPressed: () {},
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimenssions.width10),
          child: CircleAvatar(
            radius: Dimenssions.width20,
            backgroundImage: const AssetImage('assets/image_profile.png'),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardStats() {
    final items = [
      {
        'title': 'Total Penjualan',
        'value': 'Rp 15.240K',
        'icon': Icons.monetization_on,
        'color': Colors.green
      },
      {
        'title': 'Jumlah Pesanan',
        'value': '45',
        'icon': Icons.shopping_cart,
        'color': Colors.blue
      },
      {
        'title': 'Pendapatan Bulanan',
        'value': 'Rp 8.750K',
        'icon': Icons.account_balance_wallet,
        'color': Colors.purple
      },
      {
        'title': 'Produk Terjual',
        'value': '156',
        'icon': Icons.inventory,
        'color': Colors.orange
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(vertical: Dimenssions.height8),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: Dimenssions.width16,
        mainAxisSpacing: Dimenssions.height16,
        children: items
            .map((item) => _buildStatCard(
                  title: item['title'] as String,
                  value: item['value'] as String,
                  icon: item['icon'] as IconData,
                  color: item['color'] as Color,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSalesChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(Dimenssions.width16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimenssions.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grafik Penjualan Harian',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font18,
              fontWeight: bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                dateFormat: DateFormat('dd MMM'),
                intervalType: DateTimeIntervalType.days,
                interval: 1,
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                numberFormat: NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              tooltipBehavior: TooltipBehavior(
                enable: true,
                format: 'point.x : Rp point.y',
              ),
              series: <CartesianSeries<DailySalesData, DateTime>>[
                SplineAreaSeries<DailySalesData, DateTime>(
                  dataSource: salesData,
                  xValueMapper: (DailySalesData sales, _) => sales.date,
                  yValueMapper: (DailySalesData sales, _) => sales.sales,
                  color: logoColor.withOpacity(0.3),
                  borderColor: logoColor,
                  borderWidth: 3,
                  name: 'Penjualan',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Container(
      padding: EdgeInsets.all(Dimenssions.width16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimenssions.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Added this line
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Produk Terlaris',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font18,
              fontWeight: bold,
            ),
          ),
          const SizedBox(height: 10),
          ListView(
            // Changed to ListView
            shrinkWrap: true, // Added this line
            physics: const NeverScrollableScrollPhysics(), // Added this line
            children: [
              _buildProductItem('Produk A', '50 terjual', 'Rp 2.500K'),
              _buildProductItem('Produk B', '35 terjual', 'Rp 1.750K'),
              _buildProductItem('Produk C', '28 terjual', 'Rp 1.400K'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(String name, String sold, String revenue) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: logoColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.shopping_bag, color: logoColor),
      ),
      title: Text(name, style: primaryTextStyle),
      subtitle: Text(sold, style: secondaryTextStyle),
      trailing:
          Text(revenue, style: primaryTextStyle.copyWith(color: logoColor)),
    );
  }

  Widget _buildQuickActionsSection() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Cepat',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font20,
              fontWeight: bold,
              color: logoColor,
            ),
          ),
          SizedBox(height: Dimenssions.height10),
          Container(
            height: 120, // Increased height
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                    child: _buildQuickActionCard(
                        'Manajemen Pesanan', Icons.list_alt)),
                SizedBox(width: 8),
                Expanded(
                    child: _buildQuickActionCard(
                        'Laporan Penjualan', Icons.analytics)),
                SizedBox(width: 8),
                Expanded(
                    child: _buildQuickActionCard(
                        'Kelola Produk', Icons.inventory_2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
        child: Padding(
          padding: EdgeInsets.all(Dimenssions.width8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: Dimenssions.iconSize24, color: logoColor),
              SizedBox(height: Dimenssions.height8),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: Dimenssions.font12,
                    color: logoColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimenssions.width8,
        vertical: Dimenssions.width4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimenssions.radius16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          Text(
            value,
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font14,
              fontWeight: bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: secondaryTextStyle.copyWith(
              fontSize: Dimenssions.font12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class DailySalesData {
  DailySalesData(this.date, this.sales);
  final DateTime date;
  final double sales;
}
