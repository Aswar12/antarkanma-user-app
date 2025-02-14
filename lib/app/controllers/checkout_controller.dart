import 'dart:async';

import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/services/shipping_service.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/app/data/models/order_item_model.dart';
import 'package:antarkanma/app/data/models/cart_item_model.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/data/models/shipping_details_model.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/modules/user/views/payment_method_selection_page.dart';

class CheckoutController extends GetxController {
  final UserLocationController userLocationController;
  final AuthController authController;
  final CartController cartController;
  final ShippingService shippingService;
  final TransactionService transactionService;

  CheckoutController({
    required this.userLocationController,
    required this.authController,
    required this.cartController,
    required this.shippingService,
    required this.transactionService,
  });

  // Observable properties
  final isLoading = false.obs;
  final isProcessingCheckout = false.obs;
  final isCalculatingShipping = false.obs;
  final orderItems = <OrderItemModel>[].obs;
  final selectedLocation = Rxn<UserLocationModel>();
  final selectedPaymentMethod = Rxn<String>();
  final subtotal = 0.0.obs;
  final deliveryFee = 0.0.obs;
  final total = 0.0.obs;
  final shippingDetails = Rxn<ShippingDetails>();
  final merchantItems = Rx<Map<int, List<OrderItemModel>>>({});

  final List<String> paymentMethods = ['COD'];

  List<Worker>? _workers;
  Timer? _shippingDebouncer;

  @override
  void onInit() {
    super.onInit();
    _initializeCheckoutAsync();
    setPaymentMethod('COD');

    _workers = [
      ever<UserLocationModel?>(
        selectedLocation,
        (location) {
          if (location != null) {
            _debouncedCalculateShipping();
          }
        },
      ),
      ever(cartController.merchantItems, (_) {
        _debouncedCalculateShipping();
      }),
    ];
  }

  void _debouncedCalculateShipping() {
    _shippingDebouncer?.cancel();
    _shippingDebouncer = Timer(const Duration(milliseconds: 500), () {
      _calculateShippingPreview();
    });
  }

  Future<void> _initializeCheckoutAsync() async {
    await _initializeCheckoutLocation();
    _initializeCheckout();
  }

  Future<void> _initializeCheckoutLocation() async {
    try {
      // Wait for UserLocationController to initialize if needed
      if (userLocationController.isLoading) {
        await Future.doWhile(() => 
          Future.delayed(const Duration(milliseconds: 100))
          .then((_) => userLocationController.isLoading));
      }

      final selectedLoc = userLocationController.selectedLocation;
      final defaultLoc = userLocationController.defaultAddress;
      final firstLoc = userLocationController.userLocations.isNotEmpty
          ? userLocationController.userLocations.first
          : null;

      UserLocationModel? priorityLocation = selectedLoc ?? defaultLoc ?? firstLoc;

      if (priorityLocation != null) {
        selectedLocation.value = priorityLocation;
        // Only update if the location is different
        if (userLocationController.selectedLocation != priorityLocation) {
          // Update local state first
          selectedLocation.value = priorityLocation;
        }
      }
    } catch (e) {
      debugPrint('Error initializing checkout location: $e');
    }
  }

