import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/app/services/user_location_service.dart';
import 'package:antarkanma/app/services/auth_service.dart';

class UserLocationController extends GetxController {
  late final UserLocationService _locationService;
  final AuthService _authService = Get.find<AuthService>();

  final Rx<UserLocationModel?> _defaultAddress = Rx<UserLocationModel?>(null);
  final RxList<UserLocationModel> _addresses = <UserLocationModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final Rx<UserLocationModel?> _selectedLocation = Rx<UserLocationModel?>(null);

  // Public getters
  UserLocationModel? get defaultAddress => _defaultAddress.value;
  List<UserLocationModel> get addresses => _addresses;
  List<UserLocationModel> get userLocations => _addresses;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  UserLocationModel? get selectedLocation => _selectedLocation.value;

  @override
  void onInit() {
    super.onInit();
    _initializeIfAuthenticated();
  }

  void _initializeIfAuthenticated() {
    if (_authService.isLoggedIn.value) {
      try {
        _locationService = Get.find<UserLocationService>();
        loadAddresses();
      } catch (e) {
        print('Error initializing UserLocationService: $e');
        _errorMessage.value = 'Error initializing location service: $e';
      }
    }
  }

  Future<void> loadAddresses() async {
    if (!_authService.isLoggedIn.value) return;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      await _locationService.loadUserLocations();
      _addresses.value = _locationService.userLocations;
      _defaultAddress.value = _locationService.defaultLocation.value;

      // If no location is selected, select the default one
      if (_selectedLocation.value == null && _defaultAddress.value != null) {
        _selectedLocation.value = _defaultAddress.value;
      }
    } catch (e) {
      print('Error loading addresses: $e');
      _errorMessage.value = 'Error loading addresses: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> addAddress(UserLocationModel address) async {
    if (!_authService.isLoggedIn.value) return false;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      final success = await _locationService.addUserLocation(address);
      if (success) {
        await loadAddresses();
      }
      return success;
    } catch (e) {
      _errorMessage.value = 'Error adding address: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateAddress(UserLocationModel address) async {
    if (!_authService.isLoggedIn.value) return false;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      final success = await _locationService.updateUserLocation(address);
      if (success) {
        await loadAddresses();
      }
      return success;
    } catch (e) {
      _errorMessage.value = 'Error updating address: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> deleteAddress(int addressId) async {
    if (!_authService.isLoggedIn.value) return false;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      final success = await _locationService.deleteUserLocation(addressId);
      if (success) {
        await loadAddresses();
      }
      return success;
    } catch (e) {
      _errorMessage.value = 'Error deleting address: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> setDefaultAddress(int addressId) async {
    if (!_authService.isLoggedIn.value) return false;

    try {
      _isLoading.value = true;
      _errorMessage.value = '';
      final success = await _locationService.setDefaultLocation(addressId);
      if (success) {
        await loadAddresses();
      }
      return success;
    } catch (e) {
      _errorMessage.value = 'Error setting default address: $e';
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  void selectLocation(UserLocationModel location) {
    _selectedLocation.value = location;
    update();
  }

  void setSelectedLocation(UserLocationModel location) {
    _selectedLocation.value = location;
    update();
  }

  void refreshAddresses() {
    loadAddresses();
  }

  void clearError() {
    _errorMessage.value = '';
  }
}
