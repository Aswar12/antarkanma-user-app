import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';

class OrderController extends GetxController {
  final TransactionService _transactionService = Get.find<TransactionService>();

  // Observable properties
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactions();
  }

  // Fetch all transactions/orders
  Future<void> fetchTransactions() async {
    try {
      isLoading.value = true;
      final result = await _transactionService.getTransactions();
      transactions.value = result;
    } catch (e) {
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

  // Get active orders (PENDING or PROCESSING)
  List<TransactionModel> get activeOrders {
    return transactions
        .where((transaction) =>
            transaction.status == 'PENDING' ||
            transaction.status == 'PROCESSING')
        .toList();
  }

  // Get completed orders
  List<TransactionModel> get completedOrders {
    return transactions
        .where((transaction) => transaction.status == 'COMPLETED')
        .toList();
  }

  // Get cancelled orders
  List<TransactionModel> get cancelledOrders {
    return transactions
        .where((transaction) => transaction.status == 'CANCELED')
        .toList();
  }

  // Cancel an order
  Future<void> cancelOrder(String transactionId) async {
    try {
      isLoading.value = true;
      final success =
          await _transactionService.cancelTransaction(transactionId);

      if (success) {
        await fetchTransactions(); // Refresh the list
        showCustomSnackbar(
          title: 'Sukses',
          message: 'Pesanan berhasil dibatalkan',
        );
      } else {
        throw Exception('Gagal membatalkan pesanan');
      }
    } catch (e) {
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

  // Get order details
  Future<TransactionModel?> getOrderDetails(String transactionId) async {
    try {
      isLoading.value = true;
      return await _transactionService.getTransactionById(transactionId);
    } catch (e) {
      errorMessage.value = e.toString();
      showCustomSnackbar(
        title: 'Error',
        message: 'Gagal memuat detail pesanan: ${e.toString()}',
        isError: true,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh orders
  Future<void> refreshOrders() async {
    await fetchTransactions();
  }
}