  @override
  void onClose() {
    _workers?.forEach((worker) => worker.dispose());
    _workers = null;
    _shippingDebouncer?.cancel();
    super.onClose();
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

  void _initializeCheckout() {
    try {
      Map<int, List<CartItemModel>>? merchantCartItems;

      // Check if this is a direct purchase
      if (Get.arguments != null && Get.arguments is Map) {
        final args = Get.arguments as Map;
        if (args['type'] == 'direct_buy' && args['merchantItems'] != null) {
          merchantCartItems =
              args['merchantItems'] as Map<int, List<CartItemModel>>;
        }
      }

      // If not a direct purchase, get items from cart
      merchantCartItems ??= _groupCartItemsByMerchant();

      // Convert cart items to order items and group by merchant
      final Map<int, List<OrderItemModel>> groupedItems = {};
      final List<OrderItemModel> allItems = [];

      merchantCartItems.forEach((merchantId, items) {
        final merchantOrderItems = items
            .map((cartItem) => OrderItemModel.fromCartItem(
                  cartItem,
                  DateTime.now().millisecondsSinceEpoch.toString(),
                ))
            .toList();

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

  Map<int, List<CartItemModel>> _groupCartItemsByMerchant() {
    final selectedItems = cartController.selectedItems;
    final Map<int, List<CartItemModel>> merchantCartItems = {};

    for (var item in selectedItems) {
      final merchantId = item.merchant.id ?? 0;
      if (!merchantCartItems.containsKey(merchantId)) {
        merchantCartItems[merchantId] = [];
      }
      merchantCartItems[merchantId]!.add(item);
    }

    return merchantCartItems;
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
      shippingDetails.value = null;
      return;
    }

    // Prevent multiple simultaneous calculations
    if (isCalculatingShipping.value) {
      debugPrint('Shipping calculation already in progress, skipping...');
      return;
    }

    isCalculatingShipping.value = true;
    try {
      final locationId = selectedLocation.value?.id;
      if (locationId == null) return;

      final items = orderItems.map((item) => {
        'product_id': item.product.id,
        'quantity': item.quantity,
      }).toList();

      // Add timeout to prevent hanging
      final response = await Future.any([
        shippingService.getShippingPreview(
          userLocationId: locationId,
          items: items,
        ),
        Future.delayed(const Duration(seconds: 30), () => null),
      ]);

      if (response != null) {
        if (response['data']?['total_shipping_price'] != null &&
            response['data']?['merchant_deliveries'] != null &&
            response['data']?['route_summary'] != null) {
          shippingDetails.value = ShippingDetails.fromJson(response);
          _updateDeliveryFee();
        } else {
          debugPrint('Invalid shipping preview response structure: $response');
          shippingDetails.value = null;
        }
      } else {
        debugPrint('Shipping calculation timed out');
        shippingDetails.value = null;
      }
    } catch (e) {
      debugPrint('Error calculating shipping preview: $e');
      shippingDetails.value = null;
    } finally {
      isCalculatingShipping.value = false;
    }
  }

  void _updateDeliveryFee() {
    deliveryFee.value = shippingDetails.value?.totalShippingPrice ?? 0.0;
  }

  void setDeliveryLocation(UserLocationModel location) {
    selectedLocation.value = location;
    update();
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
        !isProcessingCheckout.value &&
        (shippingDetails.value?.canProceedToCheckout ?? false);
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
    if (shippingDetails.value?.routeWarningMessage != null) {
      return shippingDetails.value!.routeWarningMessage;
    }
    if (isProcessingCheckout.value) {
      return 'Sedang memproses checkout';
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
      if (!_validateCheckoutData()) {
        return;
      }

      final transactionPayload = _createTransactionPayload();
      final createdTransaction =
          await transactionService.createTransaction(transactionPayload);

      if (createdTransaction != null) {
        debugPrint('Transaction created successfully: ${createdTransaction.id}');
        _clearCart();
        _navigateToSuccessPage(createdTransaction);
        Get.find<OrderController>().setTransactionData(createdTransaction);
      } else {
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

  Map<String, dynamic> _createTransactionPayload() {
    return {
      'user_location_id': selectedLocation.value?.id,
      'payment_method': _mapPaymentMethod(selectedPaymentMethod.value ?? 'MANUAL'),
      'items': orderItems
          .map((item) => {
                'product_id': item.product.id,
                'quantity': item.quantity,
                'merchant_id': item.merchant.id,
              })
          .toList(),
      'shipping_details': shippingDetails.value?.toJson(),
    };
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

    if (shippingDetails.value == null) {
      validationErrors.add('Informasi pengiriman tidak tersedia');
    } else if (!shippingDetails.value!.canProceedToCheckout) {
      validationErrors.add(shippingDetails.value!.routeWarningMessage ??
          'Rute pengiriman tidak valid');
    }

    final invalidItems =
        orderItems.where((item) => (item.merchant.id ?? 0) <= 0);
    if (invalidItems.isNotEmpty) {
      validationErrors.add('Terdapat item dengan merchant tidak valid');
    }

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
    showCustomSnackbar(
      title: 'Validasi Gagal',
      message: errors.join('\n'),
      isError: true,
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
      if (Get.arguments == null ||
          (Get.arguments as Map)['type'] != 'direct_buy') {
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

  void showPaymentMethodModal() async {
    final result = await Get.to(() => const PaymentMethodSelectionPage());
    if (result != null && result is String) {
      setPaymentMethod(result);
    }
  }
}
