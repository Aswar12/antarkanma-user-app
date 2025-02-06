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

  Future<Position?> getCurrentLocation({bool forceUpdate = false}) async {
    try {
      Position? mostAccuratePosition;
      double bestAccuracy = double.infinity;

      if (!forceUpdate) {
        // Try to get device's last known position
        Position? devicePosition = await Geolocator.getLastKnownPosition();
        if (devicePosition != null && devicePosition.accuracy < bestAccuracy) {
          mostAccuratePosition = devicePosition;
          bestAccuracy = devicePosition.accuracy;
        }

        // Check stored location
        final storedLocation = _storageService.getMap('user_location');
        if (storedLocation != null) {
          final timestamp = storedLocation['timestamp'] as int;
          final age = DateTime.now().millisecondsSinceEpoch - timestamp;
          final storedAccuracy = storedLocation['accuracy'] as double? ?? double.infinity;

          // Consider stored location if it's less than 1 hour old and more accurate
          if (age <= 3600000 && storedAccuracy < bestAccuracy) {
            mostAccuratePosition = Position(
              latitude: storedLocation['latitude'] as double,
              longitude: storedLocation['longitude'] as double,
              timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
              accuracy: storedAccuracy,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
            bestAccuracy = storedAccuracy;
          }
        }

        // If we found an accurate enough position (less than 50 meters), use it
        if (mostAccuratePosition != null && bestAccuracy < 50) {
          debugPrint('Using existing accurate location (accuracy: ${bestAccuracy}m): ${mostAccuratePosition.latitude}, ${mostAccuratePosition.longitude}');
          latitude.value = mostAccuratePosition.latitude;
          longitude.value = mostAccuratePosition.longitude;
          isLocationAvailable.value = true;
          return mostAccuratePosition;
        }
      }

      // If no accurate enough location found or force update requested, get new location
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

      // Save to storage for future requests with accuracy info
      await _storageService.saveMap('user_location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'accuracy': position.accuracy,
      });

      debugPrint('New location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<Map<String, double>?> getLastKnownLocation() async {
    try {
      Position? mostAccuratePosition;
      double bestAccuracy = double.infinity;
      
      // Try to get from device's last known position
      Position? devicePosition = await Geolocator.getLastKnownPosition();
      if (devicePosition != null && devicePosition.accuracy < bestAccuracy) {
        mostAccuratePosition = devicePosition;
        bestAccuracy = devicePosition.accuracy;
      }
      
      // Check stored location
      final storedLocation = _storageService.getMap('user_location');
      if (storedLocation != null) {
        final timestamp = storedLocation['timestamp'] as int;
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;
        final storedAccuracy = storedLocation['accuracy'] as double? ?? double.infinity;
        
        // Only consider stored location if it's less than 1 hour old and more accurate
        if (age <= 3600000 && storedAccuracy < bestAccuracy) { // 1 hour in milliseconds
          mostAccuratePosition = Position(
            latitude: storedLocation['latitude'] as double,
            longitude: storedLocation['longitude'] as double,
            timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
            accuracy: storedAccuracy,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
          bestAccuracy = storedAccuracy;
        }
      }

      // If we found a valid position, use it
      if (mostAccuratePosition != null) {
        latitude.value = mostAccuratePosition.latitude;
        longitude.value = mostAccuratePosition.longitude;
        isLocationAvailable.value = true;
        debugPrint('Using most accurate location (accuracy: ${mostAccuratePosition.accuracy}m): ${mostAccuratePosition.latitude}, ${mostAccuratePosition.longitude}');
        return {
          'latitude': mostAccuratePosition.latitude,
          'longitude': mostAccuratePosition.longitude,
        };
      }

      // If no valid location found or accuracy not good enough, try to get current location
      return getCurrentLocation(forceUpdate: true).then((position) {
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
