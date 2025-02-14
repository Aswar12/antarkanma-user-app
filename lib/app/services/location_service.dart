import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../controllers/permission_controller.dart';

class LocationService extends GetxService {
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
  final RxBool _hasAccurateLocation = false.obs;

  final double defaultLatitude = -4.62824460;
  final double defaultLongitude = 119.58851330;

  final double _ultraHighAccuracyThreshold = 5.0;
  final double _highAccuracyThreshold = 10.0;
  final Duration _locationTimeout = const Duration(seconds: 30);
  final Duration _retryDelay = const Duration(seconds: 3);

  Future<LocationService> init() async {
    try {
      debugPrint('LocationService: Starting initialization...');

      // Clean up any existing resources first
      await _cleanupExistingResources();

      // Initialize network monitoring first
      await _initializeNetworkMonitoring();

      // Initialize platform-specific settings with network check
      if (isNetworkAvailable.value) {
        await _initializePlatform();
      } else {
        debugPrint('Network unavailable, skipping platform initialization');
      }

      // Check and request permissions
      if (!await _checkAndRequestPermissions()) {
        _fallbackToDefault();
        return this;
      }

      // Check location service
      if (!await _checkAndRequestLocationService()) {
        _fallbackToDefault();
        return this;
      }

      // Try to get last known position with timeout
      try {
        if (isNetworkAvailable.value) {
          final lastKnown = await Future.any([
            Geolocator.getLastKnownPosition(),
            Future.delayed(_locationTimeout, () => null),
          ]);

          if (lastKnown != null &&
              lastKnown.latitude != 0 &&
              lastKnown.longitude != 0) {
            _updateLocation(lastKnown, isHighAccuracy: false);
          }
        }
      } catch (e) {
        debugPrint('Error getting last known position: $e');
        // Continue initialization even if last known position fails
      }

      // Start location updates in the background only if network is available
      if (isNetworkAvailable.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          try {
            await _startLocationUpdates();
          } catch (e) {
            debugPrint('Error starting location updates: $e');
            // Don't fail initialization if updates can't start
          }
        });
      } else {
        debugPrint('Network unavailable, using default location');
        _fallbackToDefault();
      }

