import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';

class OrderController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  late final TransactionService _transactionService;

  OrderController() {
    try {
      _transactionService = Get.find<TransactionService>();
      print('\n=== OrderController Debug ===');
      print(
          'TransactionService found with instance ID: ${_transactionService.hashCode}');
    } catch (e) {
      print('Failed to find TransactionService, creating new instance');
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
    print('\n=== OrderController onInit ===');
    print('Auth status: ${_authService.isLoggedIn.value}');

    if (_authService.isLoggedIn.value) {
      fetchTransactions(status: 'PENDING,PROCESSING,ON_DELIVERY');
    } else {
      print('User not logged in, skipping transaction fetch');
    }

    // Listen for auth state changes
    ever(_authService.isLoggedIn, (bool isLoggedIn) {
      if (isLoggedIn) {
        print('User logged in, fetching transactions');
        fetchTransactions(status: 'PENDING,PROCESSING,ON_DELIVERY');
      } else {
        print('User logged out, clearing transactions');
        transactions.clear();
      }
    });
  }

  Future<void> fetchTransactions({String? status}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _transactionService.getTransactions(
        status: status,
      );

      transactions.value = result;
    } catch (e) {
      print('Error fetching transactions: $e');
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

  List<TransactionModel> get activeOrders {
    return transactions
        .where((t) =>
            t.status.toUpperCase() == 'PENDING' ||
            t.status.toUpperCase() == 'PROCESSING' ||
            t.status.toUpperCase() == 'ON_DELIVERY')
        .toList();
  }

  List<TransactionModel> get historyOrders {
    return transactions
        .where((t) =>
            t.status.toUpperCase() == 'COMPLETED' ||
            t.status.toUpperCase() == 'CANCELED')
        .toList();
  }

  void onTabChanged(int index) async {
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
      isLoading.value = true;
      final success =
          await _transactionService.cancelTransaction(transactionId);

      if (success) {
        await fetchTransactions(
            status: currentTab.value == 0
                ? 'PENDING,PROCESSING,ON_DELIVERY'
                : 'COMPLETED,CANCELED');
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

  Future<void> refreshOrders() async {
    if (_authService.isLoggedIn.value) {
      await fetchTransactions(
          status: currentTab.value == 0
              ? 'PENDING,PROCESSING,ON_DELIVERY'
              : 'COMPLETED,CANCELED');
    }
  }
}
