import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/theme.dart';

class MerchantOrderController extends GetxController {
  final TransactionService _transactionService = Get.find<TransactionService>();
  final AuthService _authService = Get.find<AuthService>();
  final MerchantService _merchantService = Get.find<MerchantService>();

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<TransactionModel> orders = <TransactionModel>[].obs;
  final RxString selectedFilter = 'all'.obs;
  final RxInt currentPage = 1.obs;
  final int pageSize = 10;
  final RxBool hasMoreData = true.obs;
  final Rx<int?> merchantId = Rx<int?>(null);

  // Order statistics
  final RxMap<String, int> orderStats = <String, int>{}.obs;
  final RxDouble totalAmount = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    _initMerchantId();
  }

  Future<void> _initMerchantId() async {
    try {
      final merchant = await _merchantService.getMerchant();
      if (merchant == null || merchant.id == null) {
        throw Exception('No merchant found for this owner');
      }

      merchantId.value = merchant.id;
      fetchOrders();
      fetchOrderSummary();
    } catch (e) {
      errorMessage.value = 'Failed to initialize merchant: ${e.toString()}';
      CustomSnackbarX.showError(
        message: errorMessage.value,
        title: 'Error',
      );
    }
  }

  Future<void> fetchOrderSummary() async {
    try {
      final currentMerchantId = merchantId.value;
      if (currentMerchantId == null) {
        throw Exception('Merchant ID not found');
      }

      final response = await _transactionService.getTransactionSummaryByMerchant(
        currentMerchantId.toString(),
      );

      if (response != null) {
        orderStats.value = Map<String, int>.from(response['status_counts'] ?? {});
        totalAmount.value = ((response['total_sales'] ?? 0) as num).toDouble();
      }
    } catch (e) {
      print('Error fetching order summary: $e');
    }
  }

  Future<void> fetchOrders({bool refresh = false}) async {
    try {
      final currentMerchantId = merchantId.value;
      if (currentMerchantId == null) {
        throw Exception('Merchant ID not found');
      }

      if (refresh) {
        currentPage.value = 1;
        hasMoreData.value = true;
      }

      if (!hasMoreData.value && !refresh) return;

      isLoading.value = true;
      errorMessage.value = '';

      final status = selectedFilter.value != 'all' ? selectedFilter.value : null;

      final response = await _transactionService.getTransactionsByMerchant(
        currentMerchantId.toString(),
        page: currentPage.value,
        limit: pageSize,
        status: status,
      );

      if (response != null && response['orders'] != null) {
        final List<dynamic> orderList = response['orders'];
        final newOrders = orderList.map((json) => TransactionModel.fromJson(json)).toList();

        if (refresh) {
          orders.clear();
        }

        if (newOrders.isEmpty) {
          hasMoreData.value = false;
        } else {
          orders.addAll(newOrders);
          currentPage.value++;
        }
      }
      
    } catch (e) {
      errorMessage.value = 'Gagal memuat pesanan: ${e.toString()}';
      CustomSnackbarX.showError(
        message: errorMessage.value,
        title: 'Error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> processOrder(String orderId) async {
    try {
      final currentMerchantId = merchantId.value;
      if (currentMerchantId == null) {
        throw Exception('Merchant ID not found');
      }

      isLoading.value = true;
      errorMessage.value = '';
      
      final response = await _transactionService.updateOrderStatus(
        currentMerchantId.toString(),
        orderId,
        status: 'ACCEPTED',
      );

      if (response) {
        // Update local state
        final orderIndex = orders.indexWhere((order) => order.id.toString() == orderId);
        if (orderIndex != -1) {
          final updatedOrder = orders[orderIndex].copyWith(status: 'ACCEPTED');
          orders[orderIndex] = updatedOrder;
        }
        
        CustomSnackbarX.showSuccess(
          message: 'Pesanan berhasil diproses',
          title: 'Sukses',
        );

        // Refresh order summary
        fetchOrderSummary();
      }
      
    } catch (e) {
      errorMessage.value = 'Gagal memproses pesanan: ${e.toString()}';
      CustomSnackbarX.showError(
        message: errorMessage.value,
        title: 'Error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectOrder(String orderId, String reason) async {
    try {
      final currentMerchantId = merchantId.value;
      if (currentMerchantId == null) {
        throw Exception('Merchant ID not found');
      }

      isLoading.value = true;
      errorMessage.value = '';
      
      final response = await _transactionService.updateOrderStatus(
        currentMerchantId.toString(),
        orderId,
        status: 'REJECTED',
        notes: reason,
      );

      if (response) {
        // Update local state
        final orderIndex = orders.indexWhere((order) => order.id.toString() == orderId);
        if (orderIndex != -1) {
          final updatedOrder = orders[orderIndex].copyWith(
            status: 'REJECTED',
            note: reason,
          );
          orders[orderIndex] = updatedOrder;
        }
        
        CustomSnackbarX.showSuccess(
          message: 'Pesanan berhasil ditolak',
          title: 'Sukses',
        );

        // Refresh order summary
        fetchOrderSummary();
      }
      
    } catch (e) {
      errorMessage.value = 'Gagal menolak pesanan: ${e.toString()}';
      CustomSnackbarX.showError(
        message: errorMessage.value,
        title: 'Error',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void filterOrders(String status) {
    if (selectedFilter.value != status) {
      selectedFilter.value = status;
      fetchOrders(refresh: true);
    }
  }

  Future<void> refreshOrders() async {
    await fetchOrders(refresh: true);
    await fetchOrderSummary();
  }

  List<TransactionModel> get filteredOrders {
    if (selectedFilter.value == 'all') {
      return orders;
    }
    return orders.where((order) => 
      order.status.toLowerCase() == selectedFilter.value.toLowerCase()
    ).toList();
  }

  // Helper method to get order status display text
  String getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Konfirmasi';
      case 'ACCEPTED':
        return 'Diterima';
      case 'REJECTED':
        return 'Ditolak';
      case 'PROCESSING':
        return 'Sedang Diproses';
      case 'SHIPPED':
        return 'Dalam Pengiriman';
      case 'DELIVERED':
        return 'Terkirim';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  // Helper method to check if order can be processed
  bool canProcessOrder(String status) {
    return status.toUpperCase() == 'PENDING';
  }

  // Helper method to check if order can be rejected
  bool canRejectOrder(String status) {
    return status.toUpperCase() == 'PENDING';
  }

  // Helper method to get status color
  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return priceColor;
      case 'ACCEPTED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'PROCESSING':
        return logoColorSecondary;
      case 'SHIPPED':
        return Colors.blue;
      case 'DELIVERED':
        return Colors.purple;
      case 'COMPLETED':
        return primaryColor;
      case 'CANCELED':
        return alertColor;
      default:
        return secondaryTextColor;
    }
  }
}
