import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:get/get.dart';

import 'package:antarkanma/app/services/merchant_service.dart'; // Importing merchant_service
import 'package:antarkanma/app/services/auth_service.dart'; // Adjust the import as necessary

class MerchantController extends GetxController {
  var currentIndex = 0.obs; // Reactive variable for current index
  final AuthService _authService = AuthService(); // Initialize AuthService
  final MerchantService _merchantService =
      MerchantService(); // Initialize MerchantService

  void changePage(int index) {
    currentIndex.value = index; // Update the current index
  }

  Future<MerchantModel?> getByOwnerId(int ownerId) async {
    try {
      final merchantData =
          await _merchantService.fetchMerchantData(); // Call fetchMerchantData
      if (merchantData == null) {
        print('No merchant data found');
        return null;
      }
      return merchantData; // Return the fetched merchant data
    } catch (e) {
      print('Error fetching merchant by owner ID: $e');
      return null;
    }
  }
}
