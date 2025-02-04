import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import '../utils/location_permission_handler.dart';
import './storage_service.dart';

class LocationService extends GetxService {
  final StorageService _storageService = StorageService.instance;
  final RxDouble latitude = 0.0.obs;
  final RxDouble longitude = 0.0.obs;
  final RxBool isLocationAvailable = false.obs;

  Future<LocationService> init() async {
    await getCurrentLocation();
    return this;
  }

  Future<Position?> getCurrentLocation() async {
    try {
      bool hasPermission = await LocationPermissionHandler.handleLocationPermission();
      if (!hasPermission) {
        debugPrint('Location permission not granted');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Save coordinates
      latitude.value = position.latitude;
      longitude.value = position.longitude;
      isLocationAvailable.value = true;

      // Save to storage for merchant requests
      await _storageService.saveMap('user_location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<Map<String, double>?> getLastKnownLocation() async {
    try {
      // First try to get from device's last known position
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        latitude.value = position.latitude;
        longitude.value = position.longitude;
        isLocationAvailable.value = true;
        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      }
      
      // If no last known position, try to get from storage
      final storedLocation = _storageService.getMap('user_location');
      if (storedLocation != null) {
        final timestamp = storedLocation['timestamp'] as int;
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        
        // Only use stored location if it's less than 1 hour old
        if (age <= 3600000) { // 1 hour in milliseconds
          latitude.value = storedLocation['latitude'] as double;
          longitude.value = storedLocation['longitude'] as double;
          isLocationAvailable.value = true;
          return {
            'latitude': latitude.value,
            'longitude': longitude.value,
          };
        }
      }

      // If no valid location found, try to get current location
      return getCurrentLocation().then((position) {
        if (position != null) {
          return {
            'latitude': position.latitude,
            'longitude': position.longitude,
          };
        }
        return null;
      });
    } catch (e) {
      debugPrint('Error getting last known location: $e');
      return null;
    }
  }

  Future<double?> calculateDistance(double targetLat, double targetLng) async {
    try {
      if (!isLocationAvailable.value) {
        await getCurrentLocation();
      }

      if (isLocationAvailable.value) {
        return Geolocator.distanceBetween(
          latitude.value,
          longitude.value,
          targetLat,
          targetLng,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return null;
    }
  }

  Map<String, double>? getCurrentCoordinates() {
    if (isLocationAvailable.value) {
      return {
        'latitude': latitude.value,
        'longitude': longitude.value,
      };
    }
    return null;
  }
}
