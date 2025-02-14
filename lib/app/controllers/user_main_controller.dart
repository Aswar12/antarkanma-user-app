import 'dart:async';
import 'package:flutter/material.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/user_location_service.dart';
import 'package:antarkanma/app/services/location_service.dart';
import 'package:get/get.dart';
import '../routes/app_pages.dart';

class UserMainController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxBool isSearching = false.obs;
  final RxBool isInitialized = false.obs;
  final RxBool isLoading = true.obs;

  // Services are lazily initialized
  late final AuthService _authService;
  late final UserLocationService _userLocationService;
  late final LocationService _locationService;

  @override
  void onInit() {
    super.onInit();
    debugPrint('UserMainController: onInit called');
    _initializeServices();
  }

  void _initializeServices() {
    _authService = Get.find<AuthService>();
    _userLocationService = Get.find<UserLocationService>();
    _locationService = Get.find<LocationService>();
    debugPrint('UserMainController: Services found');
  }

  Future<void> ensureInitialized() async {
    if (!isInitialized.value) {
      try {
        debugPrint('UserMainController: Starting initialization');
        isLoading.value = true;

        // Verify auth status
        if (!_authService.isLoggedIn.value) {
          throw Exception('User not logged in');
        }

        // Load state with proper error handling
        await _loadSavedState();
        
        isInitialized.value = true;
        debugPrint('UserMainController: Initialized successfully');
      } catch (e) {
        debugPrint('Error initializing UserMainController: $e');
        isInitialized.value = false;
        Get.snackbar(
          'Error',
          'Failed to initialize: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.offAllNamed(Routes.splash);
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> _loadSavedState() async {
    try {
      debugPrint('UserMainController: Loading saved state');
      
      // Initialize basic state
      currentIndex.value = 0;
      isSearching.value = false;

      // Load user locations if needed
      if (_userLocationService.userLocations.isEmpty) {
        debugPrint('Loading user locations...');
        await _userLocationService.loadUserLocations(forceRefresh: false);
      }

      debugPrint('UserMainController: Saved state loaded successfully');
    } catch (e) {
      debugPrint('Error loading saved state: $e');
      throw Exception('Failed to load application state: $e');
    }
  }

  void changePage(int index) {
    try {
      if (!isInitialized.value) {
        debugPrint('UserMainController: Cannot change page - not initialized');
        return;
      }

      if (index < 0 || index > 3) {
        debugPrint('Invalid page index: $index');
        return;
      }
      currentIndex.value = index;
      debugPrint('UserMainController: Changed page to $index');
    } catch (e) {
      debugPrint('Error changing page: $e');
    }
  }

  void toggleSearch() {
    try {
      if (!isInitialized.value) {
        debugPrint('UserMainController: Cannot toggle search - not initialized');
        return;
      }
      isSearching.toggle();
    } catch (e) {
      debugPrint('Error toggling search: $e');
    }
  }

  Future<void> refreshData() async {
    if (!isInitialized.value) {
      debugPrint('UserMainController: Cannot refresh - not initialized');
      return;
    }

    try {
      isLoading.value = true;
      await _userLocationService.loadUserLocations(forceRefresh: true);
      debugPrint('UserMainController: Data refreshed successfully');
    } catch (e) {
      debugPrint('Error during refresh: $e');
      Get.snackbar(
        'Warning',
        'Some data may be outdated. Please check your connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    debugPrint('UserMainController: Closing');
    super.onClose();
  }
}
