import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../controllers/permission_controller.dart';

class LocationService extends GetxService {
  static LocationService get to => Get.find();
  
  final _permissionController = Get.find<PermissionController>();
  final _connectivity = Connectivity();

  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ConnectivityResult>? _connectivityStream;
  Timer? _recoveryTimer;

  final RxDouble latitude = 0.0.obs;
  final RxDouble longitude = 0.0.obs;
  final RxBool isLocationAvailable = false.obs;
  final RxBool isHighAccuracyLocation = false.obs;
  final RxBool isNetworkAvailable = false.obs;
  final RxDouble accuracy = 0.0.obs;

  final double defaultLatitude = -4.62824460;
  final double defaultLongitude = 119.58851330;

  final double _highAccuracyThreshold = 5.0; // 5 meters accuracy
  final Duration _locationTimeout = const Duration(seconds: 15);
  final Duration _retryDelay = const Duration(seconds: 1);
  static const int maxAttempts = 5;

  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  Position? _lastPosition;
  DateTime? _lastUpdateTime;

  Future<LocationService> init() async {
    if (_isInitialized) return this;
    
    if (_initCompleter != null) {
      return _initCompleter!.future.then((_) => this);
    }

    _initCompleter = Completer<void>();

    try {
      debugPrint('LocationService: Starting initialization...');
      await _cleanupExistingResources();
      await _initializeNetworkMonitoring();
      await _initializePlatform();

      // Check and request permissions first
      if (!await _checkAndRequestPermissions()) {
        debugPrint('Location permission not granted');
        _fallbackToDefault();
        _isInitialized = true;
        _initCompleter?.complete();
        return this;
      }

      // Check if location service is enabled
      if (!await _checkAndRequestLocationService()) {
        debugPrint('Location service not enabled');
        _fallbackToDefault();
        _isInitialized = true;
        _initCompleter?.complete();
        return this;
      }

      // Only try to get position after permissions are granted
      try {
        _lastPosition = await Geolocator.getLastKnownPosition();
        if (_lastPosition != null) {
          _updateLocation(_lastPosition!, isHighAccuracy: false);
        }
      } catch (e) {
        debugPrint('Error getting last known position: $e');
        _fallbackToDefault();
      }

      await _initializeLocationSettings();

      _isInitialized = true;
      _initCompleter?.complete();
      return this;
    } catch (e) {
      debugPrint('Error initializing LocationService: $e');
      _isInitialized = false;
      _initCompleter?.completeError(e);
      rethrow;
    }
  }

  Future<Position?> getHighAccuracyLocation() async {
    if (!_isInitialized) {
      await init();
    }

    try {
      // Check location service first
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location service is disabled');
        await _handleLocationServiceDisabled();
        // Check again after user interaction
        if (!await Geolocator.isLocationServiceEnabled()) {
          return _lastPosition;
        }
      }

      // Then check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return _lastPosition;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return _lastPosition;
      }

      // If we have a recent high accuracy position, use it
      if (_lastPosition != null && 
          _lastUpdateTime != null && 
          DateTime.now().difference(_lastUpdateTime!) < const Duration(seconds: 30) &&
          _lastPosition!.accuracy <= _highAccuracyThreshold) {
        return _lastPosition;
      }

      Position? position;
      int attempts = 0;

