import 'package:antarkanma/app/controllers/order_controller.dart';
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
import 'package:flutter/material.dart';

class CheckoutController extends GetxController {
  final UserLocationController userLocationController;
  final AuthController authController;

  CheckoutController({
    required this.userLocationController,
    required this.authController,
  });

  // Observable properties
  final isLoading = false.obs;
  final isProcessingCheckout = false.obs;
  final orderItems = <OrderItemModel>[].obs;
  final selectedLocation = Rx<UserLocationModel?>(null);
  final selectedPaymentMethod = Rx<String?>(null);
  final subtotal = 0.0.obs;
  final deliveryFee = 0.0.obs;
  final total = 0.0.obs;

  final List<String> paymentMethods = [
    'COD',
  ];

  @override
  void onInit() {
    super.onInit();
    _initializeCheckoutLocation();
    _initializeCheckout();
    // Set COD as default payment method
    setPaymentMethod('COD');
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
        selectedPaymentMethod.value != null &&
        !isProcessingCheckout.value;
  }

  String? get checkoutBlockReason {
    if (selectedLocation.value == null) {
      return 'Pilih alamat pengiriman';
    }
    if (orderItems.isEmpty) {
      return 'Keranjang belanja kosong';
    }
    if (selectedPaymentMethod.value == null) {
      return 'Pilih metode pembayaran';
    }
    if (isProcessingCheckout.value) {
      return 'Sedang memproses checkout...';
    }
    return null;
  }

  void _initializeCheckout() {
    try {
      final args = Get.arguments;
      if (args != null && args['merchantItems'] != null) {
        final merchantItems =
            args['merchantItems'] as Map<int, List<CartItemModel>>;

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
    // Calculate delivery fee per merchant
    final merchantIds = orderItems.map((item) => item.merchant.id).toSet();
    return merchantIds.length * 10000.0; // 10,000 per merchant
  }

  Future<void> processCheckout() async {
    if (isProcessingCheckout.value) {
      print('Checkout already in progress, ignoring duplicate request');
      return;
    }

    isProcessingCheckout.value = true;
    isLoading.value = true;

    try {
      print('Order Items before checkout: $orderItems'); // Debug statement

      if (!_validateCheckoutData()) {
        isLoading.value = false;
        isProcessingCheckout.value = false;
        return;
      }

      final transactionService = Get.find<TransactionService>();
      
      // Create a single transaction with all items
      final Map<String, dynamic> transactionPayload = {
        'user_location_id': selectedLocation.value!.id,
        'total_price': subtotal.value,
        'shipping_price': deliveryFee.value,
        'payment_method': _mapPaymentMethod(selectedPaymentMethod.value!),
        'items': orderItems.map((item) => {
          'product_id': item.product.id,
          'product': {
            'id': item.product.id,
            'name': item.product.name,
            'description': item.product.description,
            'price': item.product.price,
            'galleries': item.product.galleries,
            'category': item.product.category.toJson(),
          },
          'quantity': item.quantity,
          'price': item.price,
          'merchant': {
            'id': item.merchant.id,
            'name': item.merchant.name,
            'address': item.merchant.address,
            'phone_number': item.merchant.phoneNumber,
          },
        }).toList(),
      };

      print('Sending transaction payload: $transactionPayload');

      // Create single transaction
      final createdTransaction = await transactionService.createTransaction(transactionPayload);

      if (createdTransaction != null) {
        print('Transaction created successfully: ${createdTransaction.id}');
        _clearCart();
        _navigateToSuccessPage(createdTransaction);
        Get.find<OrderController>().setTransactionData(createdTransaction);
      } else {
        print('Failed to create transaction');
        showCustomSnackbar(
          title: 'Error',
          message: 'Gagal membuat transaksi',
          isError: true,
        );
      }
    } catch (e) {
      _handleCheckoutError(e);
    } finally {
      isLoading.value = false;
      isProcessingCheckout.value = false;
    }
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

  void _showValidationErrorSnackbar(List<String> errors) {
    Get.snackbar(
      'Validasi Gagal',
      errors.join('\n'),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.7),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _navigateToSuccessPage(TransactionModel transaction) {
    Get.offNamed(Routes.checkoutSuccess, arguments: {
      'allTransactions': [transaction],
      'orderItems': orderItems.toList(),
      'total': total.value,
      'deliveryAddress': selectedLocation.value!,
    });

    // Set the transaction in OrderController
    Get.find<OrderController>().setTransactionData(transaction);
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
