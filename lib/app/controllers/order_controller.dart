import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart'
    as transaction;
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class OrderController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  late final TransactionService _transactionService;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

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
  static const String ORDER_STATUS_PICKED_UP = 'PICKED_UP';
  static const String ORDER_STATUS_WAITING_APPROVAL = 'WAITING_APPROVAL';

  // Store rejection reasons
  final RxMap<String, String> rejectionReasons = <String, String>{}.obs;

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
  final RxList<transaction.TransactionModel> transactions =
      <transaction.TransactionModel>[].obs;
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

    // Listen for notifications
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('\n=== Received Foreground Message ===');
      debugPrint('Message data: ${message.data}');

      String? type = message.data['type'] as String?;
      String? transactionId = message.data['transaction_id'] as String?;
      String? orderId = message.data['order_id'] as String?;
      String? reason = message.data['reason'] as String?;
      String? paymentMethod = message.data['payment_method'] as String?;

      if (type != null && transactionId != null) {
        debugPrint('Notification received - Type: $type');
        debugPrint('Transaction ID: $transactionId');
        debugPrint('Order ID: $orderId');
        debugPrint('Reason: $reason');
        debugPrint('Payment Method: $paymentMethod');

        // Refresh orders first to get latest status
        await refreshOrders();

        // Handle notification based on type
        switch (type) {
          case 'courier_found':
            CustomSnackbarX.showInfo(
              title: 'Kurir Ditemukan',
              message: 'Kurir telah ditemukan untuk pesanan Anda',
            );
            break;
          case 'order_approved':
            CustomSnackbarX.showInfo(
              title: 'Pesanan Disetujui Merchant',
              message: 'Pesanan #$orderId telah disetujui dan sedang diproses',
            );
            break;
          case 'order_rejected':
            if (orderId != null && reason != null) {
              rejectionReasons[orderId] = reason;
              CustomSnackbarX.showError(
                title: 'Pesanan Ditolak',
                message: 'Pesanan #$orderId ditolak: $reason',
              );
            }
            break;
          case 'order_ready_pickup':
            CustomSnackbarX.showInfo(
              title: 'Pesanan Siap',
              message:
                  'Pesanan Anda sudah siap dan akan segera diambil oleh kurir',
            );
            break;
          case 'order_in_transit':
            CustomSnackbarX.showInfo(
              title: 'Pesanan Dalam Perjalanan',
              message: 'Pesanan Anda sedang dalam perjalanan',
            );
            break;
          case 'order_completed':
            final notificationMessage = paymentMethod?.toUpperCase() == 'MANUAL'
                ? 'Pesanan COD Anda telah diantar dan pembayaran diterima'
                : 'Pesanan Anda telah diantar';
            CustomSnackbarX.showSuccess(
              title: 'Pesanan Selesai',
              message: notificationMessage,
            );
            break;
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('\n=== Message Opened App ===');
      debugPrint('Message data: ${message.data}');

      String? type = message.data['type'] as String?;
      String? transactionId = message.data['transaction_id'] as String?;
      String? orderId = message.data['order_id'] as String?;
      String? reason = message.data['reason'] as String?;

      if (type != null && transactionId != null) {
        debugPrint('Notification opened - Type: $type');
        debugPrint('Transaction ID: $transactionId');
        debugPrint('Order ID: $orderId');
        debugPrint('Reason: $reason');

        if (orderId != null && type == 'order_rejected' && reason != null) {
          rejectionReasons[orderId] = reason;
        }
        refreshOrders();
      }
    });
  }

  String? getRejectionReason(String orderId) {
    return rejectionReasons[orderId];
  }

  // Check if entire transaction can be cancelled (only when all orders are pending)
  bool canCancelTransaction(transaction.TransactionModel transaction) {
    return transaction.orders.every((order) {
      return order.orderItems.every((item) {
        return item.merchantApproval?.toUpperCase() == 'PENDING';
      });
    });
  }

  // Check if a specific order can be cancelled (only when merchant_approval is PENDING)
  Future<bool> canCancelOrder(transaction.OrderModel order) async {
    return order.orderItems.every((item) {
      return item.merchantApproval?.toUpperCase() == 'PENDING';
    });
  }

  // Cancel entire transaction
  Future<void> cancelTransaction(String transactionId) async {
    try {
      isLoading.value = true;

      // Cancel the transaction
      final success =
          await _transactionService.cancelTransaction(transactionId);
      if (!success) {
        throw Exception('Gagal membatalkan transaksi');
      }

      // Remove the transaction from the active list
      transactions.removeWhere((t) => t.id.toString() == transactionId);

      // Refresh the orders list to get updated data
      await refreshOrders();

      // Show success message after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        CustomSnackbarX.showSuccess(
          message: 'Transaksi berhasil dibatalkan',
        );
      });
    } catch (e) {
      errorMessage.value = e.toString();

      // Show error message after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        CustomSnackbarX.showError(
          message: 'Gagal membatalkan transaksi: ${e.toString()}',
        );
      });
    } finally {
      isLoading.value = false;
    }
  }

  // Cancel a specific order
  Future<void> cancelOrder(String orderId) async {
    try {
      isLoading.value = true;

      // Cancel the specific order
      final success = await _transactionService.cancelOrder(orderId);
      if (!success) {
        throw Exception('Gagal membatalkan pesanan');
      }

      // Refresh the orders list to get updated data
      await refreshOrders();

      // Show success message after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        CustomSnackbarX.showSuccess(
          message: 'Pesanan berhasil dibatalkan',
        );
      });
    } catch (e) {
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

  Future<void> fetchTransactions({String? status}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _transactionService.getTransactions(
        status: status,
      );

      // Update state
      transactions.value = result;
    } catch (e) {
      Future.delayed(const Duration(milliseconds: 300), () {
        CustomSnackbarX.showError(
          message: 'Gagal memuat pesanan: ${e.toString()}',
        );
      });
    } finally {
      isLoading.value = false;
    }
  }

  void setTransactionData(transaction.TransactionModel transaction) {
    transactions.add(transaction);
    update();
    refreshOrders();
  }

  List<transaction.TransactionModel> get activeOrders {
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
        return orderStatus == ORDER_STATUS_PENDING ||
            orderStatus == ORDER_STATUS_PROCESSING ||
            orderStatus == ORDER_STATUS_READYTOPICKUP ||
            orderStatus == ORDER_STATUS_SHIPPED ||
            orderStatus == ORDER_STATUS_PICKED_UP ||
            orderStatus ==
                ORDER_STATUS_WAITING_APPROVAL; // Added waiting approval status
      });
    }).toList();

    return active;
  }

  List<transaction.TransactionModel> get historyOrders {
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
        return orderStatus == ORDER_STATUS_COMPLETED ||
            orderStatus == ORDER_STATUS_CANCELED ||
            orderStatus == ORDER_STATUS_DELIVERED;
      });
    }).toList();

    return history;
  }

  void onTabChanged(int index) async {
    currentTab.value = index;
    errorMessage.value = '';

    if (index == 0) {
      await fetchTransactions(status: STATUS_PENDING);
    } else {
      await fetchTransactions(status: '$STATUS_COMPLETED,$STATUS_CANCELED');
    }
  }

  Future<void> refreshOrders() async {
    if (_authService.isLoggedIn.value) {
      await fetchTransactions(
          status: currentTab.value == 0
              ? STATUS_PENDING
              : '$STATUS_COMPLETED,$STATUS_CANCELED');
    }
  }
}
