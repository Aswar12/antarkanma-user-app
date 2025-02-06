import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/modules/user/views/payment_method_selection_page.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:antarkanma/app/services/shipping_service.dart';
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
  final CartController cartController;
  final ShippingService shippingService;

  CheckoutController({
    required this.userLocationController,
    required this.authController,
    required this.cartController,
    required this.shippingService,
  });

  // Observable properties
  final isLoading = false.obs;
  final isProcessingCheckout = false.obs;
  final isCalculatingShipping = false.obs;
  final orderItems = <OrderItemModel>[].obs;
  final selectedLocation = Rx<UserLocationModel?>(null);
  final selectedPaymentMethod = Rx<String?>(null);
  final subtotal = 0.0.obs;
  final deliveryFee = 0.0.obs;
  final total = 0.0.obs;
  
  // New shipping preview state
  final shippingPreview = Rx<Map<int, Map<String, dynamic>>>({});
  final merchantItems = Rx<Map<int, List<OrderItemModel>>>({});

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

  void _initializeCheckout() {
    try {
      Map<int, List<CartItemModel>>? merchantCartItems;
      
      // Check if this is a direct purchase
      if (Get.arguments != null && Get.arguments is Map) {
        final args = Get.arguments as Map;
        if (args['type'] == 'direct_buy' && args['merchantItems'] != null) {
          merchantCartItems = args['merchantItems'] as Map<int, List<CartItemModel>>;
        }
      }

      // If not a direct purchase, get items from cart
      if (merchantCartItems == null) {
        final selectedItems = cartController.selectedItems;
        merchantCartItems = <int, List<CartItemModel>>{};
        for (var item in selectedItems) {
          final merchantId = item.merchant.id ?? 0;
          if (!merchantCartItems.containsKey(merchantId)) {
            merchantCartItems[merchantId] = [];
          }
          merchantCartItems[merchantId]!.add(item);
        }
      }

      // Convert cart items to order items and group by merchant
      final Map<int, List<OrderItemModel>> groupedItems = {};
      final List<OrderItemModel> allItems = [];
      
      merchantCartItems.forEach((merchantId, items) {
        final merchantOrderItems = items.map((cartItem) => OrderItemModel.fromCartItem(
          cartItem,
          DateTime.now().millisecondsSinceEpoch.toString(),
        )).toList();
        
        groupedItems[merchantId] = merchantOrderItems;
        allItems.addAll(merchantOrderItems);
      });

      merchantItems.value = groupedItems;
      orderItems.value = allItems;
      _calculateTotals();
    } catch (e) {
      _handleInitializationError(e);
    }
  }

  void _handleInitializationError(dynamic error) {
    debugPrint('Error initializing checkout: $error');
    showCustomSnackbar(
      title: 'Error',
      message: 'Terjadi kesalahan saat memuat data checkout',
      isError: true,
    );
  }

  Future<void> _calculateTotals() async {
    subtotal.value = orderItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    
    await _calculateShippingPreview();
    _updateDeliveryFee();
    total.value = subtotal.value + deliveryFee.value;
  }

  Future<void> _calculateShippingPreview() async {
    if (orderItems.isEmpty || selectedLocation.value == null) {
      shippingPreview.value = {};
      return;
    }

    isCalculatingShipping.value = true;
    try {
      final Map<int, Map<String, dynamic>> preview = {};
      
      // Calculate shipping for each merchant
      for (final entry in merchantItems.value.entries) {
        final merchantId = entry.key;
        
        if (selectedLocation.value?.id != null) {
          final shippingData = await shippingService.calculateShipping(
            userLocationId: selectedLocation.value!.id!,
            merchantId: merchantId,
          );

          if (shippingData != null) {
            preview[merchantId] = {
              'cost': (shippingData['delivery_cost'] as num).toDouble(),
              'distance': shippingData['distance'],
              'duration': shippingData['duration'],
              'destination': shippingData['destination'],
            };
          }
        }
      }

      shippingPreview.value = preview;
      debugPrint('Shipping preview calculated: $preview');
    } catch (e) {
      debugPrint('Error calculating shipping preview: $e');
      shippingPreview.value = {};
    } finally {
      isCalculatingShipping.value = false;
    }
  }

  void _updateDeliveryFee() {
    deliveryFee.value = shippingPreview.value.values
        .fold(0.0, (sum, preview) => sum + (preview['cost'] as double? ?? 0.0));
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

  Future<void> processCheckout() async {
    if (isProcessingCheckout.value) {
      debugPrint('Checkout already in progress, ignoring duplicate request');
      return;
    }

    isProcessingCheckout.value = true;
    isLoading.value = true;

    try {
      debugPrint('Order Items before checkout: ${orderItems.length}');

      if (!_validateCheckoutData()) {
        isLoading.value = false;
        isProcessingCheckout.value = false;
        return;
      }

      final transactionService = Get.find<TransactionService>();

      // Create transaction payload without shipping costs
      final Map<String, dynamic> transactionPayload = {
        'user_location_id': selectedLocation.value?.id,
        'payment_method': _mapPaymentMethod(selectedPaymentMethod.value ?? 'MANUAL'),
        'items': orderItems
            .map((item) => {
                  'product_id': item.product.id,
                  'quantity': item.quantity,
                })
            .toList(),
      };

      debugPrint('Sending transaction payload');

      // Create transaction
      final createdTransaction =
          await transactionService.createTransaction(transactionPayload);

      if (createdTransaction != null) {
        debugPrint('Transaction created successfully: ${createdTransaction.id}');
        _clearCart();
        _navigateToSuccessPage(createdTransaction);
        Get.find<OrderController>().setTransactionData(createdTransaction);
      } else {
        debugPrint('Failed to create transaction');
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
    final invalidItems =
        orderItems.where((item) => (item.merchant.id ?? 0) <= 0);
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
      'subtotal': subtotal.value,
      'shippingFee': deliveryFee.value,
      'total': total.value,
      'deliveryAddress': selectedLocation.value,
    });

    // Set the transaction in OrderController
    Get.find<OrderController>().setTransactionData(transaction);
  }

  void _handleCheckoutError(dynamic error) {
    debugPrint('Checkout error: $error');
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
      // Only clear cart if not a direct purchase
      if (Get.arguments == null || (Get.arguments as Map)['type'] != 'direct_buy') {
        cartController.clearCart();
      }
    } catch (e) {
      debugPrint('Error clearing cart: $e');
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
}
