import 'package:antarkanma/app/data/models/user_model.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';

class MerchantProfileController extends GetxController {
  final MerchantService _merchantService = MerchantService();
  MerchantModel? merchant;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
    fetchMerchantData();
  }

  void fetchUserData() async {
    final user = AuthService().getUser();
    if (user != null) {
      currentUser.value = user;
    }
  }

  Future<void> fetchMerchantData() async {
    merchant = await _merchantService.fetchMerchantData();
    merchant ??= MerchantModel(
      ownerId: 0,
      name: '',
      address: '',
      phoneNumber: '',
      description: '',
      logo: '',
      status: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String get merchantName => merchant?.name ?? '';
  String get merchantPhone => merchant?.phoneNumber ?? '';

  String get merchantDescription => merchant?.description ?? '';
  String get merchantEmail => currentUser.value?.email ?? '';
  // double get merchantRating => merchant?.rating ?? 0.0; // Removed for now
}
