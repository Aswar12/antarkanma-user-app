import 'package:antarkanma/app/services/storage_service.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:flutter/foundation.dart';

class OrderController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  late final TransactionService _transactionService;

  OrderController() {
    try {
      _transactionService = Get.find<TransactionService>();
      debugPrint('\n=== OrderController Debug ===');
      debugPrint('TransactionService found with instance ID: ${_transactionService.hashCode}');
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
      fetchTransactions(status: 'PENDING,PROCESSING,ON_DELIVERY');
    } else {
      debugPrint('User not logged in, skipping transaction fetch');
    }

    // Listen for auth state changes
    ever(_authService.isLoggedIn, (bool isLoggedIn) {
      if (isLoggedIn) {
        debugPrint('User logged in, fetching transactions');
        fetchTransactions(status: 'PENDING,PROCESSING,ON_DELIVERY');
      } else {
        debugPrint('User logged out, clearing transactions');
        transactions.clear();
      }
    });
  }

  final _storageService = StorageService.instance;

  Future<void> fetchTransactions({String? status}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      debugPrint('\n=== Fetching Transactions ===');
      debugPrint('Status filter: $status');

      // Load from cache first
      final cachedOrders = _storageService.getOrders();
      if (cachedOrders != null) {
        debugPrint('\n=== Loading from Cache ===');
        debugPrint('Cached orders count: ${cachedOrders.length}');
        
        try {
          final cachedTransactions = cachedOrders.map((json) {
            debugPrint('\nParsing cached transaction:');
            debugPrint('JSON: $json');
            
            final transaction = TransactionModel.fromJson(json);
            debugPrint('Parsed transaction ID: ${transaction.id}');
            debugPrint('Items count: ${transaction.items.length}');
            
            // Log items details
            for (var item in transaction.items) {
              debugPrint('\nItem details:');
              debugPrint('Product name: ${item.product.name}');
              debugPrint('Product ID: ${item.product.id}');
              debugPrint('Quantity: ${item.quantity}');
              debugPrint('Price: ${item.price}');
              debugPrint('Merchant name: ${item.merchant.name}');
              debugPrint('Product images: ${item.product.galleries}');
            }
            
            return transaction;
          }).toList();

          transactions.value = cachedTransactions;
          debugPrint('Successfully loaded ${cachedTransactions.length} transactions from cache');
        } catch (e, stackTrace) {
          debugPrint('Error parsing cached transactions: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      }

      // Then fetch from API
      debugPrint('\n=== Fetching from API ===');
      final result = await _transactionService.getTransactions(
        status: status,
      );

      debugPrint('\n=== API Response ===');
      debugPrint('Fetched ${result.length} transactions');

      // Log details of fetched transactions
      for (var transaction in result) {
        debugPrint('\nTransaction ID: ${transaction.id}');
        debugPrint('Status: ${transaction.status}');
        debugPrint('Items count: ${transaction.items.length}');
        
        for (var item in transaction.items) {
          debugPrint('\nItem details:');
          debugPrint('Product name: ${item.product.name}');
          debugPrint('Product ID: ${item.product.id}');
          debugPrint('Quantity: ${item.quantity}');
          debugPrint('Price: ${item.price}');
          debugPrint('Merchant name: ${item.merchant.name}');
          debugPrint('Product images: ${item.product.galleries}');
        }
      }

      // Update cache and state
      final transactionsJson = result.map((t) => t.toJson()).toList();
      debugPrint('\n=== Saving to Cache ===');
      debugPrint('Saving ${transactionsJson.length} transactions');
      
      await _storageService.saveOrders(transactionsJson);
      transactions.value = result;
      
      debugPrint('Successfully updated transactions');
    } catch (e, stackTrace) {
      debugPrint('Error fetching transactions: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage.value = e.toString();
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal memuat pesanan: ${e.toString()}',
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void setTransactionData(TransactionModel transaction) {
    transactions.add(transaction);
    update();
    // Optionally refresh the orders to ensure the latest data is displayed
    refreshOrders();
  }

  List<TransactionModel> get activeOrders {
    final active = transactions
        .where((t) =>
            t.status.toUpperCase() == 'PENDING' ||
            t.status.toUpperCase() == 'PROCESSING' ||
            t.status.toUpperCase() == 'ON_DELIVERY')
        .toList();
    
    debugPrint('\n=== Active Orders ===');
    debugPrint('Count: ${active.length}');
    for (var order in active) {
      debugPrint('ID: ${order.id}, Status: ${order.status}, Items: ${order.items.length}');
    }
    
    return active;
  }

  List<TransactionModel> get historyOrders {
    final history = transactions
        .where((t) =>
            t.status.toUpperCase() == 'COMPLETED' ||
            t.status.toUpperCase() == 'CANCELED')
        .toList();
    
    debugPrint('\n=== History Orders ===');
    debugPrint('Count: ${history.length}');
    for (var order in history) {
      debugPrint('ID: ${order.id}, Status: ${order.status}, Items: ${order.items.length}');
    }
    
    return history;
  }

  void onTabChanged(int index) async {
    debugPrint('\n=== Tab Changed ===');
    debugPrint('New index: $index');
    
    currentTab.value = index;
    errorMessage.value = '';

    if (index == 0) {
      await fetchTransactions(status: 'PENDING,PROCESSING,ON_DELIVERY');
    } else {
      await fetchTransactions(status: 'COMPLETED,CANCELED');
    }
  }

  Future<void> cancelOrder(String transactionId) async {
    try {
      debugPrint('\n=== Canceling Order ===');
      debugPrint('Transaction ID: $transactionId');
      
      isLoading.value = true;
      final success = await _transactionService.cancelTransaction(transactionId);

      if (success) {
        debugPrint('Successfully canceled order');
        
        // Update local state immediately
        final updatedTransactions = transactions.map((t) {
          if (t.id.toString() == transactionId) {
            return t.copyWith(status: 'CANCELED');
          }
          return t;
        }).toList();

        transactions.value = updatedTransactions;

        // Update cache
        await _storageService
            .saveOrders(updatedTransactions.map((t) => t.toJson()).toList());

        showCustomSnackbar(
          title: 'Sukses',
          message: 'Pesanan berhasil dibatalkan',
        );

        // Refresh the current tab
        await fetchTransactions(
            status: currentTab.value == 0
                ? 'PENDING,PROCESSING,ON_DELIVERY'
                : 'COMPLETED,CANCELED');
      } else {
        throw Exception('Gagal membatalkan pesanan');
      }
    } catch (e, stackTrace) {
      debugPrint('Error canceling order: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage.value = e.toString();
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal membatalkan pesanan: ${e.toString()}',
        isError: true,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshOrders() async {
    debugPrint('\n=== Refreshing Orders ===');
    if (_authService.isLoggedIn.value) {
      await fetchTransactions(
          status: currentTab.value == 0
              ? 'PENDING,PROCESSING,ON_DELIVERY'
              : 'COMPLETED,CANCELED');
    } else {
      debugPrint('User not logged in, skipping refresh');
    }
  }
}
