// lib/app/utils/location_permission_handler.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class LocationPermissionHandler {
  static Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Show dialog to enable location services
      bool? openSettings = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Layanan Lokasi Nonaktif'),
          content: const Text(
              'Layanan lokasi dibutuhkan untuk menggunakan fitur ini. '
              'Aktifkan layanan lokasi di pengaturan?'),
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
        await Geolocator.openLocationSettings();
        // Check again after returning from settings
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          return false;
        }
      } else {
        return false;
      }
    }

    // Check and request location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Show dialog to open app settings
      bool? openAppSettings = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Izin Lokasi Diperlukan'),
          content: const Text('Izin lokasi diperlukan untuk menggunakan fitur ini. '
              'Buka pengaturan aplikasi untuk mengaktifkan izin lokasi?'),
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

      if (openAppSettings == true) {
        await Geolocator.openAppSettings();
        // Check again after returning from settings
        permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.deniedForever) {
          return false;
        }
      } else {
        return false;
      }
    }

    return true;
  }

  static Future<bool> checkAndRequestLocationService() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      bool? result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Aktifkan Layanan Lokasi'),
          content: const Text(
              'Untuk menggunakan fitur ini, Anda perlu mengaktifkan layanan lokasi. '
              'Apakah Anda ingin mengaktifkannya sekarang?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('TIDAK'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('YA'),
            ),
          ],
        ),
        barrierDismissible: false,
      );

      if (result == true) {
        await Geolocator.openLocationSettings();
        // Check again after user returns from settings
        return await Geolocator.isLocationServiceEnabled();
      }
      return false;
    }
    return true;
  }
}
