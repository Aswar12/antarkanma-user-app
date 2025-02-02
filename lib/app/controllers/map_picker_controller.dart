// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/location_permission_handler.dart';
import '../controllers/cart_controller.dart';

class MapPickerController extends GetxController {
  final selectedLocation = const LatLng(-4.6275392, 119.5871827).obs;
  final isLoading = false.obs;
  final currentAddress = ''.obs;
  final Rx<MapController> mapController = MapController().obs;
  bool _disposed = false;
  Timer? _locationTimer;

  // Add a getter for currentLocation
  LatLng get currentLocation => selectedLocation.value;

  @override
  void onInit() {
    super.onInit();
    _initializeLocation();
  }

  @override
  void onClose() {
    _disposed = true;
    _locationTimer?.cancel();
    mapController.value.dispose();
    super.onClose();
  }

  Future<void> _initializeLocation() async {
    if (_disposed) return;
    await getCurrentLocation();
  }

  void _safeUpdate(VoidCallback callback) {
    if (!_disposed) {
      try {
        callback();
      } catch (e) {
        print('Safe update error: $e');
      }
    }
  }

  Future<Position?> _getPositionWithTimeout() async {
    if (_disposed) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 40),
        onTimeout: () {
          throw TimeoutException('Waktu mendapatkan lokasi habis');
        },
      );
    } catch (e) {
      if (e is TimeoutException && !_disposed) {
        return await Geolocator.getLastKnownPosition();
      }
      rethrow;
    }
  }

  Future<void> getCurrentLocation() async {
    if (_disposed) return;

    try {
      _safeUpdate(() => isLoading.value = true);

      bool hasPermission =
          await LocationPermissionHandler.handleLocationPermission();
      if (!hasPermission || _disposed) return;

      bool serviceEnabled =
          await LocationPermissionHandler.checkAndRequestLocationService();
      if (!serviceEnabled || _disposed) return;

      Position? position = await _getPositionWithTimeout();
      if (_disposed || position == null) return;

      final newLocation = LatLng(position.latitude, position.longitude);
      await updateLocation(newLocation);

      if (!_disposed) {
        try {
          mapController.value.move(newLocation, 15);
        } catch (e) {
          print('Error moving map: $e');
        }
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      if (!_disposed) {
        _safeUpdate(() => isLoading.value = false);
      }
    }
  }

  Future<void> updateLocation(LatLng newLocation) async {
    if (_disposed) return;

    try {
      _safeUpdate(() => selectedLocation.value = newLocation);
      await getAddressFromLatLng(newLocation);
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> getAddressFromLatLng(LatLng location) async {
    if (_disposed) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw TimeoutException('Waktu mendapatkan alamat habis'),
      );

      if (_disposed) return;

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        _safeUpdate(() {
          currentAddress.value = [
            place.street,
            place.subLocality,
            place.locality,
            place.postalCode,
            place.country,
          ]
              .where((element) => element != null && element.isNotEmpty)
              .join(', ');
        });
      }
    } catch (e) {
      if (!_disposed) {
        _safeUpdate(
            () => currentAddress.value = 'Tidak dapat mendapatkan alamat');
      }
    }
  }

  void confirmLocation() {
    if (_disposed) return;

    final result = {
      'location': selectedLocation.value,
      'address': currentAddress.value,
    };

    try {
      Get.back(result: result);
    } catch (e) {
      print('Error in confirmLocation: $e');
      if (Get.context != null) {
        Navigator.of(Get.context!).pop(result);
      }
    }
  }

  void initializeMap() {
    selectedLocation.value =
        const LatLng(-4.6275392, 119.5871827); // Default coordinates
    mapController.value.move(selectedLocation.value, 15.0);
    getCurrentLocation();
  }

  String get formattedLocation {
    return '${selectedLocation.value.latitude.toStringAsFixed(6)}, '
        '${selectedLocation.value.longitude.toStringAsFixed(6)}';
  }
}
