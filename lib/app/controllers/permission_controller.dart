import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionController extends GetxController {
  final RxBool isLocationPermissionGranted = false.obs;
  final RxBool isStoragePermissionGranted = false.obs;
  final RxBool isCameraPermissionGranted = false.obs;
  final RxBool isNotificationPermissionGranted = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    try {
      // Check current permission statuses without requesting
      await _updatePermissionStatuses();
      
      // Request location permission first as it's critical
      if (!isLocationPermissionGranted.value) {
        final locationStatus = await Permission.location.request();
        isLocationPermissionGranted.value = locationStatus.isGranted;
        
        if (locationStatus.isPermanentlyDenied) {
          _showPermissionSettingsDialog('Lokasi');
        }
      }

      // Request other permissions in the background
      _requestOtherPermissions();
    } catch (e) {
      debugPrint('Error in _initializePermissions: $e');
    }
  }

  Future<void> _requestOtherPermissions() async {
    try {
      if (!isStoragePermissionGranted.value) {
        final status = await Permission.storage.request();
        isStoragePermissionGranted.value = status.isGranted;
      }

      if (!isCameraPermissionGranted.value) {
        final status = await Permission.camera.request();
        isCameraPermissionGranted.value = status.isGranted;
      }

      if (!isNotificationPermissionGranted.value) {
        final status = await Permission.notification.request();
        isNotificationPermissionGranted.value = status.isGranted;
      }
    } catch (e) {
      debugPrint('Error requesting other permissions: $e');
    }
  }

  Future<void> _updatePermissionStatuses() async {
    isLocationPermissionGranted.value = await Permission.location.isGranted;
    isStoragePermissionGranted.value = await Permission.storage.isGranted;
    isCameraPermissionGranted.value = await Permission.camera.isGranted;
    isNotificationPermissionGranted.value = await Permission.notification.isGranted;
  }


  Future<void> checkInitialPermissions() async {
    try {
      // First check if location service is enabled
      if (!await Geolocator.isLocationServiceEnabled()) {
        Get.dialog(
          AlertDialog(
            title: const Text('Layanan Lokasi Nonaktif'),
            content: const Text(
              'Untuk mendapatkan lokasi yang akurat, '
              'mohon aktifkan layanan lokasi di pengaturan perangkat Anda.'
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('BATAL'),
              ),
              TextButton(
                onPressed: () async {
                  Get.back();
                  await Geolocator.openLocationSettings();
                },
                child: const Text('PENGATURAN'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      }

      // Then check and update all permission statuses
      await _updatePermissionStatuses();
      
      // Request location permission if not granted
      if (!isLocationPermissionGranted.value) {
        final locationStatus = await Permission.location.request();
        isLocationPermissionGranted.value = locationStatus.isGranted;
        
        if (locationStatus.isPermanentlyDenied) {
          _showPermissionSettingsDialog('Lokasi');
        }
      }
    } catch (e) {
      debugPrint('Error in checkInitialPermissions: $e');
    }
  }

  Future<bool> checkAndRequestPermission(Permission permission) async {
    try {
      // First check if it's location permission and if location service is enabled
      if (permission == Permission.location && 
          !await Geolocator.isLocationServiceEnabled()) {
        Get.dialog(
          AlertDialog(
            title: const Text('Layanan Lokasi Nonaktif'),
            content: const Text(
              'Untuk mendapatkan lokasi yang akurat, '
              'mohon aktifkan layanan lokasi di pengaturan perangkat Anda.'
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('BATAL'),
              ),
              TextButton(
                onPressed: () async {
                  Get.back();
                  await Geolocator.openLocationSettings();
                },
                child: const Text('PENGATURAN'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
        return false;
      }

      PermissionStatus status = await permission.status;
      
      if (status.isGranted) {
        // Update the corresponding permission status
        _updateSpecificPermissionStatus(permission, true);
        return true;
      }

      if (status.isPermanentlyDenied) {
        _showPermissionSettingsDialog(_getPermissionName(permission));
        return false;
      }

      status = await permission.request();
      
      // Update the corresponding permission status
      _updateSpecificPermissionStatus(permission, status.isGranted);

      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking permission: $e');
      return false;
    }
  }

  void _updateSpecificPermissionStatus(Permission permission, bool granted) {
    switch (permission) {
      case Permission.location:
        isLocationPermissionGranted.value = granted;
        break;
      case Permission.storage:
        isStoragePermissionGranted.value = granted;
        break;
      case Permission.camera:
        isCameraPermissionGranted.value = granted;
        break;
      case Permission.notification:
        isNotificationPermissionGranted.value = granted;
        break;
      default:
        break;
    }
  }

  String _getPermissionName(Permission permission) {
    switch (permission) {
      case Permission.location:
        return 'Lokasi';
      case Permission.camera:
        return 'Kamera';
      case Permission.storage:
        return 'Penyimpanan';
      case Permission.notification:
        return 'Notifikasi';
      default:
        return permission.toString();
    }
  }

  void _showPermissionSettingsDialog(String permissionName) {
    Get.dialog(
      AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: Text(
          'Aplikasi memerlukan izin $permissionName untuk berfungsi dengan baik. '
          'Silakan aktifkan izin di pengaturan aplikasi.'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await openAppSettings();
              await Future.delayed(const Duration(seconds: 1));
              await _updatePermissionStatuses();
            },
            child: const Text('PENGATURAN'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<bool> checkLocationPermission() async {
    return await checkAndRequestPermission(Permission.location);
  }

  Future<bool> checkStoragePermission() async {
    return await checkAndRequestPermission(Permission.storage);
  }

  Future<bool> checkCameraPermission() async {
    return await checkAndRequestPermission(Permission.camera);
  }

  Future<bool> checkNotificationPermission() async {
    return await checkAndRequestPermission(Permission.notification);
  }

  bool isAllPermissionsGranted() {
    return isLocationPermissionGranted.value &&
           isStoragePermissionGranted.value &&
           isCameraPermissionGranted.value &&
           isNotificationPermissionGranted.value;
  }
}
