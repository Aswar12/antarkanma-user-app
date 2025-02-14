import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxService {
  final _connectivity = Connectivity();
  final RxBool isConnected = true.obs;
  StreamSubscription<ConnectivityResult>? _subscription;

  Future<ConnectivityService> init() async {
    debugPrint('ConnectivityService: Initializing...');
    
    try {
      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);

      // Listen for connectivity changes
      _subscription = _connectivity.onConnectivityChanged.listen((result) {
        _updateConnectionStatus(result);
      });

      debugPrint('ConnectivityService: Initialized successfully');
    } catch (e) {
      debugPrint('ConnectivityService: Error initializing - $e');
      isConnected.value = true; // Assume connected on error
    }

    return this;
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    isConnected.value = result != ConnectivityResult.none;
    debugPrint('ConnectivityService: Connection status - ${isConnected.value}');
    
    if (!isConnected.value) {
      Get.snackbar(
        'Warning',
        'No internet connection available',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      isConnected.value = result != ConnectivityResult.none;
      return isConnected.value;
    } catch (e) {
      debugPrint('ConnectivityService: Error checking connectivity - $e');
      return true; // Assume connected on error
    }
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