      while (attempts < maxAttempts) {
        try {
          // Try to get current position with lower accuracy first
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.reduced,
            timeLimit: const Duration(seconds: 5),
          ).timeout(const Duration(seconds: 5));

          if (position.accuracy <= _highAccuracyThreshold) {
            isHighAccuracyLocation.value = true;
            accuracy.value = position.accuracy;
            _lastPosition = position;
            _lastUpdateTime = DateTime.now();
            _updateLocation(position, isHighAccuracy: true);
            return position;
          }

          attempts++;
          if (attempts < maxAttempts) {
            await Future.delayed(const Duration(seconds: 1));
          }
        } catch (e) {
          debugPrint('Error in location attempt $attempts: $e');
          attempts++;
          if (attempts >= maxAttempts) break;
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      // If we got a position but not high accuracy, still use it
      if (position != null) {
        isHighAccuracyLocation.value = position.accuracy <= _highAccuracyThreshold;
        accuracy.value = position.accuracy;
        _lastPosition = position;
        _lastUpdateTime = DateTime.now();
        _updateLocation(position, isHighAccuracy: false);
        return position;
      }

      // If all attempts failed, try to get last known position
      try {
        position = await Geolocator.getLastKnownPosition();

        if (position != null) {
          isHighAccuracyLocation.value = false;
          accuracy.value = position.accuracy;
          _lastPosition = position;
          _lastUpdateTime = DateTime.now();
          _updateLocation(position, isHighAccuracy: false);
          return position;
        }
      } catch (e) {
        debugPrint('Error getting medium accuracy location: $e');
      }

      // Return last known position as fallback
      return _lastPosition;
    } catch (e) {
      debugPrint('Error getting high accuracy position: $e');
      return _lastPosition;
    }
  }

  Future<void> _initializeLocationSettings() async {
    try {
      if (!await _checkAndRequestPermissions()) {
        _fallbackToDefault();
        return;
      }

      if (!await _checkAndRequestLocationService()) {
        _fallbackToDefault();
        return;
      }

      // Start location updates
      if (isNetworkAvailable.value) {
        _startLocationUpdates();
      }
    } catch (e) {
      debugPrint('Error initializing location settings: $e');
      _fallbackToDefault();
    }
  }

  Future<void> _initializePlatform() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('Platform not supported');
      return;
    }

    try {
      if (Platform.isAndroid) {
        GeolocatorAndroid.registerWith();
      }
      debugPrint('Platform initialization complete');
    } catch (e) {
      debugPrint('Error initializing platform: $e');
    }
  }

  Future<void> _initializeNetworkMonitoring() async {
    try {
      _connectivityStream?.cancel();
      
      // Check initial connectivity
      try {
        final result = await _connectivity.checkConnectivity();
        isNetworkAvailable.value = result != ConnectivityResult.none;
      } catch (e) {
        debugPrint('Initial connectivity check failed: $e');
        isNetworkAvailable.value = false;
      }

      // Set up connectivity stream with error handling
      _connectivityStream = _connectivity.onConnectivityChanged.listen(
        _updateNetworkStatus,
        onError: (error) {
          debugPrint('Connectivity stream error: $error');
          isNetworkAvailable.value = false;
          _startRecoveryTimer();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Error initializing network monitoring: $e');
      isNetworkAvailable.value = false;
      // Retry network monitoring initialization after delay
      Future.delayed(const Duration(seconds: 5), _initializeNetworkMonitoring);
    }
  }

  void _updateNetworkStatus(ConnectivityResult result) {
    try {
      final hasNetwork = result != ConnectivityResult.none;
      isNetworkAvailable.value = hasNetwork;
      
      if (hasNetwork) {
        if (!_isInitialized) {
          _initializeLocationSettings();
        } else {
          // Restart location updates when network becomes available
          _startLocationUpdates();
        }
      } else {
        // Network lost - clean up location updates
        _cleanupExistingResources();
      }
    } catch (e) {
      debugPrint('Error updating network status: $e');
    }
  }

  Future<void> _startLocationUpdates() async {
    if (!isNetworkAvailable.value) {
      debugPrint('Network not available, skipping location updates');
      return;
    }

    if (!await _checkAndRequestPermissions() || !await _checkAndRequestLocationService()) {
      return;
    }

    try {
      await _cleanupExistingResources(); // Ensure clean state
      
      final locationSettings = _createLocationSettings();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).handleError((error) {
        debugPrint('Position stream error handled: $error');
        if (error is SocketException) {
          isNetworkAvailable.value = false;
          _startRecoveryTimer();
        }
        return Stream.empty();
      }).listen(
        (position) {
          if (position.latitude != 0 && position.longitude != 0) {
            _lastPosition = position;
            _lastUpdateTime = DateTime.now();
            _updateLocation(position, isHighAccuracy: position.accuracy <= _highAccuracyThreshold);
          }
        },
        onError: (error) {
          debugPrint('Position stream error: $error');
          _handleStreamError(error);
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('Error starting location updates: $e');
      _startRecoveryTimer();
    }
  }

  LocationSettings _createLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.reduced,
        distanceFilter: 10,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Antarkanma menggunakan lokasi untuk pengiriman yang akurat",
          notificationTitle: "Layanan Lokasi Aktif",
          enableWakeLock: true,
        ),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.reduced,
      distanceFilter: 10,
    );
  }

  void _updateLocation(Position position, {required bool isHighAccuracy}) {
    latitude.value = position.latitude;
    longitude.value = position.longitude;
    isLocationAvailable.value = true;
    isHighAccuracyLocation.value = isHighAccuracy;
    accuracy.value = position.accuracy;
  }

  void _handleStreamError(dynamic error) {
    debugPrint('Location stream error: $error');
    if (error is LocationServiceDisabledException) {
      _handleLocationServiceDisabled();
    } else {
      _startRecoveryTimer();
    }
  }

  Future<void> _handleLocationServiceDisabled() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.dialog(
          AlertDialog(
            title: const Text('Layanan Lokasi Nonaktif'),
            content: const Text('Untuk mendapatkan lokasi yang akurat, '
                'mohon aktifkan layanan lokasi di pengaturan perangkat Anda.'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('BATAL'),
              ),
              TextButton(
                onPressed: () async {
                  Get.back();
                  await Geolocator.openLocationSettings();
                },
                child: const Text('PENGATURAN'),
              ),
            ],
          ),
          barrierDismissible: false,
        );
      }
    } catch (e) {
      debugPrint('Error handling location service disabled: $e');
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (!_permissionController.isLocationPermissionGranted.value) {
      return await _permissionController.checkLocationPermission();
    }
    return true;
  }

  Future<bool> _checkAndRequestLocationService() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  void _fallbackToDefault() {
    latitude.value = defaultLatitude;
    longitude.value = defaultLongitude;
    isLocationAvailable.value = false;
    isHighAccuracyLocation.value = false;
    accuracy.value = 0.0;
  }

  void _startRecoveryTimer() {
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer(_retryDelay, _startLocationUpdates);
  }

  Future<void> _cleanupExistingResources() async {
    _recoveryTimer?.cancel();
    await _positionStream?.cancel();
    _positionStream = null;
  }

  Future<Map<String, dynamic>> getCurrentLocation({bool forceUpdate = false}) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      if (forceUpdate || _lastPosition == null || 
          (_lastUpdateTime != null && DateTime.now().difference(_lastUpdateTime!) > const Duration(seconds: 30))) {
        final position = await getHighAccuracyLocation();
        if (position != null) {
          return {
            'latitude': position.latitude,
            'longitude': position.longitude,
            'isDefault': false,
            'isHighAccuracy': position.accuracy <= _highAccuracyThreshold,
            'hasNetwork': isNetworkAvailable.value,
            'accuracy': position.accuracy,
          };
        }
      }

      // Return cached position if available and recent
      if (_lastPosition != null) {
        return {
          'latitude': _lastPosition!.latitude,
          'longitude': _lastPosition!.longitude,
          'isDefault': false,
          'isHighAccuracy': _lastPosition!.accuracy <= _highAccuracyThreshold,
          'hasNetwork': isNetworkAvailable.value,
          'accuracy': _lastPosition!.accuracy,
        };
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
    }

    // Return default values if all else fails
    return {
      'latitude': latitude.value,
      'longitude': longitude.value,
      'isDefault': !isLocationAvailable.value,
      'isHighAccuracy': isHighAccuracyLocation.value,
      'hasNetwork': isNetworkAvailable.value,
      'accuracy': accuracy.value,
    };
  }

  @override
  void onClose() {
    _positionStream?.cancel();
    _connectivityStream?.cancel();
    _recoveryTimer?.cancel();
    super.onClose();
  }
}