      debugPrint('LocationService: Initialization complete');
      return this;
    } catch (e) {
      debugPrint('Error initializing LocationService: $e');
      await _cleanupExistingResources();
      _fallbackToDefault();
      return this;
    }
  }

  Future<void> _initializeNetworkMonitoring() async {
    try {
      _connectivityStream?.cancel();
      _connectivityStream =
          _connectivity.onConnectivityChanged.listen((result) {
        final wasOffline = !isNetworkAvailable.value;
        isNetworkAvailable.value = result != ConnectivityResult.none;

        // If coming back online, try to restart location updates
        if (wasOffline && isNetworkAvailable.value) {
          debugPrint('Network restored, restarting location updates');
          _startLocationUpdates();
        }
      });

      final result = await _connectivity.checkConnectivity();
      isNetworkAvailable.value = result != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Error initializing network monitoring: $e');
      isNetworkAvailable.value = false;
    }
  }

  void _updateNetworkStatus(ConnectivityResult result) {
    isNetworkAvailable.value = result != ConnectivityResult.none;
  }

  int _retryCount = 0;
  static const int maxRetries = 3;
  bool _isUpdating = false;

  Future<void> _startLocationUpdates() async {
    if (_isUpdating) {
      debugPrint('Location updates already in progress');
      return;
    }

    try {
      _isUpdating = true;
      await _cleanupExistingResources();

      if (!await _checkAndRequestPermissions()) {
        _isUpdating = false;
        return;
      }

      if (!await _checkAndRequestLocationService()) {
        _isUpdating = false;
        return;
      }

      final locationSettings = _createLocationSettings();

      // Use a completer to handle the first position
      final completer = Completer<void>();
      Timer? timeoutTimer;

      // Set timeout for initial position
      timeoutTimer = Timer(_locationTimeout, () {
        if (!completer.isCompleted) {
          debugPrint('Initial position timeout');
          completer.complete(); // Complete anyway to continue stream
        }
      });

      // Create and listen to position stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) {
          // Cancel timeout on first position
          if (!completer.isCompleted) {
            timeoutTimer?.cancel();
            completer.complete();
          }

          // Handle position update
          if (position.latitude != 0 && position.longitude != 0) {
            _handlePositionUpdate(position);
          }
        },
        onError: (error) {
          debugPrint('Position stream error: $error');
          if (!completer.isCompleted) {
            timeoutTimer?.cancel();
            completer.complete(); // Complete to allow retry
          }
          _handleStreamError(error);
        },
        cancelOnError: false,
      );

      // Wait for initial position or timeout
      await completer.future;

      debugPrint('LocationService: Location updates started successfully');
    } catch (e) {
      debugPrint('Error starting location updates: $e');
      _startRecoveryTimer();
    }
  }

  Future<void> _cleanupExistingResources() async {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;

    if (_positionStream != null) {
      await _positionStream!.cancel();
      _positionStream = null;
    }

    _retryCount = 0;
    _isUpdating = false;
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (!_permissionController.isLocationPermissionGranted.value) {
      debugPrint('Location permission not granted, requesting...');
      final granted = await _permissionController.checkLocationPermission();
      if (!granted) {
        debugPrint('Location permission denied');
        return false;
      }
    }
    return true;
  }

  Future<bool> _checkAndRequestLocationService() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services disabled');
      await _handleLocationServiceDisabled();
      return false;
    }
    return true;
  }

  LocationSettings _createLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.best, // Maximum accuracy
        distanceFilter: 3, // Smaller distance for more frequent updates
        forceLocationManager: false, // Use Google Play Services for better accuracy
        intervalDuration: const Duration(seconds: 5), // More frequent updates
        timeLimit: const Duration(seconds: 60), // Longer timeout for better accuracy
        foregroundNotificationConfig: null,
      );
    } else if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 5,
        pauseLocationUpdatesAutomatically: true,
        // Prevent platform channel issues during background operation
        allowBackgroundLocationUpdates: false,
      );
    } else {
      return const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Platform initialization is handled in init()
  }

  Future<void> _initializePlatform() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      debugPrint('Platform not supported');
      return;
    }

    try {
      // Initialize platform interface first
      if (Platform.isAndroid) {
        await _initializeAndroidPlatform();
      }

      // Check location service
      if (!await Geolocator.isLocationServiceEnabled()) {
        debugPrint('Location service disabled');
        await _handleLocationServiceDisabled();
        return;
      }

      // Check accuracy mode
      try {
        final accuracy = await Geolocator.getLocationAccuracy();
        debugPrint('Location accuracy: $accuracy');
      } catch (e) {
        debugPrint('Error checking location accuracy: $e');
      }

      debugPrint('Platform initialization complete');
    } catch (e) {
      debugPrint('Error initializing platform: $e');
      throw Exception('Platform initialization failed: $e');
    }
  }

  Future<void> _initializeAndroidPlatform() async {
    try {
      // Ensure we only register once
      GeolocatorAndroid.registerWith();
      debugPrint('Android platform registered');

      // Small delay to ensure registration is complete
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      debugPrint('Error registering Android platform: $e');
      throw Exception('Android platform registration failed: $e');
    }
  }

  void _handlePositionUpdate(Position position) {
    _updateLocation(position, isHighAccuracy: true);
    if (!_hasAccurateLocation.value && isNetworkAvailable.value) {
      _enhanceLocationAccuracy();
    }
  }

  void _handleStreamError(dynamic error) {
    debugPrint('Location stream error: $error');
    if (error is LocationServiceDisabledException) {
      _handleLocationServiceDisabled();
    } else if (error is TimeoutException) {
      debugPrint('Location stream timed out, restarting...');
      _startRecoveryTimer();
    } else {
      debugPrint('Unknown location error: $error');
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

  Future<void> _enhanceLocationAccuracy() async {
    // Guard clauses
    if (_hasAccurateLocation.value) {
      debugPrint('Location already has high accuracy');
      return;
    }

    if (!_permissionController.isLocationPermissionGranted.value) {
      debugPrint('Location permission not granted, skipping enhancement');
      return;
    }

    if (!isNetworkAvailable.value) {
      debugPrint('Network not available, skipping enhancement');
      return;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      debugPrint('Location service disabled, skipping enhancement');
      return;
    }

    Timer? timeoutTimer;
    StreamSubscription<Position>? positionSubscription;

    try {
      final completer = Completer<Position>();

      // Set up timeout
      timeoutTimer = Timer(_locationTimeout, () {
        if (!completer.isCompleted) {
          debugPrint('Location enhancement timed out');
          completer.completeError(TimeoutException('Location enhancement timed out'));
          positionSubscription?.cancel();
        }
      });

      // Set up error handler
      void handleError(dynamic error) {
        if (!completer.isCompleted) {
          debugPrint('Location enhancement error: $error');
          completer.completeError(error);
        }
      }

      try {
        // Try to get both GPS and network locations simultaneously
        final Future<Position> gpsPosition = Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 60),
          forceAndroidLocationManager: false,
        );

        final Future<Position> networkPosition = Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.reduced,
          timeLimit: const Duration(seconds: 30),
          forceAndroidLocationManager: true,
        );

        // Wait for both positions with timeout
        final List<Position?> positions = await Future.wait([
          gpsPosition.catchError((e) {
            debugPrint('GPS position error: $e');
            return null;
          }),
          networkPosition.catchError((e) {
            debugPrint('Network position error: $e');
            return null;
          }),
        ], eagerError: false);

        Position? bestPosition;
        double bestAccuracy = double.infinity;

        // Compare accuracies and choose the best position
        for (final position in positions) {
          if (position != null && 
              position.latitude != 0 && 
              position.longitude != 0 && 
              position.accuracy < bestAccuracy) {
            bestPosition = position;
            bestAccuracy = position.accuracy;
          }
        }

        if (bestPosition != null) {
          debugPrint('Best position accuracy: ${bestPosition.accuracy}m');
          if (!completer.isCompleted) {
            completer.complete(bestPosition);
          }
        } else {
          throw Exception('No valid position obtained');
        }
      } catch (e) {
        handleError(e);
      }

      // Wait for result
      final position = await completer.future;

      if (position.accuracy <= _ultraHighAccuracyThreshold) {
        _updateLocation(position, isHighAccuracy: true);
        debugPrint('Location enhanced successfully with accuracy: ${position.accuracy}m');
      } else {
        debugPrint('Location accuracy not meeting threshold: ${position.accuracy}m');
      }
    } catch (e) {
      debugPrint('Location enhancement failed: $e');
      // Continue with current location
    } finally {
      timeoutTimer?.cancel();
      positionSubscription?.cancel();
    }
  }

  void _updateLocation(Position position, {required bool isHighAccuracy}) {
    latitude.value = position.latitude;
    longitude.value = position.longitude;
    isLocationAvailable.value = true;

    if (isHighAccuracy) {
      isHighAccuracyLocation.value =
          position.accuracy <= _highAccuracyThreshold;
      if (position.accuracy <= _ultraHighAccuracyThreshold) {
        _hasAccurateLocation.value = true;
      }
    }
  }

  void _fallbackToDefault() {
    _positionStream?.cancel();
    _recoveryTimer?.cancel();

    latitude.value = defaultLatitude;
    longitude.value = defaultLongitude;
    isLocationAvailable.value = false;
    isHighAccuracyLocation.value = false;
    _hasAccurateLocation.value = false;
  }

  void _startRecoveryTimer() {
    _recoveryTimer?.cancel();
    _recoveryTimer = Timer.periodic(_retryDelay, (timer) {
      _startLocationUpdates();
    });
  }

  Future<Map<String, dynamic>> getCurrentLocation(
      {bool forceUpdate = false}) async {
    Timer? timeoutTimer;

    try {
      if (forceUpdate) {
        final completer = Completer<void>();

        // Set up timeout
        timeoutTimer = Timer(_locationTimeout, () {
          if (!completer.isCompleted) {
            debugPrint('Location update timed out, using current location');
            completer.complete();
          }
        });

        // Try to enhance accuracy with timeout
        try {
          await _enhanceLocationAccuracy().timeout(_locationTimeout,
              onTimeout: () {
            debugPrint('Location enhancement timed out');
          });
        } catch (e) {
          debugPrint('Error during location enhancement: $e');
          // Continue with current location
        }

        completer.complete();
        await completer.future;
      }

      // Check if we have valid location data
      if (latitude.value != 0 &&
          longitude.value != 0 &&
          isLocationAvailable.value) {
        return {
          'latitude': latitude.value,
          'longitude': longitude.value,
          'isDefault': false,
          'isHighAccuracy': isHighAccuracyLocation.value,
          'hasNetwork': isNetworkAvailable.value,
        };
      } else {
        debugPrint('Using default location');
        return {
          'latitude': defaultLatitude,
          'longitude': defaultLongitude,
          'isDefault': true,
          'isHighAccuracy': false,
          'hasNetwork': isNetworkAvailable.value,
        };
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return {
        'latitude': defaultLatitude,
        'longitude': defaultLongitude,
        'isDefault': true,
        'isHighAccuracy': false,
        'hasNetwork': isNetworkAvailable.value,
        'error': e.toString()
      };
    } finally {
      timeoutTimer?.cancel();
    }
  }

  Future<void> forceLocationRefresh() async {
    _hasAccurateLocation.value = false;
    await _startLocationUpdates();
  }

  @override
  void onClose() {
    _positionStream?.cancel();
    _connectivityStream?.cancel();
    _recoveryTimer?.cancel();
    super.onClose();
  }
}
