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

  final double defaultLatitude = -4.62824460;
  final double defaultLongitude = 119.58851330;

  final double _highAccuracyThreshold = 10.0;
  final Duration _locationTimeout = const Duration(seconds: 30);
  final Duration _retryDelay = const Duration(seconds: 3);

  // New method specifically for getting high-accuracy location when needed
  Future<Position?> getHighAccuracyLocation() async {
    if (!_permissionController.isLocationPermissionGranted.value ||
        !isNetworkAvailable.value ||
        !await Geolocator.isLocationServiceEnabled()) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: _locationTimeout,
        forceAndroidLocationManager: true,
      );

      _updateLocation(position, isHighAccuracy: true);
      return position;
    } on TimeoutException catch (e) {
      debugPrint('Timeout getting high accuracy location: $e');
      return null;
    } catch (e) {
      debugPrint('Error getting high accuracy location: $e');
      return null;
    }
  }

  Future<LocationService> init() async {
    try {
      debugPrint('LocationService: Starting initialization...');
      await _cleanupExistingResources();
      await _initializeNetworkMonitoring();

      if (isNetworkAvailable.value) {
        await _initializePlatform();
      }

      if (!await _checkAndRequestPermissions()) {
        _fallbackToDefault();
        return this;
      }

      if (!await _checkAndRequestLocationService()) {
        _fallbackToDefault();
        return this;
      }

      try {
        if (isNetworkAvailable.value) {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null && lastKnown.latitude != 0 && lastKnown.longitude != 0) {
            _updateLocation(lastKnown, isHighAccuracy: false);
          }
        }
      } catch (e) {
        debugPrint('Error getting last known position: $e');
      }

      if (isNetworkAvailable.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startLocationUpdates();
        });
      } else {
        _fallbackToDefault();
      }

      return this;
    } catch (e) {
      debugPrint('Error initializing LocationService: $e');
      await _cleanupExistingResources();
      _fallbackToDefault();
      return this;
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
      _connectivityStream = _connectivity.onConnectivityChanged.listen(_updateNetworkStatus);
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

  Future<void> _startLocationUpdates() async {
    if (!await _checkAndRequestPermissions() || !await _checkAndRequestLocationService()) {
      return;
    }

    try {
      final locationSettings = _createLocationSettings();
      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (position) {
          if (position.latitude != 0 && position.longitude != 0) {
            _updateLocation(position, isHighAccuracy: false);
          }
        },
        onError: (error) {
          debugPrint('Position stream error: $error');
          _handleStreamError(error);
        },
      );
    } catch (e) {
      debugPrint('Error starting location updates: $e');
      _startRecoveryTimer();
    }
  }

  LocationSettings _createLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 10,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 10),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: 10,
    );
  }

  void _updateLocation(Position position, {required bool isHighAccuracy}) {
    latitude.value = position.latitude;
    longitude.value = position.longitude;
    isLocationAvailable.value = true;
    isHighAccuracyLocation.value = position.accuracy <= _highAccuracyThreshold;
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

  // Method used by homepage controller
  Future<Map<String, dynamic>> getCurrentLocation({bool forceUpdate = false}) async {
    if (forceUpdate) {
      final position = await getHighAccuracyLocation();
      if (position != null) {
        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'isDefault': false,
          'isHighAccuracy': true,
          'hasNetwork': isNetworkAvailable.value,
        };
      }
    }

    return {
      'latitude': latitude.value,
      'longitude': longitude.value,
      'isDefault': !isLocationAvailable.value,
      'isHighAccuracy': isHighAccuracyLocation.value,
      'hasNetwork': isNetworkAvailable.value,
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
