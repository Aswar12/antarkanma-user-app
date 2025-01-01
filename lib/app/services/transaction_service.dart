import 'package:get/get.dart';
import '../data/providers/transaction_provider.dart';
import '../data/models/transaction_model.dart';
import '../widgets/custom_snackbar.dart';

class TransactionService extends GetxService {
  final TransactionProvider _transactionProvider = TransactionProvider();

  Future<TransactionModel?> createTransaction(TransactionModel transaction) async {
    try {
      final response = await _transactionProvider.createTransaction(transaction.toJson());

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['meta']?['status'] == 'success') {
          return TransactionModel.fromJson(response.data['data']);
        } else {
          final message = response.data['meta']?['message'] ?? 'Gagal membuat transaksi';
          CustomSnackbarX.showError(
            title: 'Error',
            message: message,
            position: SnackPosition.BOTTOM,
          );
          return null;
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
    } catch (e) {
      print('Error creating transaction: $e');
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
        return transactionsData
            .map((json) => TransactionModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      final response = await _transactionProvider.getTransactionById(id);

      if (response.statusCode == 200) {
        return TransactionModel.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Error getting transaction: $e');
      return null;
    }
  }

  Future<bool> cancelTransaction(String id) async {
    try {
      final response = await _transactionProvider.cancelTransaction(id);
      return response.statusCode == 200;
    } catch (e) {
      print('Error canceling transaction: $e');
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
      print('Error getting merchant transactions: $e');
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
      print('Error getting transaction summary: $e');
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
      print('Error updating order status: $e');
      CustomSnackbarX.showError(
        title: 'Error',
        message: 'Gagal memperbarui status pesanan',
        position: SnackPosition.BOTTOM,
      );
      return false;
    }
  }
}
