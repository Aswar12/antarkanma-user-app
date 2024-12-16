// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/data/providers/transaction_provider.dart';

class TransactionService extends GetxService {
  final TransactionProvider _transactionProvider = TransactionProvider();

  Future<TransactionModel?> createTransaction(
      TransactionModel transaction) async {
    try {
      final response =
          await _transactionProvider.createTransaction(transaction.toJson());

      if (response.statusCode == 201) {
        // Parsing data transaksi dari response
        // Sesuaikan dengan struktur response backend Anda
        final createdTransaction =
            TransactionModel.fromJson(response.data['data'] ?? response.data);

        return createdTransaction;
      }

      // Log error jika status code bukan 201
      print(
          'Failed to create transaction. Status code: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error creating transaction: $e');
      return null;
    }
  }

  Future<List<TransactionModel>> getTransactions() async {
    try {
      final response = await _transactionProvider.getTransactions();
      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            response.data['data']; // Mengambil data dari response
        return jsonList.map((json) => TransactionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  Future<TransactionModel?> getTransactionById(String transactionId) async {
    try {
      final response =
          await _transactionProvider.getTransactionById(transactionId);
      if (response.statusCode == 200) {
        return TransactionModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      print('Error getting transaction by ID: $e');
      return null;
    }
  }

  Future<bool> updateTransaction(
      String transactionId, Map<String, dynamic> updateData) async {
    try {
      final response = await _transactionProvider.updateTransaction(
          transactionId, updateData);
      return response.statusCode == 200; // HTTP 200 OK
    } catch (e) {
      print('Error updating transaction: $e');
      return false;
    }
  }

  Future<bool> cancelTransaction(String transactionId) async {
    try {
      final response =
          await _transactionProvider.cancelTransaction(transactionId);
      return response.statusCode == 200; // HTTP 200 OK
    } catch (e) {
      print('Error canceling transaction: $e');
      return false;
    }
  }

  Future<List<TransactionModel>> getTransactionsByMerchant(
      String merchantId) async {
    try {
      final response =
          await _transactionProvider.getTransactionsByMerchant(merchantId);
      if (response.statusCode == 200) {
        final List<dynamic> jsonList =
            response.data['data']; // Mengambil data dari response
        return jsonList.map((json) => TransactionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting transactions by merchant: $e');
      return [];
    }
  }
}
