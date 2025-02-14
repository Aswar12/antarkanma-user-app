// ignore_for_file: override_on_non_overriding_member

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/app/data/providers/user_location_provider.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';

class UserLocationService extends GetxService {
  static UserLocationService? _instance;
  StorageService? _storageService;
  UserLocationProvider? _userLocationProvider;
  final RxBool _isInitialized = false.obs;

  // Observable state
  final RxList<UserLocationModel> userLocations = <UserLocationModel>[].obs;
  final Rx<UserLocationModel?> defaultLocation = Rx<UserLocationModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  static const String _userLocationsKey = 'user_locations';
  static const String _defaultLocationKey = 'default_location';
  static const String _lastSyncKey = 'last_locations_sync';
  static const Duration _cacheDuration = Duration(hours: 24);

  // Private constructor without initialization
  UserLocationService._();

  // Factory constructor to return the singleton instance
  factory UserLocationService() {
    _instance ??= UserLocationService._();
    return _instance!;
  }

  bool canInitialize() {
    try {
      _storageService = StorageService.instance;
      final token = _storageService?.getToken();
      return token != null;
    } catch (e) {
      debugPrint('Error checking initialization status: $e');
      return false;
    }
  }

  Future<void> _initializeService() async {
    if (_isInitialized.value) return;

    try {
      // Initialize StorageService first
      _storageService = StorageService.instance;
      await _storageService?.ensureInitialized();
      
      // Retrieve token directly from StorageService
      final token = _storageService?.getToken();
      if (token == null) {
        debugPrint('UserLocationService: No valid token found, skipping initialization');
        return;
      }
      
      _userLocationProvider = UserLocationProvider();
      
      _isInitialized.value = true;
      debugPrint('UserLocationService initialized successfully');
      
      // Load data after initialization
      await _loadInitialData();
    } catch (e) {
      debugPrint('Error initializing UserLocationService: $e');
      _isInitialized.value = false;
      // Don't rethrow, just log the error
    }
  }

