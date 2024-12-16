import 'package:antarkanma/app/data/models/user_model.dart';
import 'package:get/get.dart';
import '../services/user_service.dart';

class UserController extends GetxController {
  final UserService _userService = Get.find<UserService>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      isLoading.value = true;
      error.value = '';

      final user = await _userService.getUserProfile();
      if (user != null) {
        currentUser.value = user;
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile({
    required String name,
    String? email,
    String? phoneNumber,
    String? username,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      final success = await _userService.updateUserProfile(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        username: username,
      );

      if (success) {
        await fetchUserProfile();
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  // Getters
  bool get isAdmin => currentUser.value?.role == 'ADMIN';
  bool get isMerchant => currentUser.value?.role == 'MERCHANT';
  bool get isCourier => currentUser.value?.role == 'COURIER';
  bool get isUser => currentUser.value?.role == 'USER';
}
