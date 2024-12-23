import 'package:get/get.dart';

class MerchantController extends GetxController {
  var currentIndex = 0.obs; // Reactive variable for current index

  void changePage(int index) {
    currentIndex.value = index; // Update the current index
  }
}
