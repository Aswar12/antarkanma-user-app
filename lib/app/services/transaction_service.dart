// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/data/providers/transaction_provider.dart';
import 'package:antarkanma/app/services/storage_service.dart';

class TransactionService extends GetxService {
  final TransactionProvider _transactionProvider = TransactionProvider();
  final StorageService _storageService = StorageService.instance;

  Future<List<TransactionModel>> getTransactions({String? status}) async {
    try {
      print('\n=== Transaction Service Debug ===');
      print('Fetching transactions with status: $status');
      print('Token: ${_storageService.getToken()}');

      final response = await _transactionProvider.getTransactions(
        status: status,
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;

        if (responseData['meta']?['status'] == 'success') {
          // The data is nested in data.data due to pagination structure
          final paginationData = responseData['data'];
          if (paginationData != null && paginationData['data'] is List) {
            final transactionsList = paginationData['data'] as List;
            print('Found ${transactionsList.length} transactions');

            return transactionsList
                .map((json) => TransactionModel.fromJson(json))
                .toList();
          } else {
            print('No transactions found in response');
          }
        } else {
          print('Response meta status is not success');
        }
      } else {
        print('Response status code is not 200');
      }

      return [];
    } catch (e) {
      print('Error getting transactions: $e');
      if (e.toString().contains('401')) {
        throw Exception('Sesi anda telah berakhir. Silakan login kembali.');
      } else if (e.toString().contains('404')) {
        throw Exception('Data pesanan tidak ditemukan.');
      } else if (e.toString().contains('500')) {
        throw Exception(
            'Terjadi kesalahan pada server. Silakan coba lagi nanti.');
      }
      throw Exception('Gagal memuat pesanan: ${e.toString()}');
    }
  }

  Future<TransactionModel?> createTransaction(
      TransactionModel transaction) async {
    try {
      final transactionData = transaction.toCheckoutPayload();
      print('Creating transaction with data: $transactionData');

      final response =
          await _transactionProvider.createTransaction(transactionData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData['meta']?['status'] == 'success') {
          return TransactionModel.fromJson(responseData['data']);
        }
      }

      throw Exception(
          response.data['meta']?['message'] ?? 'Failed to create transaction');
    } catch (e) {
      print('Error creating transaction: $e');
      rethrow;
    }
  }

  Future<TransactionModel?> getTransactionById(String transactionId) async {
    try {
      final response =
          await _transactionProvider.getTransactionById(transactionId);

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['meta']?['status'] == 'success') {
          return TransactionModel.fromJson(responseData['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting transaction by ID: $e');
      rethrow;
    }
  }

  Future<bool> cancelTransaction(String transactionId) async {
    try {
      final response =
          await _transactionProvider.cancelTransaction(transactionId);
      return response.statusCode == 200;
    } catch (e) {
      print('Error canceling transaction: $e');
      if (e.toString().contains('404')) {
        throw Exception('Pesanan tidak ditemukan.');
      } else if (e.toString().contains('403')) {
        throw Exception(
            'Anda tidak memiliki izin untuk membatalkan pesanan ini.');
      }
      throw Exception('Gagal membatalkan pesanan: ${e.toString()}');
    }
  }

  Future<List<TransactionModel>> getTransactionsByMerchant(
      String merchantId) async {
    try {
      final response =
          await _transactionProvider.getTransactionsByMerchant(merchantId);

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['meta']?['status'] == 'success') {
          final data = responseData['data'];

          if (data is List) {
            return data.map((json) => TransactionModel.fromJson(json)).toList();
          } else if (data is Map && data['data'] is List) {
            return (data['data'] as List)
                .map((json) => TransactionModel.fromJson(json))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      print('Error getting merchant transactions: $e');
      return [];
    }
  }
}
