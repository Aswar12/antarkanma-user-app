import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/widgets/order_card.dart';
import 'package:antarkanma/app/modules/merchant/controllers/merchant_order_controller.dart';

class MerchantOrderPage extends StatefulWidget {
  const MerchantOrderPage({super.key});

  @override
  State<MerchantOrderPage> createState() => MerchantOrderPageState();
}

class MerchantOrderPageState extends State<MerchantOrderPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final MerchantOrderController controller;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(MerchantOrderController());
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        switch (_tabController.index) {
          case 0:
            controller.filterOrders('all');
            break;
          case 1:
            controller.filterOrders('PENDING');
            break;
          case 2:
            controller.filterOrders('ACCEPTED');
            break;
          case 3:
            controller.filterOrders('PROCESSING');
            break;
          case 4:
            controller.filterOrders('COMPLETED');
            break;
          case 5:
            controller.filterOrders('REJECTED');
            break;
        }
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
      key: _scaffoldKey,
      backgroundColor: backgroundColor1,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildOrderStatistics(),
          _buildStatusTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('all'),
                _buildOrderList('PENDING'),
                _buildOrderList('ACCEPTED'),
                _buildOrderList('PROCESSING'),
                _buildOrderList('COMPLETED'),
                _buildOrderList('REJECTED'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      title: Text(
        'Daftar Pesanan',
        style: primaryTextStyle.copyWith(
          color: logoColor,
          fontSize: Dimenssions.font18,
          fontWeight: semiBold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: logoColor),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.filter_list, color: logoColor),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildOrderStatistics() {
    return Obx(() {
      final stats = controller.orderStats;
      final total = controller.totalAmount.value;

      return Container(
        padding: EdgeInsets.all(Dimenssions.width16),
        color: Colors.white,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Pending',
                  stats['PENDING']?.toString() ?? '0',
                  Colors.orange,
                ),
                _buildStatItem(
                  'Diterima',
                  stats['ACCEPTED']?.toString() ?? '0',
                  Colors.green,
                ),
                _buildStatItem(
                  'Proses',
                  stats['PROCESSING']?.toString() ?? '0',
                  logoColorSecondary,
                ),
                _buildStatItem(
                  'Selesai',
                  stats['COMPLETED']?.toString() ?? '0',
                  primaryColor,
                ),
              ],
            ),
            SizedBox(height: Dimenssions.height12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total Pendapatan: ',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font14,
                    fontWeight: medium,
                  ),
                ),
                Text(
                  'Rp ${total.toStringAsFixed(0)}',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font16,
                    fontWeight: bold,
                    color: logoColorSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font20,
            fontWeight: bold,
            color: color,
          ),
        ),
        SizedBox(height: Dimenssions.height4),
        Text(
          label,
          style: secondaryTextStyle.copyWith(
            fontSize: Dimenssions.font12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: logoColor,
        unselectedLabelColor: subtitleColor,
        indicatorColor: logoColor,
        tabs: const [
          Tab(text: 'Semua'),
          Tab(text: 'Pending'),
          Tab(text: 'Diterima'),
          Tab(text: 'Proses'),
          Tab(text: 'Selesai'),
          Tab(text: 'Ditolak'),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    return Obx(() {
      if (controller.isLoading.value && controller.orders.isEmpty) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(logoColorSecondary),
          ),
        );
      }

      if (controller.errorMessage.value.isNotEmpty && controller.orders.isEmpty) {
        return _buildErrorState();
      }

      if (controller.orders.isEmpty) {
        return _buildEmptyState();
      }

      return RefreshIndicator(
        onRefresh: () => controller.refreshOrders(),
        color: logoColorSecondary,
        child: ListView.builder(
          padding: EdgeInsets.all(Dimenssions.width16),
          itemCount: controller.filteredOrders.length,
          itemBuilder: (context, index) {
            final transaction = controller.filteredOrders[index];
            return _buildOrderCard(transaction);
          },
        ),
      );
    });
  }

  Widget _buildErrorState() {
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
            controller.errorMessage.value,
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font16,
              color: alertColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Dimenssions.height20),
          TextButton(
            onPressed: () => controller.refreshOrders(),
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
        ],
      ),
    );
  }

  Widget _buildOrderCard(transaction) {
    return Card(
      margin: EdgeInsets.only(bottom: Dimenssions.height16),
      color: backgroundColor1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimenssions.radius12),
      ),
      child: Column(
        children: [
          _buildOrderHeader(transaction),
          _buildOrderContent(transaction),
          if (controller.canProcessOrder(transaction.status))
            _buildOrderFooter(transaction),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(transaction) {
    return Container(
      padding: EdgeInsets.all(Dimenssions.width16),
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Dimenssions.radius12),
          topRight: Radius.circular(Dimenssions.radius12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${transaction.orderId ?? transaction.id}',
                style: primaryTextStyle.copyWith(
                  fontWeight: semiBold,
                ),
              ),
              SizedBox(height: Dimenssions.height4),
              Text(
                transaction.createdAt != null
                    ? transaction.createdAt!.toString()
                    : '-',
                style: secondaryTextStyle.copyWith(
                  fontSize: Dimenssions.font12,
                ),
              ),
            ],
          ),
          _buildStatusBadge(transaction.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = controller.getStatusColor(status);
    final text = controller.getStatusText(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimenssions.width12,
        vertical: Dimenssions.height4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimenssions.radius12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: primaryTextStyle.copyWith(
          color: color,
          fontSize: Dimenssions.font12,
          fontWeight: medium,
        ),
      ),
    );
  }

  Widget _buildOrderContent(transaction) {
    return Container(
      padding: EdgeInsets.all(Dimenssions.width16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: logoColor.withOpacity(0.1),
                child: Icon(Icons.person_outline, color: logoColor),
              ),
              SizedBox(width: Dimenssions.width12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.user?.name ?? 'Unknown Customer',
                      style: primaryTextStyle.copyWith(fontWeight: medium),
                    ),
                    SizedBox(height: Dimenssions.height4),
                    Text(
                      transaction.user?.phone ?? 'No Phone',
                      style: secondaryTextStyle,
                    ),
                    Text(
                      transaction.userLocation?.address ?? 'No Address',
                      style: secondaryTextStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: Dimenssions.height24),
          Text(
            'Daftar Pesanan:',
            style: primaryTextStyle.copyWith(fontWeight: medium),
          ),
          SizedBox(height: Dimenssions.height8),
          ...transaction.items.map<Widget>((item) {
            return Padding(
              padding: EdgeInsets.only(bottom: Dimenssions.height12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: Dimenssions.height60,
                          height: Dimenssions.height60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimenssions.radius8),
                            image: DecorationImage(
                              image: NetworkImage(item.product.firstImageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: Dimenssions.width12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.product.name,
                                style: primaryTextStyle.copyWith(
                                  fontWeight: medium,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: Dimenssions.height4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Dimenssions.width8,
                                  vertical: Dimenssions.height4,
                                ),
                                decoration: BoxDecoration(
                                  color: logoColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      Dimenssions.radius8),
                                ),
                                child: Text(
                                  '${item.quantity} item',
                                  style: primaryTextStyle.copyWith(
                                    color: logoColor,
                                    fontWeight: medium,
                                    fontSize: Dimenssions.font12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.formattedPrice,
                    style: primaryTextStyle.copyWith(
                      fontWeight: medium,
                      color: logoColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          Divider(height: Dimenssions.height24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: primaryTextStyle.copyWith(fontWeight: semiBold),
              ),
              Text(
                transaction.formattedGrandTotal,
                style: primaryTextStyle.copyWith(
                  fontWeight: bold,
                  color: logoColor,
                  fontSize: Dimenssions.font16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFooter(transaction) {
    return Container(
      padding: EdgeInsets.all(Dimenssions.width16),
      decoration: BoxDecoration(
        color: backgroundColor1,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showRejectDialog(transaction),
              style: OutlinedButton.styleFrom(
                backgroundColor: alertColor.withOpacity(0.1),
                foregroundColor: alertColor,
                side: BorderSide(color: alertColor),
                padding: EdgeInsets.symmetric(vertical: Dimenssions.height12),
              ),
              child: Text('Tolak Pesanan'),
            ),
          ),
          SizedBox(width: Dimenssions.width12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showProcessDialog(transaction),
              style: ElevatedButton.styleFrom(
                backgroundColor: logoColorSecondary,
                padding: EdgeInsets.symmetric(vertical: Dimenssions.height12),
              ),
              child: Text(
                'Proses Pesanan',
                style: primaryTextStyle.copyWith(
                  color: backgroundColor1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProcessDialog(transaction) {
    Get.dialog(
      AlertDialog(
        backgroundColor: backgroundColor1,
        title: Text('Proses Pesanan'),
        content: Text('Apakah Anda yakin ingin memproses pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Batal',
              style: primaryTextStyle.copyWith(color: secondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.processOrder(transaction.id.toString());
            },
            style: ElevatedButton.styleFrom(backgroundColor: logoColorSecondary),
            child: Text(
              'Proses',
              style: primaryTextStyle.copyWith(color: backgroundColor1),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(transaction) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: backgroundColor1,
        title: Text('Tolak Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Apakah Anda yakin ingin menolak pesanan ini?'),
            SizedBox(height: Dimenssions.height16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Alasan penolakan (opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimenssions.radius8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimenssions.radius8),
                  borderSide: BorderSide(color: backgroundColor3),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Dimenssions.radius8),
                  borderSide: BorderSide(color: logoColorSecondary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Batal',
              style: primaryTextStyle.copyWith(color: secondaryTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.rejectOrder(
                transaction.id.toString(),
                reasonController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: alertColor),
            child: Text(
              'Tolak',
              style: primaryTextStyle.copyWith(color: backgroundColor1),
            ),
          ),
        ],
      ),
    );
  }
}
