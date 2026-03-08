import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/services/transaction_service.dart';

class OrderRepository {
  final TransactionService _transactionService = Get.find<TransactionService>();

  /// Create a new order/transaction
  Future<TransactionModel?> createOrder(
      Map<String, dynamic> transactionData) async {
    try {
      return await _transactionService.createTransaction(transactionData);
    } catch (e) {
      debugPrint('❌ [OrderRepository] createOrder error: $e');
      rethrow;
    }
  }

  /// Get paginated list of orders with optional status filter
  Future<List<TransactionModel>> getOrders({
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      return await _transactionService.getTransactions(
        status: status,
        page: page,
        pageSize: pageSize,
      );
    } catch (e) {
      debugPrint('❌ [OrderRepository] getOrders error: $e');
      rethrow;
    }
  }

  /// Get a single order by ID
  Future<TransactionModel?> getOrderById(String id) async {
    try {
      return await _transactionService.getTransactionById(id);
    } catch (e) {
      debugPrint('❌ [OrderRepository] getOrderById error: $e');
      rethrow;
    }
  }

  /// Cancel an order
  Future<bool> cancelOrder(String transactionId) async {
    try {
      return await _transactionService.cancelTransaction(transactionId);
    } catch (e) {
      debugPrint('❌ [OrderRepository] cancelOrder error: $e');
      rethrow;
    }
  }
}