  Future<void> _loadInitialData() async {
    if (!_isInitialized.value) return;

    try {
      // Load local data first
      loadUserLocationsFromLocal();
      
      // Then sync with backend if needed
      if (_shouldSyncWithBackend()) {
        await loadUserLocations(forceRefresh: true);
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      // Don't rethrow here, just log the error
    }
  }

  bool _shouldSyncWithBackend() {
    if (!_isInitialized.value || _storageService == null) return false;
    
    final lastSync = _storageService!.getInt(_lastSyncKey);
    if (lastSync == null) return true;

    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    final now = DateTime.now();
    return now.difference(lastSyncTime) > _cacheDuration;
  }

  void loadUserLocationsFromLocal() {
    if (!_isInitialized.value || _storageService == null) return;

    try {
      final localLocations = _storageService!.getList(_userLocationsKey);
      final localDefaultLocation = _storageService!.getMap(_defaultLocationKey);

      if (localLocations != null) {
        userLocations.value = localLocations
            .map((json) => UserLocationModel.fromJson(json))
            .toList();
      }

      if (localDefaultLocation != null) {
        defaultLocation.value = UserLocationModel.fromJson(localDefaultLocation);
      }
    } catch (e) {
      debugPrint('Error loading local locations: $e');
      // Don't set error message here as it's just local data
    }
  }

  Future<void> loadUserLocations({bool forceRefresh = false}) async {
    if (!_isInitialized.value) {
      await _initializeService();
    }

    if (!_isInitialized.value) return;

    try {
      isLoading.value = true;
      final token = _storageService?.getToken();
      if (token == null) return;

      if (!forceRefresh &&
          userLocations.isNotEmpty &&
          !_shouldSyncWithBackend()) {
        return;
      }

      final response = await _userLocationProvider?.getUserLocations(token);
      if (response?.statusCode == 200) {
        final List<dynamic> locationsData = response!.data['data'];
        userLocations.value = locationsData
            .map((data) => UserLocationModel.fromJson(data))
            .toList();

        updateDefaultLocation();
        saveLocationsToLocal();

        await _storageService?.saveInt(
            _lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      errorMessage.value = e.toString();
      debugPrint('Error loading user locations: $e');
      // Only show snackbar for user-initiated loads
      if (forceRefresh) {
        showCustomSnackbar(
            title: 'Error',
            message: 'Gagal memuat lokasi: ${e.toString()}',
            isError: true);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addUserLocation(UserLocationModel location) async {
    if (!_isInitialized.value) {
      await _initializeService();
    }

    if (!_isInitialized.value) return false;

    try {
      final token = _storageService?.getToken();
      if (token == null) return false;

      final response =
          await _userLocationProvider?.addUserLocation(token, location.toJson());

      if (response?.statusCode == 201 || response?.statusCode == 200) {
        final newLocation = UserLocationModel.fromJson(response!.data['data']);
        userLocations.add(newLocation);

        if (newLocation.isDefault) {
          for (var loc in userLocations) {
            if (loc.id != newLocation.id) loc.isDefault = false;
          }
          updateDefaultLocation();
        }

        saveLocationsToLocal();
        showCustomSnackbar(
            title: 'Sukses', message: 'Lokasi berhasil ditambahkan');
        return true;
      }

      throw Exception(response?.data['message'] ?? 'Gagal menambahkan lokasi');
    } catch (e) {
      showCustomSnackbar(title: 'Error', message: e.toString(), isError: true);
      return false;
    }
  }

  Future<bool> updateUserLocation(UserLocationModel location) async {
    if (!_isInitialized.value) {
      await _initializeService();
    }

    if (!_isInitialized.value) return false;

    try {
      final token = _storageService?.getToken();
      if (token == null) return false;

      final response = await _userLocationProvider?.updateUserLocation(
          token, location.id!, location.toJson());

      if (response?.statusCode == 200) {
        final updatedLocation =
            UserLocationModel.fromJson(response!.data['data']);

        final index =
            userLocations.indexWhere((loc) => loc.id == updatedLocation.id);
        if (index != -1) {
          userLocations[index] = updatedLocation;

          if (updatedLocation.isDefault) {
            for (var loc in userLocations) {
              if (loc.id != updatedLocation.id) loc.isDefault = false;
            }
            updateDefaultLocation();
          }

          saveLocationsToLocal();
        }

        showCustomSnackbar(
            title: 'Sukses', message: 'Lokasi berhasil diperbarui');
        return true;
      }

      throw Exception(response?.data['message'] ?? 'Gagal memperbarui lokasi');
    } catch (e) {
      showCustomSnackbar(title: 'Error', message: e.toString(), isError: true);
      return false;
    }
  }

  Future<bool> deleteUserLocation(int locationId) async {
    if (!_isInitialized.value) {
      await _initializeService();
    }

    if (!_isInitialized.value) return false;

    try {
      final token = _storageService?.getToken();
      if (token == null) return false;

      final response =
          await _userLocationProvider?.deleteUserLocation(token, locationId);

      if (response?.statusCode == 200) {
        userLocations.removeWhere((loc) => loc.id == locationId);
        updateDefaultLocation();
        saveLocationsToLocal();
        showCustomSnackbar(title: 'Sukses', message: 'Lokasi berhasil dihapus');
        return true;
      }

      throw Exception(response?.data['message'] ?? 'Gagal menghapus lokasi');
    } catch (e) {
      showCustomSnackbar(title: 'Error', message: e.toString(), isError: true);
      return false;
    }
  }

  Future<bool> setDefaultLocation(int locationId) async {
    if (!_isInitialized.value) {
      await _initializeService();
    }

    if (!_isInitialized.value) return false;

    try {
      final token = _storageService?.getToken();
      if (token == null) return false;

      final response =
          await _userLocationProvider?.setDefaultLocation(token, locationId);

      if (response?.statusCode == 200) {
        for (var loc in userLocations) {
          loc.isDefault = loc.id == locationId;
        }

        updateDefaultLocation();
        saveLocationsToLocal();

        showCustomSnackbar(
            title: 'Sukses', message: 'Lokasi default berhasil diubah');
        return true;
      }

      throw Exception(
          response?.data['message'] ?? 'Gagal mengubah lokasi default');
    } catch (e) {
      showCustomSnackbar(title: 'Error', message: e.toString(), isError: true);
      return false;
    }
  }

  void updateDefaultLocation() {
    if (!_isInitialized.value || _storageService == null) return;

    UserLocationModel? defaultLoc;
    defaultLoc = userLocations.firstWhereOrNull((loc) => loc.isDefault);

    if (defaultLoc == null && userLocations.isNotEmpty) {
      defaultLoc = userLocations.first;
      defaultLoc.isDefault = true;
    }

    if (defaultLoc != null) {
      defaultLocation.value = defaultLoc;
      _storageService!.saveMap(_defaultLocationKey, defaultLoc.toJson());
    } else {
      defaultLocation.value = null;
      _storageService!.remove(_defaultLocationKey);
    }
  }

  void saveLocationsToLocal() {
    if (!_isInitialized.value || _storageService == null) return;
    _storageService!.saveList(
        _userLocationsKey, userLocations.map((loc) => loc.toJson()).toList());
  }

  Future<void> syncLocations({bool forceRefresh = false}) async {
    try {
      await loadUserLocations(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('Error syncing locations: $e');
      if (forceRefresh) {
        showCustomSnackbar(
            title: 'Error',
            message: 'Gagal menyinkronkan lokasi: ${e.toString()}',
            isError: true);
      }
    }
  }

  void clearLocalData() {
    if (!_isInitialized.value || _storageService == null) return;
    userLocations.clear();
    defaultLocation.value = null;
    _storageService!.remove(_userLocationsKey);
    _storageService!.remove(_defaultLocationKey);
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized.value) {
      await _initializeService();
    }
  }
}
