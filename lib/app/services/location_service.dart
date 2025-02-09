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
  final RxBool isHighAccuracyLocation = false.obs;

  // Default coordinates for Sulawesi Selatan
  static const double defaultLatitude = -4.62824460;
  static const double defaultLongitude = 119.58851330;

  static const String _locationKey = 'user_default_location';
  static const String _lastAccurateLocationKey = 'last_accurate_location';
  static const int _locationMaxAge = 3600000; // 1 hour in milliseconds
  static const double _highAccuracyThreshold = 20.0; // 20 meters
  static const double _acceptableAccuracyThreshold = 50.0; // 50 meters

  Future<void> init() async {
    try {
      // First try to load the last accurate location
      final accurateLocation = await _loadLastAccurateLocation();
      if (accurateLocation != null) {
        // Use accurate location as initial position
        latitude.value = accurateLocation['latitude'];
        longitude.value = accurateLocation['longitude'];
        isLocationAvailable.value = true;
        isHighAccuracyLocation.value = accurateLocation['accuracy'] <= _highAccuracyThreshold;
        debugPrint('Using stored accurate location: ${latitude.value}, ${longitude.value} (accuracy: ${accurateLocation['accuracy']}m)');
      } else {
        // Fall back to default location
        final defaultLocation = _storageService.getMap(_locationKey);
        if (defaultLocation != null) {
          latitude.value = defaultLocation['latitude'];
          longitude.value = defaultLocation['longitude'];
          isLocationAvailable.value = true;
          isHighAccuracyLocation.value = false;
          debugPrint('Using default location: ${latitude.value}, ${longitude.value}');
        } else {
          // Use Sulawesi Selatan as fallback
          latitude.value = defaultLatitude;
          longitude.value = defaultLongitude;
          isLocationAvailable.value = false;
          isHighAccuracyLocation.value = false;
          debugPrint('Using Sulawesi Selatan as fallback location');
        }
      }

      isInitialized.value = true;

      // Start background location update
      _startBackgroundLocationUpdate();
    } catch (e) {
      debugPrint('Error in location service initialization: $e');
      // Fallback to Sulawesi Selatan coordinates
      latitude.value = defaultLatitude;
      longitude.value = defaultLongitude;
      isLocationAvailable.value = false;
      isHighAccuracyLocation.value = false;
      isInitialized.value = true;
    }
  }

  Future<Map<String, dynamic>?> _loadLastAccurateLocation() async {
    final storedLocation = _storageService.getMap(_lastAccurateLocationKey);
    if (storedLocation != null) {
      final timestamp = storedLocation['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      
      // Only use stored location if it's fresh enough
      if (age <= _locationMaxAge) {
        return storedLocation;
      }
    }
    return null;
  }

  void _startBackgroundLocationUpdate() async {
    try {
      // First try to get a quick fix using last known position
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _updateLocation(lastKnown, isHighAccuracy: false);
      }

      // Then try to get high accuracy location
      bool hasPermission = await LocationPermissionHandler.handleLocationPermission();
      if (hasPermission) {
        // Request location with high accuracy
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 30),
        );
        
        _updateLocation(position, isHighAccuracy: true);
        
        // If we got a high accuracy fix, start listening for location updates
        if (position.accuracy <= _highAccuracyThreshold) {
          _startLocationUpdates();
        }
      }
    } catch (e) {
      debugPrint('Error in background location update: $e');
    }
  }

  void _startLocationUpdates() {
    // Listen for location changes with both GPS and Network
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10, // minimum distance (meters) before updates
      ),
    ).listen(
      (Position position) {
        _updateLocation(position, isHighAccuracy: true);
      },
      onError: (error) {
        debugPrint('Error in location stream: $error');
      },
    );
  }

  void _updateLocation(Position position, {required bool isHighAccuracy}) {
    // Update current coordinates
    latitude.value = position.latitude;
    longitude.value = position.longitude;
    isLocationAvailable.value = true;
    
    // Update high accuracy status
    if (isHighAccuracy) {
      isHighAccuracyLocation.value = position.accuracy <= _highAccuracyThreshold;
    }

    // Save as last accurate location if accuracy is good enough
    if (position.accuracy <= _acceptableAccuracyThreshold) {
      _storageService.saveMap(_lastAccurateLocationKey, {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // If it's highly accurate, also save as default location
      if (position.accuracy <= _highAccuracyThreshold) {
        _storageService.saveMap(_locationKey, {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    }

    debugPrint('Location updated: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)');
  }

  Future<Map<String, dynamic>> getCurrentLocation({bool forceUpdate = false}) async {
    try {
      if (!forceUpdate) {
        // First try to use existing accurate location
        final accurateLocation = await _loadLastAccurateLocation();
        if (accurateLocation != null) {
          return {
            'latitude': accurateLocation['latitude'],
            'longitude': accurateLocation['longitude'],
            'accuracy': accurateLocation['accuracy'],
            'isDefault': false,
            'isHighAccuracy': accurateLocation['accuracy'] <= _highAccuracyThreshold,
            'timestamp': accurateLocation['timestamp']
          };
        }
      }

      // If no accurate location or force update requested, get new location
      bool hasPermission = await LocationPermissionHandler.handleLocationPermission();
      if (!hasPermission) {
        return {
          'latitude': latitude.value,
          'longitude': longitude.value,
          'accuracy': double.infinity,
          'isDefault': true,
          'isHighAccuracy': false,
          'error': 'Location permission not granted'
        };
      }

      // Try to get high accuracy location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );

      _updateLocation(position, isHighAccuracy: true);

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'isDefault': false,
        'isHighAccuracy': position.accuracy <= _highAccuracyThreshold,
        'timestamp': DateTime.now().millisecondsSinceEpoch
      };
    } catch (e) {
      debugPrint('Error getting location: $e');
      return {
        'latitude': latitude.value,
        'longitude': longitude.value,
        'accuracy': double.infinity,
        'isDefault': !isLocationAvailable.value,
        'isHighAccuracy': false,
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
        'isHighAccuracy': isHighAccuracyLocation.value,
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
        'isHighAccuracy': false,
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
      'isHighAccuracy': isHighAccuracyLocation.value,
    };
  }

  bool isUsingDefaultLocation() {
    return isInitialized.value && !isLocationAvailable.value;
  }

  bool hasHighAccuracyLocation() {
    return isLocationAvailable.value && isHighAccuracyLocation.value;
  }
}
