import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:get/get.dart';

class UserMainController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxBool isSearching = false.obs;
  late HomePageController homeController;

  @override
  void onInit() {
    super.onInit();
    print('UserMainController: Initializing...');
    _initializeHomeController();
  }

  void _initializeHomeController() {
    // Get existing HomePageController or create new one
    if (!Get.isRegistered<HomePageController>()) {
      print('UserMainController: Creating new HomePageController');
      homeController = HomePageController();
      Get.put(homeController, permanent: true);
    } else {
      print('UserMainController: Using existing HomePageController');
      homeController = Get.find<HomePageController>();
    }

    // Ensure popular products are loaded
    if (homeController.popularProducts.isEmpty) {
      print('UserMainController: Loading popular products...');
      homeController.loadPopularProducts().then((_) {
        print('UserMainController: Loaded ${homeController.popularProducts.length} popular products');
      });
    } else {
      print('UserMainController: Popular products already loaded: ${homeController.popularProducts.length}');
    }
  }

  void changePage(int index) {
    print('UserMainController: Changing page to $index');
    currentIndex.value = index;
    
    // If returning to home page (index 0), ensure data is loaded
    if (index == 0 && homeController.popularProducts.isEmpty) {
      print('UserMainController: Reloading home page data');
      homeController.loadPopularProducts();
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
