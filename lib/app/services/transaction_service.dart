import 'package:get/get.dart';
import '../data/providers/transaction_provider.dart';
import '../data/models/transaction_model.dart';
import '../widgets/custom_snackbar.dart';
import 'package:flutter/foundation.dart';

class TransactionService extends GetxService {
  final TransactionProvider _transactionProvider = TransactionProvider();

  Future<TransactionModel?> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      debugPrint('\n=== TransactionService: Creating Transaction ===');
      debugPrint('Transaction Data: $transactionData');

      final response = await _transactionProvider.createTransaction(transactionData);
      debugPrint('\n=== TransactionService: Response Received ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData != null && responseData['meta']?['status'] == 'success') {
          try {
            // Extract transaction data from the response
            final transactionJson = responseData['data'];
            debugPrint('\n=== TransactionService: Creating TransactionModel ===');
            debugPrint('Transaction JSON: $transactionJson');

            // Verify required fields are present
            if (transactionJson == null) {
              throw Exception('Transaction data is null');
            }

            // Log the items data specifically
            if (transactionJson['items'] != null) {
              debugPrint('\n=== Transaction Items Data ===');
              debugPrint('Items: ${transactionJson['items']}');
            } else {
              debugPrint('Warning: No items data in response');
            }

            // Create TransactionModel from the response
            final transaction = TransactionModel.fromJson(transactionJson);
            debugPrint('\n=== TransactionService: Transaction Created ===');
            debugPrint('Transaction ID: ${transaction.id}');
            debugPrint('Order ID: ${transaction.orderId}');
            debugPrint('Total Price: ${transaction.totalPrice}');
            debugPrint('Items Count: ${transaction.items.length}');
            debugPrint('Items Details:');
            for (var item in transaction.items) {
              debugPrint('- Product: ${item.product.name}');
              debugPrint('  Quantity: ${item.quantity}');
              debugPrint('  Price: ${item.price}');
              debugPrint('  Merchant: ${item.merchant.name}');
              debugPrint('  Images: ${item.product.galleries}');
            }

            // Verify the transaction data is complete
            if (transaction.items.isEmpty) {
              debugPrint('Warning: Transaction created but has no items');
            }

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
          final message = responseData?['meta']?['message'] ?? 'Gagal membuat transaksi';
          CustomSnackbarX.showError(
            title: 'Error',
            message: message,
            position: SnackPosition.BOTTOM,
          );
        }
      }

      if (response.statusCode == 422) {
        final data = response.data;
        if (data != null && data['data'] != null) {
          final errors = data['data'] as Map<String, dynamic>;
          final errorMessages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else {
              errorMessages.add(value.toString());
            }
          });
          CustomSnackbarX.showError(
            title: 'Error',
            message: errorMessages.join('\n'),
            position: SnackPosition.BOTTOM,
          );
        }
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('\n=== TransactionService: Error Creating Transaction ===');
      debugPrint('Error: $e');
      debugPrint('Stack Trace: $stackTrace');
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
        
        final transactions = transactionsData.map((json) {
          try {
            return TransactionModel.fromJson(json);
          } catch (e, stackTrace) {
            debugPrint('Error parsing transaction: $e');
            debugPrint('Stack trace: $stackTrace');
            debugPrint('JSON data: $json');
            return null;
          }
        }).where((t) => t != null).cast<TransactionModel>().toList();

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

  Future<bool> cancelTransaction(String id) async {
    try {
      final response = await _transactionProvider.cancelTransaction(id);
      return response.statusCode == 200;
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
      final response = await _transactionProvider.getTransactionsByMerchant(
        merchantId,
        page: page ?? 1,
        limit: limit ?? 10,
        status: status,
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting merchant transactions: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTransactionSummaryByMerchant(
    String merchantId,
  ) async {
    try {
      final response = await _transactionProvider.getTransactionSummaryByMerchant(merchantId);
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting transaction summary: $e');
      return null;
    }
  }

  Future<bool> updateOrderStatus(
    String merchantId,
    String orderId, {
    required String status,
    String? notes,
  }) async {
    try {
      final response = await _transactionProvider.updateOrderStatus(
        merchantId,
        orderId,
        status: status,
        notes: notes,
      );

      if (response.statusCode == 200) {
        CustomSnackbarX.showSuccess(
          title: 'Success',
          message: 'Status pesanan berhasil diperbarui',
          position: SnackPosition.BOTTOM,
        );
        return true;
      } else if (response.statusCode == 422) {
        final data = response.data;
        if (data != null && data['data'] != null) {
          final errors = data['data'] as Map<String, dynamic>;
          final errorMessages = <String>[];
          errors.forEach((key, value) {
            if (value is List) {
              errorMessages.addAll(value.map((e) => e.toString()));
            } else {
              errorMessages.add(value.toString());
            }
          });
          CustomSnackbarX.showError(
            title: 'Error',
            message: errorMessages.join('\n'),
            position: SnackPosition.BOTTOM,
          );
        }
      }
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
