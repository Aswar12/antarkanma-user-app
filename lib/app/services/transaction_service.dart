import 'package:get/get.dart';
import '../data/providers/transaction_provider.dart';
import '../data/models/transaction_model.dart';
import '../data/models/order_item_model.dart';
import '../widgets/custom_snackbar.dart';
import 'package:flutter/foundation.dart';

class TransactionService extends GetxService {
  final TransactionProvider _transactionProvider = TransactionProvider();

  Future<TransactionModel?> createTransaction(
      Map<String, dynamic> transactionData) async {
    try {
      debugPrint('\n=== TransactionService: Creating Transaction ===');
      debugPrint('Transaction Data: $transactionData');

      final response =
          await _transactionProvider.createTransaction(transactionData);
      debugPrint('\n=== TransactionService: Response Received ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData != null &&
            responseData['meta']?['status'] == 'success') {
          try {
            final transactionJson = responseData['data'];
            debugPrint(
                '\n=== TransactionService: Creating TransactionModel ===');
            debugPrint('Transaction JSON: $transactionJson');

            if (transactionJson == null) {
              throw Exception('Transaction data is null');
            }

            final transaction = TransactionModel.fromJson(transactionJson);
            debugPrint('\n=== TransactionService: Transaction Created ===');
            debugPrint('Transaction ID: ${transaction.id}');
            debugPrint('Order ID: ${transaction.orderId}');
            debugPrint('Total Price: ${transaction.totalPrice}');
            debugPrint('Items Count: ${transaction.items.length}');

            return transaction;
          } catch (parseError, stackTrace) {
            debugPrint('\n=== Error Parsing Transaction Data ===');
            debugPrint('Parse Error: $parseError');
            debugPrint('Stack Trace: $stackTrace');
            debugPrint('Raw Data: ${responseData['data']}');

            CustomSnackbarX.showError(
              title: 'Error',
              message: 'Terjadi kesalahan saat memproses data transaksi',
              position: SnackPosition.BOTTOM,
            );
            return null;
          }
        } else {
          final message =
              responseData?['meta']?['message'] ?? 'Gagal membuat transaksi';
          CustomSnackbarX.showError(
            title: 'Error',
            message: message,
            position: SnackPosition.BOTTOM,
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('\n=== TransactionService: Error Creating Transaction ===');
      debugPrint('Error: $e');
      CustomSnackbarX.showError(
        title: 'Error',
        message: 'Gagal membuat transaksi: $e',
        position: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<List<TransactionModel>> getTransactions({
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final response = await _transactionProvider.getTransactions(
        status: status,
        page: page,
        pageSize: pageSize,
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final List<dynamic> transactionsData = response.data['data'];
        debugPrint('\n=== Getting Transactions ===');
        debugPrint('Found ${transactionsData.length} transactions');

        final transactions = transactionsData
            .map((json) {
              try {
                return TransactionModel.fromJson(json);
              } catch (e, stackTrace) {
                debugPrint('Error parsing transaction: $e');
                debugPrint('Stack trace: $stackTrace');
                debugPrint('JSON data: $json');
                return null;
              }
            })
            .where((t) => t != null)
            .cast<TransactionModel>()
            .toList();

        debugPrint('Successfully parsed ${transactions.length} transactions');
        return transactions;
      }
      return [];
    } catch (e) {
      debugPrint('Error getting transactions: $e');
      return [];
    }
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      final response = await _transactionProvider.getTransactionById(id);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final transactionJson = response.data['data'];
        debugPrint('\n=== Getting Transaction By ID ===');
        debugPrint('Transaction data: $transactionJson');

        final transaction = TransactionModel.fromJson(transactionJson);
        debugPrint('Successfully parsed transaction ${transaction.id}');
        return transaction;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting transaction: $e');
      return null;
    }
  }

  Future<bool> cancelTransaction(String transactionId) async {
    try {
      debugPrint('\n=== TransactionService: Canceling Transaction ===');
      debugPrint('Transaction ID: $transactionId');

      final response =
          await _transactionProvider.cancelTransaction(transactionId);

      if (response.statusCode == 200) {
        debugPrint('Successfully canceled transaction');
        return true;
      }

      final message =
          response.data?['meta']?['message'] ?? 'Failed to cancel transaction';
      CustomSnackbarX.showError(
        title: 'Error',
        message: message,
        position: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      debugPrint('Error canceling transaction: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getTransactionsByMerchant(
    String merchantId, {
    int? page = 1,
    int? limit = 10,
    String? status,
  }) async {
    try {
      debugPrint('\n=== Getting Merchant Orders ===');
      debugPrint('Merchant ID: $merchantId');
      debugPrint('Page: $page');
      debugPrint('Limit: $limit');
      debugPrint('Status Filter: $status');

      final response = await _transactionProvider.getTransactionsByMerchant(
        merchantId,
        page: page ?? 1,
        limit: limit ?? 10,
        status: status,
      );

      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');

      if (response.statusCode == 200 &&
          response.data['meta']?['status'] == 'success') {
        final data = response.data['data'];
        if (data != null) {
          final transactions = data['transactions'];

          // Handle status_counts as List or Map
          final defaultCounts = {
            OrderItemStatus.pending: 0,
            OrderItemStatus.processing: 0,
            OrderItemStatus.readyForPickup: 0,
            OrderItemStatus.completed: 0,
            OrderItemStatus.canceled: 0,
          };

          Map<String, int> mergedStatusCounts =
              Map<String, int>.from(defaultCounts);

          // Get status_counts from response
          final statusCountsData = data['status_counts'];
          if (statusCountsData != null) {
            if (statusCountsData is List) {
              // If it's a list, process each item
              for (var item in statusCountsData) {
                if (item is Map) {
                  String? status = item['status']?.toString().toUpperCase();
                  int count =
                      item['count'] is num ? (item['count'] as num).toInt() : 0;
                  if (status != null && defaultCounts.containsKey(status)) {
                    mergedStatusCounts[status] = count;
                  }
                }
              }
            } else if (statusCountsData is Map) {
              // If it's a map, process directly
              statusCountsData.forEach((key, value) {
                String status = key.toString().toUpperCase();
                if (defaultCounts.containsKey(status)) {
                  mergedStatusCounts[status] = value is num ? value.toInt() : 0;
                }
              });
            }
          }

          debugPrint('\n=== Status Counts ===');
          mergedStatusCounts.forEach((key, value) {
            debugPrint('$key: $value');
          });

          return {
            'transactions': transactions,
            'status_counts': mergedStatusCounts,
          };
        }
      }

      debugPrint('Failed to get merchant orders');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('Error getting merchant orders: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTransactionSummaryByMerchant(
      String merchantId) async {
    try {
      final response = await _transactionProvider
          .getTransactionSummaryByMerchant(merchantId);
      debugPrint('\n=== Getting Transaction Summary ===');
      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');

      if (response.statusCode == 200 &&
          response.data['meta']?['status'] == 'success') {
        final data = response.data['data'];
        if (data != null) {
          final statistics = data['statistics'] ?? {};
          final ordersData = data['orders'] ?? {};

          return {
            'statistics': {
              'total_orders': statistics['total_orders'] ?? 0,
              'pending_orders': statistics['pending_orders'] ?? 0,
              'processing_orders': statistics['processing_orders'] ?? 0,
              'readytopickup_orders': statistics['readytopickup_orders'] ?? 0,
              'completed_orders': statistics['completed_orders'] ?? 0,
              'canceled_orders': statistics['canceled_orders'] ?? 0,
              'total_revenue':
                  (statistics['total_revenue'] as num?)?.toDouble() ?? 0.0,
            },
            'orders': {
              'pending': _parseOrdersList(ordersData['pending']),
              'processing': _parseOrdersList(ordersData['processing']),
              'readytopickup': _parseOrdersList(ordersData['readytopickup']),
              'completed': _parseOrdersList(ordersData['completed']),
              'canceled': _parseOrdersList(ordersData['canceled']),
            },
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting transaction summary: $e');
      return null;
    }
  }

  List<TransactionModel> _parseOrdersList(List<dynamic>? ordersList) {
    if (ordersList == null) return [];
    return ordersList
        .map((json) {
          try {
            return TransactionModel.fromJson(json);
          } catch (e) {
            debugPrint('Error parsing order in summary: $e');
            debugPrint('Order JSON: $json');
            return null;
          }
        })
        .where((order) => order != null)
        .cast<TransactionModel>()
        .toList();
  }

  Future<bool> updateOrderStatus(
    String merchantId,
    String orderId, {
    required String action,
    String? notes,
  }) async {
    try {
      debugPrint('\n=== Updating Order Status ===');
      debugPrint('Merchant ID: $merchantId');
      debugPrint('Order ID: $orderId');
      debugPrint('Action: $action');
      if (notes != null) debugPrint('Notes: $notes');

      final response = await _transactionProvider.updateOrderStatus(
        orderId,
        action,
        notes: notes,
      );

      if (response.statusCode == 200 &&
          response.data['meta']?['status'] == 'success') {
        debugPrint('Successfully updated order status');
        CustomSnackbarX.showSuccess(
          title: 'Success',
          message: response.data['meta']?['message'] ??
              'Status pesanan berhasil diperbarui',
          position: SnackPosition.BOTTOM,
        );
        return true;
      }

      debugPrint('Failed to update order status');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');

      CustomSnackbarX.showError(
        title: 'Error',
        message: response.data['meta']?['message'] ??
            'Gagal memperbarui status pesanan',
        position: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      CustomSnackbarX.showError(
        title: 'Error',
        message: 'Gagal memperbarui status pesanan',
        position: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
