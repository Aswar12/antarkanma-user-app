import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../data/providers/shipping_provider.dart';

class ShippingService extends GetxService {
  final ShippingProvider _shippingProvider;

  ShippingService() : _shippingProvider = Get.find<ShippingProvider>();

  Future<Map<String, dynamic>?> calculateShipping({
    required int userLocationId,
    required int merchantId,
  }) async {
    try {
      final response = await _shippingProvider.calculateShipping(
        userLocationId: userLocationId,
        merchantId: merchantId,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData['meta']['code'] == 200 &&
            responseData['data'] != null) {
          return responseData['data'];
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error calculating shipping: $e');
      return null;
    }
  }
}
