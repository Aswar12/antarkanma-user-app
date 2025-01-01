// ignore_for_file: unused_element, avoid_print

import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/modules/user/views/payment_method_selection_page.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/order_item_model.dart';
import 'package:antarkanma/app/data/models/cart_item_model.dart';
import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'user_location_controller.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';

class CheckoutController extends GetxController {
  final UserLocationController userLocationController;
  final AuthController authController;

  CheckoutController({
    required this.userLocationController,
    required this.authController,
  });

  // Observable properties
  final isLoading = false.obs;
  final orderItems = <OrderItemModel>[].obs;
  final selectedLocation = Rx<UserLocationModel?>(null);
  final selectedPaymentMethod = Rx<String?>(null);
  final subtotal = 0.0.obs;
  final deliveryFee = 0.0.obs;
  final total = 0.0.obs;
  final createdTransactions = <TransactionModel>[].obs;

  final List<String> paymentMethods = [
    'COD',
  ];

  @override
  void onInit() {
    super.onInit();
    _initializeCheckoutLocation();
    _initializeCheckout();
    ever(userLocationController.selectedLocation, (location) {
      if (location != null) {
        setDeliveryLocation(location);
      }
    });
  }

  void _initializeCheckoutLocation() {
    final selectedLocation = userLocationController.selectedLocation.value;
    final defaultLocation = userLocationController.defaultAddress;
    final firstLocation = userLocationController.userLocations.isNotEmpty
        ? userLocationController.userLocations.first
        : null;

    UserLocationModel? priorityLocation;

    if (selectedLocation != null) {
      priorityLocation = selectedLocation;
    } else if (defaultLocation != null) {
      priorityLocation = defaultLocation;
    } else if (firstLocation != null) {
      priorityLocation = firstLocation;
    }

    if (priorityLocation != null) {
      this.selectedLocation.value = priorityLocation;
      userLocationController.setSelectedLocation(priorityLocation);
    }
  }

  void setDeliveryLocation(UserLocationModel location) {
    selectedLocation.value = location;
    userLocationController.setSelectedLocation(location);
    _calculateTotals();
    update();
  }

  void updateSelectedLocation(UserLocationModel location) {
    setDeliveryLocation(location);
  }

  List<UserLocationModel> get availableLocations {
    return userLocationController.userLocations;
  }

  Future<bool> addNewLocation(UserLocationModel newLocation) async {
    final result = await userLocationController.addAddress(newLocation);
    if (result) {
      setDeliveryLocation(newLocation);
    }
    return result;
  }

  bool get canCheckout {
    return selectedLocation.value != null &&
        orderItems.isNotEmpty &&
        selectedPaymentMethod.value != null;
  }

  String? get checkoutBlockReason {
    if (selectedLocation.value == null) {
      return 'Pilih alamat pengiriman';
    }
    return null;
  }

  void _initializeCheckout() {
    try {
      final args = Get.arguments;
      if (args != null && args['merchantItems'] != null) {
        final merchantItems =
            args['merchantItems'] as Map<int, List<CartItemModel>>;

        // Group items by merchant to ensure proper association
        final List<OrderItemModel> allItems = [];
        merchantItems.forEach((merchantId, items) {
          for (var cartItem in items) {
            if (cartItem.merchant.id == merchantId) {
              allItems.add(OrderItemModel.fromCartItem(
                cartItem,
                DateTime.now().millisecondsSinceEpoch.toString(),
              ));
            }
          }
        });

        orderItems.value = allItems;
        _calculateTotals();
      }
    } catch (e) {
      _handleInitializationError(e);
    }
  }

  void _handleInitializationError(dynamic error) {
    print('Error initializing checkout: $error');
    showCustomSnackbar(
      title: 'Error',
      message: 'Terjadi kesalahan saat memuat data checkout',
      isError: true,
    );
  }

  void _calculateTotals() {
    subtotal.value = orderItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    deliveryFee.value = _calculateDeliveryFee();
    total.value = subtotal.value + deliveryFee.value;
  }

  double _calculateDeliveryFee() {
    if (orderItems.isEmpty) return 0.0;
    return 10000.0;
  }

  Future<void> processCheckout() async {
    isLoading.value = true;
    createdTransactions.clear();

    try {
      if (!_validateCheckoutData()) {
        isLoading.value = false;
        return;
      }

      final merchantGroups = _groupItemsByMerchant();
      final transactionService = Get.find<TransactionService>();
      
      // Create transactions for each merchant
      for (var entry in merchantGroups.entries) {
        final merchantId = entry.key;
        final merchantItems = entry.value;
        
        // Calculate merchant-specific totals
        final merchantSubtotal = merchantItems.fold(
          0.0,
          (sum, item) => sum + (item.price * item.quantity),
        );
        final merchantDeliveryFee = _calculateDeliveryFee();
        
        // Create transaction for this merchant
        final merchantTransaction = _createTransactionModelForMerchant(
          merchantId,
          merchantItems,
          merchantSubtotal,
          merchantDeliveryFee,
        );

        // Create transaction in backend
        final createdTransaction = await transactionService.createTransaction(merchantTransaction);
        if (createdTransaction != null) {
          createdTransactions.add(createdTransaction);
        }
      }

      if (createdTransactions.isNotEmpty) {
        _clearCart();
        _navigateToSuccessPage(createdTransactions.first); // Navigate with first transaction
      }
    } catch (e) {
      _handleCheckoutError(e);
    } finally {
      isLoading.value = false;
    }
  }

