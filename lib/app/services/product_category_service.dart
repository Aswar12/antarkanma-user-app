import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:antarkanma/app/data/models/product_category_model.dart';
import 'package:antarkanma/app/data/providers/product_category_provider.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';

class ProductCategoryService extends GetxService {
  final ProductCategoryProvider _provider = ProductCategoryProvider();
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storage = StorageService.instance;

  static const String CATEGORIES_STORAGE_KEY = 'product_categories';
  final RxList<ProductCategory> categories = <ProductCategory>[].obs;
  final RxBool isLoading = false.obs;

  String? _getToken() {
    // First try to get token from storage
    final token = _storage.getToken();
    if (token != null) return token;
    
    // If not in storage, try from auth service
    return _authService.getToken();
  }

  Future<List<ProductCategory>> getCategories({bool forceRefresh = false}) async {
    try {
      // Always try to load from local storage first
      final storedCategories = _storage.getList(CATEGORIES_STORAGE_KEY);
      if (storedCategories != null && storedCategories.isNotEmpty) {
        debugPrint('Loading categories from local storage: ${storedCategories.length}');
        final localCategories = storedCategories
            .map((json) => ProductCategory.fromJson(json))
            .toList();
        categories.assignAll(localCategories);
        
        // If we have local data and don't need to refresh, return it
        if (!forceRefresh) {
          return localCategories;
        }
      }

      // Only fetch from API if we need to refresh or don't have local data
      isLoading.value = true;
      final token = _getToken();
      if (token == null) {
        debugPrint('No token available for categories request');
        return categories.toList(); // Return cached data if available
      }

      final response = await _provider.getCategories(token, silent: true);
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['data'];
        final List<ProductCategory> newCategories =
            data.map((json) => ProductCategory.fromJson(json)).toList();

        debugPrint('Loaded categories from API: ${newCategories.length}');
        categories.assignAll(newCategories);

        // Save to local storage
        await _storage.saveList(CATEGORIES_STORAGE_KEY,
            newCategories.map((cat) => cat.toJson()).toList());

        return newCategories;
      } else {
        debugPrint('Failed to load categories. Status code: ${response.statusCode}');
      }
      return categories.toList(); // Return cached data if API call fails
    } catch (e) {
      debugPrint('Error in getCategories: $e');
      return categories.toList(); // Return cached data on error
    } finally {
      isLoading.value = false;
    }
  }

  Future<ProductCategory?> getCategory(int id) async {
    try {
      // Check local categories first
      final localCategory = categories.firstWhereOrNull((cat) => cat.id == id);
      if (localCategory != null) {
        return localCategory;
      }

      final token = _getToken();
      if (token == null) return null;

      final response = await _provider.getCategory(token, id, silent: true);
      if (response.statusCode == 200 && response.data['data'] != null) {
        return ProductCategory.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting category: $e');
      return null;
    }
  }

  Future<bool> createCategory(String name, {String? description}) async {
    try {
      final token = _getToken();
      if (token == null) return false;

      final response = await _provider.createCategory(token, {
        'name': name,
        if (description != null) 'description': description,
      });

      if (response.statusCode == 200) {
        final category = ProductCategory.fromJson(response.data['data']);
        categories.add(category);
        
        // Update local storage
        await _storage.saveList(CATEGORIES_STORAGE_KEY,
            categories.map((cat) => cat.toJson()).toList());
            
        showCustomSnackbar(
          title: 'Success',
          message: 'Category created successfully',
        );
        return true;
      }
      return false;
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to create category: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  Future<bool> updateCategory(int id, String name, {String? description}) async {
    try {
      final token = _getToken();
      if (token == null) return false;

      final response = await _provider.updateCategory(token, id, {
        'name': name,
        if (description != null) 'description': description,
      });

      if (response.statusCode == 200) {
        final updatedCategory = ProductCategory.fromJson(response.data['data']);
        final index = categories.indexWhere((cat) => cat.id == id);
        if (index != -1) {
          categories[index] = updatedCategory;
          
          // Update local storage
          await _storage.saveList(CATEGORIES_STORAGE_KEY,
              categories.map((cat) => cat.toJson()).toList());
        }
        showCustomSnackbar(
          title: 'Success',
          message: 'Category updated successfully',
        );
        return true;
      }
      return false;
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to update category: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final token = _getToken();
      if (token == null) return false;

      final response = await _provider.deleteCategory(token, id);
      if (response.statusCode == 200) {
        categories.removeWhere((cat) => cat.id == id);
        
        // Update local storage
        await _storage.saveList(CATEGORIES_STORAGE_KEY,
            categories.map((cat) => cat.toJson()).toList());
            
        showCustomSnackbar(
          title: 'Success',
          message: 'Category deleted successfully',
        );
        return true;
      }
      return false;
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to delete category: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  // Initialize service
  Future<void> init() async {
    await getCategories();
  }

  @override
  void onInit() {
    super.onInit();
    init();
  }
}
