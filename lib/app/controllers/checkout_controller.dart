import 'dart:async';
import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:antarkanma/app/services/shipping_service.dart';
import 'package:antarkanma/app/services/transaction_service.dart';
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
  dio.CancelToken? _shippingCancelToken;

  void validateShipping() {
    if (shippingDetails.value?.isValidForShipping != true) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Shipping validation failed',
        isError: true,
      );
      return;
    }
    calculateShippingPreview();
  }

  @override
  void onInit() {
    super.onInit();
    setPaymentMethod('COD');
    _initializeCheckoutAsync();

    _workers = [
      ever<UserLocationModel?>(selectedLocation, (location) {
        if (location != null) {
          _reinitializeCheckout();
        }
      }),
      ever(cartController.merchantItems, (_) {
        _reinitializeCheckout();
      }),
    ];
  }

  void _reinitializeCheckout() {
    _initializeCheckout();
  }

  Future<void> _initializeCheckoutAsync() async {
    try {
      await _initializeCheckoutLocation();
      _initializeCheckout();
    } catch (e) {
      debugPrint('Error in initialization: $e');
    }
  }

  Future<void> _initializeCheckoutLocation() async {
    try {
      if (userLocationController.userLocations.isEmpty) {
        await userLocationController.loadAddresses();
      }

      final selectedLoc = userLocationController.selectedLocation;
      final defaultLoc = userLocationController.defaultAddress;
      final firstLoc = userLocationController.userLocations.isNotEmpty
          ? userLocationController.userLocations.first
          : null;

      UserLocationModel? priorityLocation = selectedLoc ?? defaultLoc ?? firstLoc;

      if (priorityLocation != null) {
        selectedLocation.value = priorityLocation;
        debugPrint('Location set successfully: ${priorityLocation.id}');
      } else {
        debugPrint('No valid location found');
        showCustomSnackbar(
          title: 'Warning',
          message: 'Alamat pengiriman tidak tersedia. Silakan tambahkan alamat baru.',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Error initializing checkout location: $e');
      _handleInitializationError(e);
    }
  }

  @override
  void onClose() {
    _workers?.forEach((worker) => worker.dispose());
    _workers = null;
    _shippingCancelToken?.cancel('Controller disposed');
    _shippingCancelToken = null;
    super.onClose();
  }

  void autoSetInitialValues() {
    if (selectedLocation.value == null) {
      _initializeCheckoutLocation();
    }

    if (selectedPaymentMethod.value == null && paymentMethods.isNotEmpty) {
      setPaymentMethod(paymentMethods.first);
    }

    _initializeCheckout();
  }

  void _initializeCheckout() {
    try {
      Map<int, List<CartItemModel>>? merchantCartItems;

      if (Get.arguments != null && Get.arguments is Map) {
        final args = Get.arguments as Map;
        if (args['type'] == 'direct_buy' && args['merchantItems'] != null) {
          merchantCartItems = args['merchantItems'] as Map<int, List<CartItemModel>>;
        }
      }

      merchantCartItems ??= _groupCartItemsByMerchant();

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

      subtotal.value = orderItems.fold(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      total.value = subtotal.value;
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

  Future<void> calculateShippingPreview() async {
    if (orderItems.isEmpty || selectedLocation.value == null) {
      shippingDetails.value = null;
      return;
    }

    if (isCalculatingShipping.value) {
      _shippingCancelToken?.cancel('New calculation requested');
      _shippingCancelToken = null;
    }

    isCalculatingShipping.value = true;
    _shippingCancelToken = dio.CancelToken();

    try {
      final locationId = selectedLocation.value?.id;
      if (locationId == null) {
        debugPrint('No location ID available for shipping calculation');
        showCustomSnackbar(
          title: 'Error',
          message: 'Alamat pengiriman tidak valid',
          isError: true,
        );
        return;
      }

      final items = orderItems.map((item) => {
        'product_id': item.product.id,
        'quantity': item.quantity,
      }).toList();

      final response = await shippingService.getShippingPreview(
        userLocationId: locationId,
        items: items,
        cancelToken: _shippingCancelToken,
      );

      if (_shippingCancelToken?.isCancelled ?? true) {
        debugPrint('Shipping calculation was cancelled');
        return;
      }

      if (response != null && response['data'] != null) {
        shippingDetails.value = ShippingDetails.fromJson(response);
        _updateDeliveryFee();
        debugPrint('Shipping calculation completed successfully');
      } else {
        debugPrint('Invalid shipping preview response');
        shippingDetails.value = null;
        showCustomSnackbar(
          title: 'Error',
          message: 'Gagal mendapatkan informasi pengiriman',
          isError: true,
        );
      }
    } on TimeoutException catch (e) {
      debugPrint('Shipping calculation timeout: ${e.message}');
      if (!(_shippingCancelToken?.isCancelled ?? true)) {
        showCustomSnackbar(
          title: 'Error',
          message: 'Kalkulasi biaya pengiriman timeout. Silakan coba lagi.',
          isError: true,
        );
      }
    } on dio.DioException catch (e) {
      if (e.type == dio.DioExceptionType.cancel) {
        debugPrint('Shipping calculation cancelled');
        return;
      }
      
      if (!(_shippingCancelToken?.isCancelled ?? true)) {
        String errorMessage = 'Gagal menghitung biaya pengiriman';
        if (e.type == dio.DioExceptionType.connectionTimeout ||
            e.type == dio.DioExceptionType.sendTimeout ||
            e.type == dio.DioExceptionType.receiveTimeout) {
          errorMessage = 'Koneksi timeout. Silakan coba lagi.';
        }
        
        debugPrint('Dio error in shipping calculation: ${e.message}');
        showCustomSnackbar(
          title: 'Error',
          message: errorMessage,
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Error calculating shipping preview: $e');
      if (!(_shippingCancelToken?.isCancelled ?? true)) {
        showCustomSnackbar(
          title: 'Error',
          message: 'Terjadi kesalahan saat menghitung biaya pengiriman',
          isError: true,
        );
      }
    } finally {
      if (!(_shippingCancelToken?.isCancelled ?? true)) {
        isCalculatingShipping.value = false;
        _shippingCancelToken = null;
      }
    }
  }

  void _updateDeliveryFee() {
    deliveryFee.value = shippingDetails.value?.totalShippingPrice ?? 0.0;
    total.value = subtotal.value + deliveryFee.value;
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
      final createdTransaction = await transactionService.createTransaction(transactionPayload);

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
    } on dio.DioException catch (e) {
      String errorMessage = 'Gagal memproses checkout';
      if (e.type == dio.DioExceptionType.connectionTimeout ||
          e.type == dio.DioExceptionType.sendTimeout ||
          e.type == dio.DioExceptionType.receiveTimeout) {
        errorMessage = 'Koneksi timeout. Silakan coba lagi.';
      }
      
      debugPrint('Dio error in checkout: ${e.message}');
      showCustomSnackbar(
        title: 'Error',
        message: errorMessage,
        isError: true,
      );
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
      validationErrors.add(shippingDetails.value!.routeWarningMessage ?? 'Rute pengiriman tidak valid');
    }

    final invalidItems = orderItems.where((item) => (item.merchant.id ?? 0) <= 0);
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

  void showPaymentMethodModal() async {
    final result = await Get.to(() => const PaymentMethodSelectionPage());
    if (result != null && result is String) {
      setPaymentMethod(result);
    }
  }
}
