// ignore_for_file: override_on_non_overriding_member

import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/app/data/providers/user_location_provider.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';

class UserLocationService extends GetxService {
  static UserLocationService? _instance;
  late final StorageService _storageService;
  late final AuthService _authService;
  late final UserLocationProvider _userLocationProvider;

  // Observable state
  final RxList<UserLocationModel> userLocations = <UserLocationModel>[].obs;
  final Rx<UserLocationModel?> defaultLocation = Rx<UserLocationModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  static const String _userLocationsKey = 'user_locations';
  static const String _defaultLocationKey = 'default_location';
  static const String _lastSyncKey = 'last_locations_sync';
  static const Duration _cacheDuration = Duration(hours: 24);

  // Private constructor
  UserLocationService._() {
    try {
      _storageService = Get.find<StorageService>();
      _authService = Get.find<AuthService>();
      _userLocationProvider = UserLocationProvider();
      debugPrint('UserLocationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing UserLocationService: $e');
      rethrow;
    }
  }

  // Factory constructor to return the singleton instance
  factory UserLocationService() {
    _instance ??= UserLocationService._();
    return _instance!;
  }

  @override
  void onInit() {
    super.onInit();
    loadUserLocationsFromLocal();
    if (_shouldSyncWithBackend()) {
      loadUserLocations();
    }
  }

  bool _shouldSyncWithBackend() {
    final lastSync = _storageService.getInt(_lastSyncKey);
    if (lastSync == null) return true;

    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
    final now = DateTime.now();
    return now.difference(lastSyncTime) > _cacheDuration;
  }

  void loadUserLocationsFromLocal() {
    try {
      final localLocations = _storageService.getList(_userLocationsKey);
      final localDefaultLocation = _storageService.getMap(_defaultLocationKey);

      userLocations.value = localLocations != null
          ? localLocations
              .map((json) => UserLocationModel.fromJson(json))
              .toList()
          : [];

      defaultLocation.value = localDefaultLocation != null
          ? UserLocationModel.fromJson(localDefaultLocation)
          : null;
    } catch (e) {
      errorMessage.value = 'Gagal memuat lokasi lokal: ${e.toString()}';
    }
  }

  Future<void> loadUserLocations({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      final token = _authService.getToken();
      if (token == null) {
        throw Exception('Token tidak valid');
      }

      if (!forceRefresh &&
          userLocations.isNotEmpty &&
          !_shouldSyncWithBackend()) {
        return;
      }

      final response = await _userLocationProvider.getUserLocations(token);
      if (response.statusCode == 200) {
        final List<dynamic> locationsData = response.data['data'];
        userLocations.value = locationsData
            .map((data) => UserLocationModel.fromJson(data))
            .toList();

        updateDefaultLocation();
        saveLocationsToLocal();

        await _storageService.saveInt(
            _lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      } else {
        throw Exception('Gagal memuat lokasi');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      showCustomSnackbar(
          title: 'Error',
          message: 'Gagal memuat lokasi: ${e.toString()}',
          isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addUserLocation(UserLocationModel location) async {
    try {
      final token = _authService.getToken();
      if (token == null) throw Exception('Token tidak valid');

      final response =
          await _userLocationProvider.addUserLocation(token, location.toJson());

      if (response.statusCode == 201 || response.statusCode == 200) {
        final newLocation = UserLocationModel.fromJson(response.data['data']);
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

      throw Exception(response.data['message'] ?? 'Gagal menambahkan lokasi');
    } catch (e) {
      showCustomSnackbar(title: 'Error', message: e.toString(), isError: true);
      return false;
    }
  }

  Future<bool> updateUserLocation(UserLocationModel location) async {
    try {
      final token = _authService.getToken();
      if (token == null) throw Exception('Token tidak valid');

      final response = await _userLocationProvider.updateUserLocation(
          token, location.id!, location.toJson());

      if (response.statusCode == 200) {
        final updatedLocation =
            UserLocationModel.fromJson(response.data['data']);

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

      throw Exception(response.data['message'] ?? 'Gagal memperbarui lokasi');
    } catch (e) {
      showCustomSnackbar(title: 'Error', message: e.toString(), isError: true);
      return false;
    }
  }

  Future<bool> deleteUserLocation(int locationId) async {
    try {
      final token = _authService.getToken();
      if (token == null) throw Exception('Token tidak valid');

      final response =
          await _userLocationProvider.deleteUserLocation(token, locationId);

      if (response.statusCode == 200) {
        userLocations.removeWhere((loc) => loc.id == locationId);
        updateDefaultLocation();
        saveLocationsToLocal();
        showCustomSnackbar(title: 'Sukses', message: 'Lokasi berhasil dihapus');
        return true;
      }

      throw Exception(response.data['message'] ?? 'Gagal menghapus lokasi');
    } catch (e) {
      showCustomSnackbar(title: 'Error', message: e.toString(), isError: true);
      return false;
    }
  }

  Future<bool> setDefaultLocation(int locationId) async {
    try {
      final token = _authService.getToken();
      if (token == null) throw Exception('Token tidak valid');

      final response =
          await _userLocationProvider.setDefaultLocation(token, locationId);

      if (response.statusCode == 200) {
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
          response.data['message'] ?? 'Gagal mengubah lokasi default');
    } catch (e) {
      showCustomSnackbar(title: 'Error', message: e.toString(), isError: true);
      return false;
    }
  }

  void updateDefaultLocation() {
    UserLocationModel? defaultLoc;
    defaultLoc = userLocations.firstWhereOrNull((loc) => loc.isDefault);

    if (defaultLoc == null && userLocations.isNotEmpty) {
      defaultLoc = userLocations.first;
      defaultLoc.isDefault = true;
    }

    if (defaultLoc != null) {
      defaultLocation.value = defaultLoc;
      _storageService.saveMap(_defaultLocationKey, defaultLoc.toJson());
    } else {
      defaultLocation.value = null;
      _storageService.remove(_defaultLocationKey);
    }
  }

  void saveLocationsToLocal() {
    _storageService.saveList(
        _userLocationsKey, userLocations.map((loc) => loc.toJson()).toList());
  }

  Future<void> syncLocations({bool forceRefresh = false}) async {
    try {
      await loadUserLocations(forceRefresh: forceRefresh);
    } catch (e) {
      showCustomSnackbar(
          title: 'Error',
          message: 'Gagal menyinkronkan lokasi: ${e.toString()}',
          isError: true);
    }
  }

  void clearLocalData() {
    userLocations.clear();
    defaultLocation.value = null;
    _storageService.remove(_userLocationsKey);
    _storageService.remove(_defaultLocationKey);
  }
}