  TransactionModel _createTransactionModelForMerchant(
    int merchantId,
    List<OrderItemModel> merchantItems,
    double subtotal,
    double deliveryFee,
  ) {
    if (selectedLocation.value == null) {
      throw Exception('Lokasi pengiriman belum dipilih');
    }

    if (selectedPaymentMethod.value == null) {
      throw Exception('Metode pembayaran belum dipilih');
    }

    final authService = Get.find<AuthService>();
    final userId = authService.userId;

    if (userId == null) {
      throw Exception('Pengguna tidak terautentikasi');
    }

    return TransactionModel(
      userId: userId,
      userLocationId: selectedLocation.value!.id ?? 0,
      totalPrice: subtotal,
      shippingPrice: deliveryFee,
      paymentMethod: _mapPaymentMethod(selectedPaymentMethod.value!),
      status: 'PENDING',
      paymentStatus: 'PENDING',
      items: merchantItems,
    );
  }

  String _mapPaymentMethod(String method) {
    switch (method) {
      case 'COD':
        return 'MANUAL';
      case 'Transfer Bank':
      case 'DANA':
      case 'OVO':
      case 'GoPay':
        return 'ONLINE';
      default:
        return 'MANUAL';
    }
  }

  bool _validateCheckoutData() {
    final validationErrors = <String>[];

    if (orderItems.isEmpty) {
      validationErrors.add('Keranjang belanja kosong');
    }

    if (selectedLocation.value == null) {
      validationErrors.add('Pilih alamat pengiriman');
    }

    if (selectedPaymentMethod.value == null) {
      validationErrors.add('Pilih metode pembayaran');
    }

    // Validate merchant IDs
    final invalidItems = orderItems.where((item) => item.merchant.id <= 0);
    if (invalidItems.isNotEmpty) {
      validationErrors.add('Terdapat item dengan merchant tidak valid');
    }

    // Validate each item
    for (var item in orderItems) {
      if (!item.validate()) {
        validationErrors.add('Item pesanan tidak valid');
        break;
      }
    }

    if (validationErrors.isNotEmpty) {
      _showValidationErrorSnackbar(validationErrors);
      return false;
    }

    return true;
  }

  void _navigateToSuccessPage(TransactionModel transaction) {
    Get.offNamed(Routes.checkoutSuccess, arguments: {
      'transaction': transaction,
      'orderItems': orderItems.toList(),
      'total': total.value,
      'deliveryAddress': selectedLocation.value!,
      'allTransactions': createdTransactions, // Add all transactions to arguments
    });
  }

  void _handleCheckoutError(dynamic error) {
    print('Checkout error: $error');
    String errorMessage = _getErrorMessage(error);
    showCustomSnackbar(
      title: 'Error',
      message: 'Gagal memproses checkout: $errorMessage',
      isError: true,
    );
  }

  Map<int, List<OrderItemModel>> _groupItemsByMerchant() {
    final Map<int, List<OrderItemModel>> merchantGroups = {};
    for (var item in orderItems) {
      final merchantId = item.merchant.id;
      if (merchantId > 0) {
        // Only group items with valid merchant IDs
        if (!merchantGroups.containsKey(merchantId)) {
          merchantGroups[merchantId] = [];
        }
        merchantGroups[merchantId]!.add(item);
      }
    }
    return merchantGroups;
  }

  void _showValidationErrorSnackbar(List<String> errors) {
    showCustomSnackbar(
      title: 'Validasi Gagal',
      message: errors.join('\n'),
      isError: true,
    );
  }

  String _getErrorMessage(dynamic error) {
    if (error is String) return error;
    if (error is Exception) return error.toString();
    return 'Terjadi kesalahan tidak dikenal';
  }

  void _clearCart() {
    try {
      Get.find<CartController>().clearCart();
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  void setPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
    update();
  }

  void autoSetInitialValues() {
    if (selectedLocation.value == null) {
      _initializeCheckoutLocation();
    }

    if (selectedPaymentMethod.value == null && paymentMethods.isNotEmpty) {
      setPaymentMethod(paymentMethods.first);
    }

    update();
  }

  void showPaymentMethodModal() async {
    final result = await Get.to(() => const PaymentMethodSelectionPage());
    if (result != null && result is String) {
      setPaymentMethod(result);
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
