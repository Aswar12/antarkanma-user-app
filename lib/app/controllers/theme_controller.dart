import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  final _box = GetStorage();
  final _key = 'isDarkMode'; // true = dark, false = light, null = system

  Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void _loadTheme() {
    final isDark = _box.read(_key);
    if (isDark == true) {
      themeMode.value = ThemeMode.dark;
    } else if (isDark == false) {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.system;
    }
  }

  void saveTheme(ThemeMode mode) {
    themeMode.value = mode;
    if (mode == ThemeMode.dark) {
      _box.write(_key, true);
    } else if (mode == ThemeMode.light) {
      _box.write(_key, false);
    } else {
      _box.remove(_key); // System mode
    }
    Get.changeThemeMode(mode);
    update(); // Notify GetBuilder to rebuild
  }

  bool get isDarkMode => themeMode.value == ThemeMode.dark;
}
