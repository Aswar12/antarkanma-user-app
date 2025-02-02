import 'package:antarkanma/app/services/storage_service.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:antarkanma/app/data/models/order_item_model.dart';

class OrderController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  late final TransactionService _transactionService;

  // Define transaction status constants
  static const String STATUS_PENDING = 'PENDING';
  static const String STATUS_PROCESSING = 'PROCESSING';
  static const String STATUS_COMPLETED = 'COMPLETED';
  static const String STATUS_CANCELED = 'CANCELED';

  // Define order status constants
  static const String ORDER_STATUS_PENDING = 'PENDING';
  static const String ORDER_STATUS_PROCESSING = 'PROCESSING';
  static const String ORDER_STATUS_READYTOPICKUP = 'READYTOPICKUP';
  static const String ORDER_STATUS_SHIPPED = 'SHIPPED';
  static const String ORDER_STATUS_DELIVERED = 'DELIVERED';
  static const String ORDER_STATUS_COMPLETED = 'COMPLETED';
  static const String ORDER_STATUS_CANCELED = 'CANCELED';

  OrderController() {
    try {
      _transactionService = Get.find<TransactionService>();
      debugPrint('\n=== OrderController Debug ===');
      debugPrint(
          'TransactionService found with instance ID: ${_transactionService.hashCode}');
    } catch (e) {
      debugPrint('Failed to find TransactionService, creating new instance');
      _transactionService = Get.put(TransactionService());
    }
  }

  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxInt currentTab = 0.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('\n=== OrderController onInit ===');
    debugPrint('Auth status: ${_authService.isLoggedIn.value}');

    if (_authService.isLoggedIn.value) {
      fetchTransactions(status: STATUS_PENDING);
    } else {
      debugPrint('User not logged in, skipping transaction fetch');
    }

    ever(_authService.isLoggedIn, (bool isLoggedIn) {
      if (isLoggedIn) {
        debugPrint('User logged in, fetching transactions');
        fetchTransactions(status: STATUS_PENDING);
      } else {
        debugPrint('User logged out, clearing transactions');
        transactions.clear();
      }
    });
  }

  Future<void> fetchTransactions({String? status}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      debugPrint('\n=== Fetching Transactions ===');
      debugPrint('Status filter: $status');

      // Fetch from API
      debugPrint('\n=== Fetching from API ===');
      final result = await _transactionService.getTransactions(
        status: status,
      );

      debugPrint('\n=== API Response ===');
      debugPrint('Fetched ${result.length} transactions');

      for (var transaction in result) {
        debugPrint('\nTransaction ID: ${transaction.id}');
        debugPrint('Transaction Status: ${transaction.status}');
        debugPrint('Orders count: ${transaction.orders.length}');
        for (var order in transaction.orders) {
          debugPrint('Order Status: ${order.orderStatus}');
          debugPrint('Items count: ${order.orderItems.length}');
        }
      }

      // Update state
      transactions.value = result;
      debugPrint('Successfully updated transactions');
    } catch (e, stackTrace) {
      debugPrint('Error fetching transactions: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage.value = e.toString();
      Future.delayed(const Duration(milliseconds: 300), () {
        CustomSnackbarX.showError(
          message: 'Gagal memuat pesanan: ${e.toString()}',
        );
      });
    } finally {
      isLoading.value = false;
    }
  }

  void setTransactionData(TransactionModel transaction) {
    transactions.add(transaction);
    update();
    refreshOrders();
  }

  List<TransactionModel> get activeOrders {
    final active = transactions.where((t) {
      // Check transaction status first
      final transactionStatus = t.status.toUpperCase();
      if (transactionStatus == STATUS_COMPLETED || 
          transactionStatus == STATUS_CANCELED) {
        return false;
      }

      // Then check if any order is active
      return t.orders.any((order) {
        final orderStatus = order.orderStatus.toUpperCase();
        debugPrint('Checking transaction ${t.id} order with status: $orderStatus');
        return orderStatus == ORDER_STATUS_PENDING || 
               orderStatus == ORDER_STATUS_PROCESSING || 
               orderStatus == ORDER_STATUS_READYTOPICKUP ||
               orderStatus == ORDER_STATUS_SHIPPED;
      });
    }).toList();

    debugPrint('\n=== Active Orders ===');
    debugPrint('Count: ${active.length}');
    for (var transaction in active) {
      debugPrint('Transaction ID: ${transaction.id}');
      debugPrint('Transaction Status: ${transaction.status}');
      for (var order in transaction.orders) {
        debugPrint('Order Status: ${order.orderStatus}, Items: ${order.orderItems.length}');
      }
    }

    return active;
  }

  List<TransactionModel> get historyOrders {
    final history = transactions.where((t) {
      // Check transaction status first
      final transactionStatus = t.status.toUpperCase();
      if (transactionStatus == STATUS_COMPLETED || 
          transactionStatus == STATUS_CANCELED) {
        return true;
      }

      // Then check if all orders are completed/canceled/delivered
      return t.orders.every((order) {
        final orderStatus = order.orderStatus.toUpperCase();
        debugPrint('Checking transaction ${t.id} order with status: $orderStatus');
        return orderStatus == ORDER_STATUS_COMPLETED || 
               orderStatus == ORDER_STATUS_CANCELED ||
               orderStatus == ORDER_STATUS_DELIVERED;
      });
    }).toList();

    debugPrint('\n=== History Orders ===');
    debugPrint('Count: ${history.length}');
    for (var transaction in history) {
      debugPrint('Transaction ID: ${transaction.id}');
      debugPrint('Transaction Status: ${transaction.status}');
      for (var order in transaction.orders) {
        debugPrint('Order Status: ${order.orderStatus}, Items: ${order.orderItems.length}');
      }
    }

    return history;
  }

  void onTabChanged(int index) async {
    debugPrint('\n=== Tab Changed ===');
    debugPrint('New index: $index');

    currentTab.value = index;
    errorMessage.value = '';

    if (index == 0) {
      await fetchTransactions(status: STATUS_PENDING);
    } else {
      await fetchTransactions(status: '$STATUS_COMPLETED,$STATUS_CANCELED');
    }
  }

  Future<void> cancelOrder(String transactionId) async {
    try {
      debugPrint('\n=== Canceling Order ===');
      debugPrint('Transaction ID: $transactionId');

      isLoading.value = true;

      // Cancel the transaction
      final success = await _transactionService.cancelTransaction(transactionId);
      if (!success) {
        throw Exception('Gagal membatalkan pesanan');
      }

      // Remove the transaction from the active list
      transactions.removeWhere((t) => t.id.toString() == transactionId);
      
      // Refresh the orders list to get updated data
      await refreshOrders();
      
      // Show success message after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        CustomSnackbarX.showSuccess(
          message: 'Pesanan berhasil dibatalkan',
        );
      });
    } catch (e, stackTrace) {
      debugPrint('Error canceling order: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage.value = e.toString();
      
      // Show error message after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        CustomSnackbarX.showError(
          message: 'Gagal membatalkan pesanan: ${e.toString()}',
        );
      });
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshOrders() async {
    debugPrint('\n=== Refreshing Orders ===');
    if (_authService.isLoggedIn.value) {
      await fetchTransactions(
          status: currentTab.value == 0
              ? STATUS_PENDING
              : '$STATUS_COMPLETED,$STATUS_CANCELED');
    } else {
      debugPrint('User not logged in, skipping refresh');
    }
  }
}
