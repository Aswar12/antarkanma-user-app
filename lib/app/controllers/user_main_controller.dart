// lib/app/controllers/user_main_controller.dart

import 'package:get/get.dart';

class UserMainController extends GetxController {
  // Gunakan late untuk menghindari null
  final _currentIndex = 0.obs;

  // Getter
  int get currentIndexValue => _currentIndex.value;
  RxInt get currentIndex => _currentIndex;

  @override
  void onInit() {
    super.onInit();
    _currentIndex.value = 0; // Set nilai awal
  }

  void changePage(int index) {
    _currentIndex.value = index;
  }
}
