import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:get/get.dart';

class UserMainController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxBool isSearching = false.obs;
  final AuthService _authService = Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
    print('UserMainController: Initializing...');
    // HomePageController is now initialized by UserBinding
    // We just need to ensure it's loaded when returning to home page
  }

  void changePage(int index) {
    print('UserMainController: Changing page to $index');
    currentIndex.value = index;
    
    // If returning to home page (index 0), ensure data is loaded
    if (index == 0 && 
        _authService.isLoggedIn.value && 
        _authService.currentUser.value?.role == 'USER') {
      print('UserMainController: Checking home page data');
      final homeController = Get.find<HomePageController>();
      if (homeController.popularProducts.isEmpty) {
        print('UserMainController: Loading home page data');
        homeController.loadInitialData().catchError((error) {
          print('UserMainController: Error loading home page data: $error');
        });
      }
    }
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
