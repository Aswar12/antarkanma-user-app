import 'package:get/get.dart';

class UserMainController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxBool isSearching = false.obs;

  void changePage(int index) {
    currentIndex.value = index;
  }

  void toggleSearch() {
    isSearching.toggle();
  }
}
