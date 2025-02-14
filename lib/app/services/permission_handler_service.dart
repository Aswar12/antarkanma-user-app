import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get_storage/get_storage.dart';

class PermissionHandlerService extends GetxService {
  static const String _permissionsRequestedKey = 'permissions_requested';
  final _storage = GetStorage();
  
  Future<PermissionHandlerService> init() async {
    await _checkAndRequestPermissions();
    return this;
  }

  Future<void> _checkAndRequestPermissions() async {
    bool permissionsRequested = _storage.read(_permissionsRequestedKey) ?? false;
    
    if (!permissionsRequested) {
      await requestInitialPermissions();
      await _storage.write(_permissionsRequestedKey, true);
    }
  }

  Future<Map<Permission, PermissionStatus>> requestInitialPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.storage,
      Permission.camera,
      Permission.notification,
    ].request();

    // Log permission statuses for debugging
    statuses.forEach((permission, status) {
      debugPrint('Permission $permission status: $status');
    });

    // Show dialog if any permission is permanently denied
    List<Permission> permanentlyDenied = statuses.entries
        .where((e) => e.value.isPermanentlyDenied)
        .map((e) => e.key)
        .toList();

    if (permanentlyDenied.isNotEmpty) {
      await _showPermissionSettingsDialog(permanentlyDenied);
    }

    return statuses;
  }

  Future<void> _showPermissionSettingsDialog(List<Permission> permissions) async {
    String permissionNames = permissions
        .map((p) => p.toString().split('.').last)
        .join(', ');

    await Get.dialog(
      AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: Text(
          'Aplikasi memerlukan izin $permissionNames untuk berfungsi dengan baik. '
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
            },
            child: const Text('BUKA PENGATURAN'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<bool> checkAndRequestPermission(Permission permission) async {
    PermissionStatus status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      bool? openSettings = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Izin Diperlukan'),
          content: Text(
            'Aplikasi memerlukan izin ${permission.toString().split('.').last} '
            'untuk menggunakan fitur ini. Buka pengaturan untuk mengaktifkan izin?'
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('BATAL'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('PENGATURAN'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (openSettings == true) {
        await openAppSettings();
        return await permission.status.isGranted;
      }
      return false;
    }

    status = await permission.request();
    return status.isGranted;
  }
}
