// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/location_permission_handler.dart';
import '../services/location_service.dart';

class MapPickerController extends GetxController {
  final selectedLocation = const LatLng(-4.6275392, 119.5871827).obs;
  final isLoading = false.obs;
  final currentAddress = ''.obs;
  late final Rx<MapController> mapController;
  final isHighAccuracy = false.obs;
  final accuracy = 0.0.obs;
  final zoomLevel = 17.0.obs;
  final canConfirm = false.obs; // Add canConfirm observable
  bool _disposed = false;
  Timer? _locationTimer;
  Timer? _zoomTimer;

  // Location Service
  final LocationService _locationService = LocationService.to;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  // Add a getter for currentLocation
  LatLng get currentLocation => selectedLocation.value;

  @override
  void onInit() {
    super.onInit();
    mapController = MapController().obs;
    _initializeLocation();
  }

  @override
  void onClose() {
    _disposed = true;
    _locationTimer?.cancel();
    _zoomTimer?.cancel();
    mapController.value.dispose();
    super.onClose();
  }

  Future<void> _initializeLocation() async {
    if (_disposed) return;

    if (_initCompleter != null) {
      await _initCompleter!.future;
      return;
    }

    _initCompleter = Completer<void>();

    try {
      await _locationService.init();

      // Get initial location
      final locationData = await _locationService.getCurrentLocation();
      if (locationData['latitude'] != null &&
          locationData['longitude'] != null) {
        final newLocation = LatLng(
          locationData['latitude'],
          locationData['longitude'],
        );
        await updateLocation(newLocation);
        isHighAccuracy.value = locationData['isHighAccuracy'] ?? false;
        accuracy.value = locationData['accuracy'] ?? 0.0;

        // Smoothly zoom to location
        animateToLocation(newLocation);
      }

      _isInitialized = true;
      _initCompleter?.complete();
    } catch (e) {
      debugPrint('Error initializing location: $e');
      _initCompleter?.completeError(e);
    }
  }

  void animateToLocation(LatLng location) {
    if (_disposed) return;

    try {
      // First move to location with current zoom
      mapController.value.move(location, mapController.value.zoom);

      // Then smoothly zoom in
      _zoomTimer?.cancel();
      const duration = Duration(milliseconds: 100);
      const steps = 10;
      final startZoom = mapController.value.zoom;
      final zoomDiff = (zoomLevel.value - startZoom) / steps;

      int step = 0;
      _zoomTimer = Timer.periodic(duration, (timer) {
        if (_disposed || step >= steps) {
          timer.cancel();
          return;
        }

        final newZoom = startZoom + (zoomDiff * step);
        try {
          mapController.value.move(location, newZoom);
        } catch (e) {
          debugPrint('Error during zoom animation: $e');
        }
        step++;
      });
    } catch (e) {
      debugPrint('Error animating to location: $e');
    }
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

      // Ensure initialization is complete
      if (!_isInitialized) {
        await _initializeLocation();
      }

      // Get location from LocationService
      final locationData =
          await _locationService.getCurrentLocation(forceUpdate: true);

      if (locationData['latitude'] != null &&
          locationData['longitude'] != null) {
        isHighAccuracy.value = locationData['isHighAccuracy'] ?? false;
        accuracy.value = locationData['accuracy'] ?? 0.0;

        final newLocation = LatLng(
          locationData['latitude'],
          locationData['longitude'],
        );

        await updateLocation(newLocation);

        // If not high accuracy, start periodic checks
        if (!isHighAccuracy.value) {
          _startAccuracyCheck();
        }

        // Animate to new location
        animateToLocation(newLocation);
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      if (!_disposed) {
        _safeUpdate(() => isLoading.value = false);
      }
    }
  }

  void _startAccuracyCheck() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_disposed || isHighAccuracy.value) {
        _locationTimer?.cancel();
        return;
      }

      final locationData =
          await _locationService.getCurrentLocation(forceUpdate: true);

      if (locationData['isHighAccuracy'] == true) {
        isHighAccuracy.value = true;
        accuracy.value = locationData['accuracy'] ?? 0.0;

        final betterLocation = LatLng(
          locationData['latitude'],
          locationData['longitude'],
        );

        await updateLocation(betterLocation);
        _locationTimer?.cancel();

        // Animate to better location
        animateToLocation(betterLocation);
      }
    });
  }

  Future<void> updateLocation(LatLng newLocation) async {
    if (_disposed) return;

    try {
      _safeUpdate(() {
        selectedLocation.value = newLocation;
        // Enable confirmation when location is updated
        canConfirm.value = true;
      });
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
      'isHighAccuracy': isHighAccuracy.value,
      'accuracy': accuracy.value,
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
    if (!_isInitialized) {
      _initializeLocation();
    }
  }

  String get formattedLocation {
    return '${selectedLocation.value.latitude.toStringAsFixed(6)}, '
        '${selectedLocation.value.longitude.toStringAsFixed(6)}';
  }

  String get accuracyText {
    return 'Akurasi (±${accuracy.value.toStringAsFixed(1)}m)';
  }
}
