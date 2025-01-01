// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/widgets/order_card.dart';
import 'package:antarkanma/theme.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with SingleTickerProviderStateMixin {
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
            if (!Get.find<AuthService>().isLoggedIn.value) {
              return _buildLoginPrompt();
            }

            if (controller.isLoading.value) {
              return _buildLoadingState();
            }

            if (controller.errorMessage.value.isNotEmpty) {
              return _buildErrorState(controller.errorMessage.value);
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

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Silakan login terlebih dahulu',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font16,
            ),
          ),
          SizedBox(height: Dimenssions.height20),
          TextButton(
            onPressed: () => Get.toNamed(Routes.login),
            child: Text(
              'Login',
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

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(logoColorSecondary),
      ),
    );
  }

  Widget _buildOrderList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    final controller = Get.find<OrderController>();

    return RefreshIndicator(
      onRefresh: () => controller.refreshOrders(),
      color: logoColorSecondary,
      child: ListView.builder(
        padding: EdgeInsets.all(Dimenssions.height15),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return OrderCard(
            transaction: transaction,
            onTap: _showOrderDetails,
          );
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
              onPressed: () => Get.toNamed('/usermain/home'),
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

  Widget _buildErrorState(String message) {
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
            message,
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font16,
              color: alertColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: Dimenssions.height20),
          TextButton(
            onPressed: () => Get.find<OrderController>().refreshOrders(),
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
          child: OrderCard(
            transaction: transaction,
            onTap: (_) {}, // No action needed in details view
          ),
        ),
      ),
    );
  }
}
