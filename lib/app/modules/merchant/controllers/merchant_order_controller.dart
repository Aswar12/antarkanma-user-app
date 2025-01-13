import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:flutter/foundation.dart';

class MerchantOrderController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storageService = StorageService.instance;
  final MerchantService _merchantService = Get.find<MerchantService>();
  late final TransactionService _transactionService;

  // Define valid order statuses
  static const List<String> validOrderStatuses = [
    'PENDING',
    'PROCESSING',
    'READYTOPICKUP',
    'COMPLETED',
    'CANCELED'
  ];

  MerchantOrderController() {
    try {
      _transactionService = Get.find<TransactionService>();
      debugPrint('\n=== MerchantOrderController Debug ===');
      debugPrint(
          'TransactionService found with instance ID: ${_transactionService.hashCode}');
    } catch (e) {
      debugPrint('Failed to find TransactionService, creating new instance');
      _transactionService = Get.put(TransactionService());
    }
  }

  // Observable variables
  final RxList<TransactionModel> orders = <TransactionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString currentFilter = 'all'.obs;
  final RxInt currentPage = 1.obs;
  final RxDouble totalAmount = 0.0.obs;

  // Order statistics
  final RxMap<String, int> orderStats = <String, int>{
    'PENDING': 0,
    'PROCESSING': 0,
    'READYTOPICKUP': 0,
    'COMPLETED': 0,
    'CANCELED': 0,
  }.obs;

  // Computed list of filtered orders
  List<TransactionModel> get filteredOrders {
    if (currentFilter.value == 'all') {
      return orders;
    }
    return orders.where((order) => order.status == currentFilter.value).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<String?> getMerchantId() async {
    try {
      final merchant = await _merchantService.getMerchant();
      if (merchant == null || merchant.id == null) {
        throw Exception('Merchant not found');
      }
      return merchant.id.toString();
    } catch (e) {
      debugPrint('Error getting merchant ID: $e');
      return null;
    }
  }

  Future<void> fetchOrders() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      errorMessage.value = '';

      final mId = await getMerchantId();
      if (mId == null) {
        throw Exception('Merchant ID not found');
      }

      debugPrint('\n=== Fetching Merchant Orders ===');
      debugPrint('Merchant ID: $mId');
      debugPrint('Current Filter: ${currentFilter.value}');
      debugPrint('Current Page: ${currentPage.value}');

      final response = await _transactionService.getTransactionsByMerchant(
        mId,
        page: currentPage.value,
        limit: 10,
        status: currentFilter.value == 'all' ? null : currentFilter.value,
      );

      if (response != null) {
        final transactionsData = response['transactions'];
        if (transactionsData != null) {
          final List<dynamic> data = transactionsData['data'] ?? [];
          debugPrint('Received ${data.length} orders');

          final newOrders =
              data.map((json) => TransactionModel.fromJson(json)).toList();

          if (currentPage.value == 1) {
            orders.clear();
          }

          orders.addAll(newOrders);

          // Update pagination info
          final pagination = transactionsData['pagination'];
          hasMore.value = pagination != null &&
              pagination['current_page'] < pagination['last_page'];

          // Update order statistics from response
          final Map<String, int>? statusCounts = response['status_counts'] as Map<String, int>?;
          if (statusCounts != null) {
            debugPrint('\n=== Updating Order Stats ===');
            orderStats.value = Map<String, int>.from(orderStats); // Create a new map
            statusCounts.forEach((key, value) {
              if (orderStats.containsKey(key)) {
                orderStats[key] = value;
                debugPrint('$key: $value');
              }
            });
          }

          // Update total amount
          final statistics = response['statistics'];
          if (statistics != null && statistics['total_revenue'] != null) {
            totalAmount.value = (statistics['total_revenue'] as num).toDouble();
          }

          debugPrint('Orders updated successfully');
        }
      } else {
        throw Exception('Failed to fetch orders');
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void filterOrders(String status) {
    debugPrint('\n=== Filtering Orders ===');
    debugPrint('Filter Status: $status');
    currentFilter.value = status;
    debugPrint('Filtered Orders Count: ${filteredOrders.length}');
  }

  Future<void> refreshOrders() async {
    debugPrint('\n=== Refreshing Orders ===');
    currentPage.value = 1;
    hasMore.value = true;
    await fetchOrders();
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoading.value) return;
    debugPrint('\n=== Loading More Orders ===');
    debugPrint('Current Page: ${currentPage.value}');
    currentPage.value++;
    await fetchOrders();
  }

  bool canProcessOrder(String status) {
    return status == 'PENDING' || status == 'PROCESSING';
  }

  Future<void> markAsReadyForPickup(String orderId) async {
    try {
      debugPrint('\n=== Marking Order as Ready for Pickup ===');
      debugPrint('Order ID: $orderId');

      final mId = await getMerchantId();
      if (mId == null) {
        throw Exception('Merchant ID not found');
      }

      final success = await _transactionService.updateOrderStatus(
        mId,
        orderId,
        action: 'readyForPickup',
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Order marked as ready for pickup',
          snackPosition: SnackPosition.BOTTOM,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        await refreshOrders();
      } else {
        throw Exception('Failed to mark order as ready for pickup');
      }
    } catch (e) {
      debugPrint('Error marking order as ready for pickup: $e');
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> processOrder(String orderId) async {
    try {
      debugPrint('\n=== Processing Order ===');
      debugPrint('Order ID: $orderId');

      final mId = await getMerchantId();
      if (mId == null) {
        throw Exception('Merchant ID not found');
      }

      final success = await _transactionService.updateOrderStatus(
        mId,
        orderId,
        action: 'process',
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Order successfully processed',
          snackPosition: SnackPosition.BOTTOM,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        await refreshOrders();
      } else {
        throw Exception('Failed to process order');
      }
    } catch (e) {
      debugPrint('Error processing order: $e');
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> rejectOrder(String orderId, String? reason) async {
    try {
      debugPrint('\n=== Rejecting Order ===');
      debugPrint('Order ID: $orderId');
      debugPrint('Reason: $reason');

      final mId = await getMerchantId();
      if (mId == null) {
        throw Exception('Merchant ID not found');
      }

      final success = await _transactionService.updateOrderStatus(
        mId,
        orderId,
        action: 'cancel',
        notes: reason,
      );

      if (success) {
        Get.snackbar(
          'Success',
          'Order rejected successfully',
          snackPosition: SnackPosition.BOTTOM,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        await refreshOrders();
      } else {
        throw Exception('Failed to reject order');
      }
    } catch (e) {
      debugPrint('Error rejecting order: $e');
      Get.snackbar('Error', e.toString());
    }
  }
}
