import 'package:antarkanma/app/services/auth_service.dart';
import 'package:get/get.dart';

class UserMainController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxBool isSearching = false.obs;
  final AuthService _authService = Get.find<AuthService>();


  void changePage(int index) {
    currentIndex.value = index;
  }

  void toggleSearch() {
    isSearching.toggle();
  }

  @override
  void onClose() {
    print('UserMainController: Closing');
    super.onClose();
  }
}
