import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/product_category_model.dart';
import 'package:antarkanma/app/data/providers/product_category_provider.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';

class ProductCategoryService extends GetxService {
  final ProductCategoryProvider _provider = ProductCategoryProvider();
  final AuthService _authService = Get.find<AuthService>();

  static const String CATEGORIES_STORAGE_KEY = 'product_categories';
  final RxList<ProductCategory> categories = <ProductCategory>[].obs;
  final RxBool isLoading = false.obs;
  final StorageService _storage = StorageService.instance;

  Future<List<ProductCategory>> getCategories({bool forceRefresh = false}) async {
    try {
      // Always try to load from local storage first
      final storedCategories = _storage.getList(CATEGORIES_STORAGE_KEY);
      if (storedCategories != null) {
        print('Loading categories from local storage: ${storedCategories.length}'); // Debug print
        final localCategories = storedCategories
            .map((json) => ProductCategory.fromJson(json))
            .toList();
        categories.assignAll(localCategories);
        
        // If we have local data and don't need to refresh, return it
        if (!forceRefresh && localCategories.isNotEmpty) {
          return localCategories;
        }
      }

      // Only fetch from API if we need to refresh or don't have local data
      isLoading.value = true;
      final token = _authService.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await _provider.getCategories(token);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final List<ProductCategory> newCategories =
            data.map((json) => ProductCategory.fromJson(json)).toList();

        print('Loaded categories from API: ${newCategories.length}'); // Debug print
        categories.assignAll(newCategories);

        // Save to local storage
        await _storage.saveList(CATEGORIES_STORAGE_KEY,
            newCategories.map((cat) => cat.toJson()).toList());

        return newCategories;
      }
      throw Exception('Failed to get categories');
    } catch (e) {
      print('Error in getCategories: $e'); // Debug print
      // If we have local data, use that on error
      if (categories.isNotEmpty) {
        return categories;
      } else {
        showCustomSnackbar(
          title: 'Error',
          message: 'Failed to load categories: ${e.toString()}',
          isError: true,
        );
        return [];
      }
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

      final token = _authService.getToken();
      if (token == null) throw Exception('Token not found');

      final response = await _provider.getCategory(token, id);
      if (response.statusCode == 200) {
        return ProductCategory.fromJson(response.data['data']);
      }
      throw Exception('Failed to get category');
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to load category: ${e.toString()}',
        isError: true,
      );
      return null;
    }
  }

  Future<bool> createCategory(String name, {String? description}) async {
    try {
      final token = _authService.getToken();
      if (token == null) throw Exception('Token not found');

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

      throw Exception(response.data['message'] ?? 'Failed to create category');
    } catch (e) {
      showCustomSnackbar(
        title: 'Error',
        message: 'Failed to create category: ${e.toString()}',
        isError: true,
      );
      return false;
    }
  }

  Future<bool> updateCategory(int id, String name,
      {String? description}) async {
    try {
      final token = _authService.getToken();
      if (token == null) throw Exception('Token not found');

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

      throw Exception(response.data['message'] ?? 'Failed to update category');
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
      final token = _authService.getToken();
      if (token == null) throw Exception('Token not found');

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

      throw Exception(response.data['message'] ?? 'Failed to delete category');
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
