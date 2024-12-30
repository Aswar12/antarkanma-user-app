import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';

class MerchantController extends GetxController {
  final MerchantService _merchantService = MerchantService();
  final AuthService _authService = AuthService();

  var currentIndex = 0.obs;
  var isLoading = false.obs;
  var merchant = Rx<MerchantModel?>(null);
  var hasError = false.obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print("MerchantController onInit called");
    _initializeData();
  }

  void _initializeData() {
    // Listen to auth changes
    ever(_authService.currentUser, (user) {
      if (user != null && merchant.value == null) {
        fetchMerchantData();
      }
    });

    // Initial fetch if user is already logged in
    if (_authService.currentUser.value != null) {
      fetchMerchantData();
    }
  }

  Future<void> fetchMerchantData() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final data = await _merchantService.getMerchant();
      
      if (data != null) {
        merchant.value = data;
        print("Merchant data fetched successfully: ${data.name}");
      } else {
        hasError.value = true;
        errorMessage.value = 'Tidak dapat memuat data merchant';
      }
    } catch (e) {
      print("Error fetching merchant data: $e");
      hasError.value = true;
      errorMessage.value = 'Terjadi kesalahan saat memuat data';
    } finally {
      isLoading.value = false;
    }
  }

  void changePage(int index) {
    currentIndex.value = index;
  }

  // Getter for merchant name with loading state handling
  String get merchantName => merchant.value?.name ?? '';

  // Method to refresh data after updates
  void refreshData() {
    fetchMerchantData();
  }
}
