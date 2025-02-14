import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionChecker {
  static Future<bool> checkAllRequiredPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.storage,
      Permission.notification,
    ].request();

    bool allGranted = true;
    List<String> deniedPermissions = [];

    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
        deniedPermissions.add(_getPermissionName(permission));
      }
    });

    if (!allGranted) {
      await _showPermissionDeniedDialog(deniedPermissions);
      return false;
    }

    return true;
  }

  static String _getPermissionName(Permission permission) {
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

  static Future<void> _showPermissionDeniedDialog(List<String> permissions) async {
    String permissionText = permissions.join(', ');
    
    await Get.dialog(
      AlertDialog(
        title: const Text('Izin Diperlukan'),
        content: Text(
          'Aplikasi memerlukan izin berikut untuk berfungsi dengan baik:\n\n'
          '$permissionText\n\n'
          'Silakan aktifkan izin tersebut di pengaturan aplikasi.'
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

  static Future<bool> checkAndRequestPermission(Permission permission) async {
    PermissionStatus status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      bool? openSettings = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Izin Diperlukan'),
          content: Text(
            'Aplikasi memerlukan izin ${_getPermissionName(permission)} '
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
