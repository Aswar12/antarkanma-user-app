import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionController extends GetxController {
  final RxBool isLocationPermissionGranted = false.obs;
  final RxBool isStoragePermissionGranted = false.obs;
  final RxBool isCameraPermissionGranted = false.obs;
  final RxBool isNotificationPermissionGranted = false.obs;
  
  // Add a flag to prevent multiple dialogs
  bool _isShowingLocationDialog = false;

  @override
  void onInit() {
    super.onInit();
    _initializePermissions();
  }

  // Flag to prevent concurrent permission requests
  bool _isRequestingPermissions = false;

  Future<void> _initializePermissions() async {
    await checkInitialPermissions();
  }

  Future<void> _updatePermissionStatuses() async {
    isLocationPermissionGranted.value = await Permission.location.isGranted;
    isStoragePermissionGranted.value = await Permission.storage.isGranted;
    isCameraPermissionGranted.value = await Permission.camera.isGranted;
    isNotificationPermissionGranted.value = await Permission.notification.isGranted;
  }

  Future<void> checkInitialPermissions() async {
    if (_isRequestingPermissions) {
      debugPrint('Permission request already in progress');
      return;
    }

    try {
      _isRequestingPermissions = true;

      if (_isShowingLocationDialog) {
        return;
      }

      // First check location service
      final locationEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('Location service enabled: $locationEnabled');
      
      if (!locationEnabled) {
        _isShowingLocationDialog = true;
        final serviceEnabled = await _showLocationServiceDialog();
        _isShowingLocationDialog = false;
        if (!serviceEnabled) {
          debugPrint('Location service dialog cancelled or failed');
          return;
        }
      }

      await _updatePermissionStatuses();

      // Request permissions one at a time with delay between each
      if (!isLocationPermissionGranted.value) {
        await _requestSinglePermission(Permission.location, 'Lokasi');
        // Extra delay after location permission since it's critical
        await Future.delayed(const Duration(seconds: 2));
      }

      if (!isNotificationPermissionGranted.value) {
        await _requestSinglePermission(Permission.notification, 'Notifikasi');
        await Future.delayed(const Duration(seconds: 1));
      }

      if (!isCameraPermissionGranted.value) {
        await _requestSinglePermission(Permission.camera, 'Kamera');
        await Future.delayed(const Duration(seconds: 1));
      }

      if (!isStoragePermissionGranted.value) {
        await _requestSinglePermission(Permission.storage, 'Penyimpanan');
      }
    } catch (e) {
      debugPrint('Error in checkInitialPermissions: $e');
    } finally {
      _isShowingLocationDialog = false;
      _isRequestingPermissions = false;
    }
  }

  Future<void> _requestSinglePermission(Permission permission, String permissionName) async {
    try {
      final status = await permission.request();
      _updateSpecificPermissionStatus(permission, status.isGranted);
      
      if (status.isPermanentlyDenied) {
        final settingsOpened = await _showPermissionSettingsDialog(permissionName);
        if (!settingsOpened) {
          debugPrint('$permissionName permission settings cancelled');
          return;
        }
      }
    } catch (e) {
      debugPrint('Error requesting $permissionName permission: $e');
    }
  }

  Future<bool> _showLocationServiceDialog() async {
    try {
      if (_isShowingLocationDialog) {
        return false; // Prevent multiple dialogs
      }

      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Layanan Lokasi Nonaktif'),
          content: const Text(
            'Untuk mendapatkan lokasi yang akurat, '
            'mohon aktifkan layanan lokasi di pengaturan perangkat Anda.'
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('BATAL'),
            ),
            TextButton(
              onPressed: () {
                Get.back(result: true);
                Geolocator.openLocationSettings()
                    .timeout(const Duration(seconds: 20))
                    .then((_) async {
                  // Give user time to enable location
                  await Future.delayed(const Duration(seconds: 3));
                  final enabled = await Geolocator.isLocationServiceEnabled();
                  if (!enabled) {
                    debugPrint('Location service still disabled after settings');
                  }
                }).catchError((e) {
                  debugPrint('Error opening location settings: $e');
                });
              },
              child: const Text('PENGATURAN'),
            ),
          ],
        ),
        barrierDismissible: false,
      ).timeout(const Duration(seconds: 20));
      
      return result ?? false;
    } catch (e) {
      debugPrint('Error showing location service dialog: $e');
      return false;
    }
  }

  Future<bool> _showPermissionSettingsDialog(String permissionName) async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Izin Diperlukan'),
          content: Text(
            'Aplikasi memerlukan izin $permissionName untuk berfungsi dengan baik. '
            'Silakan aktifkan izin di pengaturan aplikasi.'
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('BATAL'),
            ),
            TextButton(
              onPressed: () {
                Get.back(result: true);
                openAppSettings()
                    .timeout(const Duration(seconds: 20))
                    .then((_) async {
                  await Future.delayed(const Duration(seconds: 1));
                  await _updatePermissionStatuses();
                }).catchError((e) {
                  debugPrint('Error opening app settings: $e');
                });
              },
              child: const Text('PENGATURAN'),
            ),
          ],
        ),
        barrierDismissible: false,
      ).timeout(const Duration(seconds: 20));
      
      return result ?? false;
    } catch (e) {
      debugPrint('Error showing permission settings dialog: $e');
      return false;
    }
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

  Future<bool> checkAndRequestPermission(Permission permission) async {
    if (_isRequestingPermissions) {
      debugPrint('Permission request already in progress');
      return false;
    }

    try {
      _isRequestingPermissions = true;

      if (permission == Permission.location) {
        final locationEnabled = await Geolocator.isLocationServiceEnabled();
        if (!locationEnabled) {
          if (_isShowingLocationDialog) {
            return false;
          }
          _isShowingLocationDialog = true;
          final serviceEnabled = await _showLocationServiceDialog();
          _isShowingLocationDialog = false;
          if (!serviceEnabled) {
            debugPrint('Location service dialog cancelled or failed');
            return false;
          }
          // Give time for location service to be enabled
          await Future.delayed(const Duration(seconds: 2));
        }
      }

      await _requestSinglePermission(permission, _getPermissionName(permission));
      final status = await permission.status;
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

  bool isAllPermissionsGranted() {
    return isLocationPermissionGranted.value &&
           isStoragePermissionGranted.value &&
           isCameraPermissionGranted.value &&
           isNotificationPermissionGranted.value;
  }
}
