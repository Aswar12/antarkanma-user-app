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
  final RxBool isInitialized = false.obs;

  late double defaultLatitude;
  late double defaultLongitude;

  static const String _locationKey = 'user_default_location';

  Future<void> init() async {
    try {
      // Load stored location if available
      final storedLocation = _storageService.getMap(_locationKey);
      if (storedLocation != null) {
        defaultLatitude = storedLocation['latitude'];
        defaultLongitude = storedLocation['longitude'];
        debugPrint('Loaded default location from storage: $defaultLatitude, $defaultLongitude');
      } else {
        // Request current location if no stored location
        await _requestCurrentLocation();
      }

      // Set initial values
      latitude.value = defaultLatitude;
      longitude.value = defaultLongitude;
      isLocationAvailable.value = false;
      isInitialized.value = true;

      // Try to get current location in the background
      getCurrentLocation().then((location) {
        if (!location['isDefault']) {
          latitude.value = location['latitude'];
          longitude.value = location['longitude'];
          isLocationAvailable.value = true;
        }
      }).catchError((e) {
        debugPrint('Error getting location in background: $e');
      });
    } catch (e) {
      debugPrint('Error in location service initialization: $e');
      // Fallback to default coordinates
      defaultLatitude = -6.2088;
      defaultLongitude = 106.8456;
      latitude.value = defaultLatitude;
      longitude.value = defaultLongitude;
      isLocationAvailable.value = false;
      isInitialized.value = true;
    }
  }

  Future<void> _requestCurrentLocation() async {
    final hasPermission = await LocationPermissionHandler.handleLocationPermission();
    if (hasPermission) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Save as default location
      await _storageService.saveMap(_locationKey, {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      defaultLatitude = position.latitude;
      defaultLongitude = position.longitude;
      debugPrint('Saved new default location: $defaultLatitude, $defaultLongitude');
    } else {
      // Use Jakarta as fallback
      defaultLatitude = -6.2088;
      defaultLongitude = 106.8456;
      debugPrint('Using Jakarta as fallback location');
    }
  }

  Future<Map<String, dynamic>> getCurrentLocation({bool forceUpdate = false}) async {
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
          return {
            'position': mostAccuratePosition,
            'latitude': mostAccuratePosition.latitude,
            'longitude': mostAccuratePosition.longitude,
            'accuracy': mostAccuratePosition.accuracy,
            'isDefault': false,
            'timestamp': DateTime.now().millisecondsSinceEpoch
          };
        }
      }

      // If no accurate enough location found or force update requested, get new location
      bool hasPermission = await LocationPermissionHandler.handleLocationPermission();
      if (!hasPermission) {
        debugPrint('Location permission not granted');
        return {
          'latitude': latitude.value,
          'longitude': longitude.value,
          'accuracy': double.infinity,
          'isDefault': true,
          'error': 'Location permission not granted',
          'timestamp': DateTime.now().millisecondsSinceEpoch
        };
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Save coordinates
      latitude.value = position.latitude;
      longitude.value = position.longitude;
      isLocationAvailable.value = true;

      // Save to storage for future requests with accuracy info
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _storageService.saveMap('user_location', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': timestamp,
        'accuracy': position.accuracy,
      });

      // Update default location if this is an accurate fix
      if (position.accuracy < 50) {  // Less than 50 meters accuracy
        await _storageService.saveMap(_locationKey, {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': timestamp,
        });
        defaultLatitude = position.latitude;
        defaultLongitude = position.longitude;
        debugPrint('Updated default location with accurate position: ${position.latitude}, ${position.longitude}');
      }

      debugPrint('New location obtained: ${position.latitude}, ${position.longitude}');
      return {
        'position': position,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'isDefault': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch
      };
    } catch (e) {
      debugPrint('Error getting location: $e');
      // Return default location on error
      return {
        'latitude': latitude.value,
        'longitude': longitude.value,
        'accuracy': double.infinity,
        'isDefault': true,
        'error': e.toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch
      };
    }
  }

  Future<Map<String, dynamic>> getLastKnownLocation() async {
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
        if (age <= 3600000 && storedAccuracy < bestAccuracy) {
          // 1 hour in milliseconds
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
          'isDefault': false,
          'accuracy': mostAccuratePosition.accuracy
        };
      }

      // Try to get current location
      final currentLocation = await getCurrentLocation(forceUpdate: true);
      if (!currentLocation['isDefault']) {
        return currentLocation;
      }

      // Return default location if no actual location available
      return {
        'latitude': latitude.value,
        'longitude': longitude.value,
        'isDefault': true,
        'accuracy': double.infinity
      };
    } catch (e) {
      debugPrint('Error getting last known location: $e');
      // Return default location on error
      return {
        'latitude': latitude.value,
        'longitude': longitude.value,
        'isDefault': true,
        'accuracy': double.infinity,
        'error': e.toString()
      };
    }
  }

  Future<Map<String, dynamic>> calculateDistance(
      double targetLat, double targetLng) async {
    try {
      if (!isLocationAvailable.value && !isInitialized.value) {
        await getCurrentLocation();
      }

      final distance = Geolocator.distanceBetween(
        latitude.value,
        longitude.value,
        targetLat,
        targetLng,
      );

      return {
        'distance': distance,
        'isDefault': !isLocationAvailable.value,
        'fromLocation': {
          'latitude': latitude.value,
          'longitude': longitude.value
        }
      };
    } catch (e) {
      debugPrint('Error calculating distance: $e');
      return {
        'error': e.toString(),
        'isDefault': !isLocationAvailable.value,
        'fromLocation': {
          'latitude': latitude.value,
          'longitude': longitude.value
        }
      };
    }
  }

  Map<String, dynamic> getCurrentCoordinates() {
    return {
      'latitude': latitude.value,
      'longitude': longitude.value,
      'isDefault': !isLocationAvailable.value,
    };
  }

  bool isUsingDefaultLocation() {
    return isInitialized.value && !isLocationAvailable.value;
  }
}


