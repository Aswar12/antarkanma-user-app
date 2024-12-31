import 'package:get/get.dart';
import '../data/models/product_category_model.dart';
import '../data/providers/product_category_provider.dart';
import 'auth_service.dart';
import 'package:get_storage/get_storage.dart';

class CategoryService extends GetxService {
  final RxList<ProductCategory> categories = <ProductCategory>[].obs;
  final RxBool isLoading = false.obs;
  final AuthService _authService = Get.find<AuthService>();
  final ProductCategoryProvider _provider = ProductCategoryProvider();
  final _storage = GetStorage();
  static const String _categoriesKey = 'categories';

  // Get categories from local storage or API
  Future<List<ProductCategory>> getCategories() async {
    try {
      isLoading.value = true;
      
      // Try to load from local storage first
      final storedCategories = _storage.read(_categoriesKey);
      if (storedCategories != null) {
        try {
          final List<ProductCategory> loadedCategories = (storedCategories as List)
              .map((json) => ProductCategory.fromJson(json))
              .toList();
          categories.assignAll(loadedCategories);
          print('Categories loaded from local storage: ${loadedCategories.length}');
          return loadedCategories;
        } catch (e) {
          print('Error parsing stored categories: $e');
          await _storage.remove(_categoriesKey);
        }
      }

      // If not in local storage or parsing failed, load from API
      final token = _authService.getToken();
      if (token == null) {
        print('No token available, will try again later');
        return [];
      }

      print('Fetching categories from API...');
      final response = await _provider.getCategories(token);
      print('API Response Status: ${response.statusCode}');
      print('API Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        print('Raw category data: $data');
        
        final List<ProductCategory> loadedCategories = [];
        for (var json in data) {
          try {
            final category = ProductCategory.fromJson(json);
            loadedCategories.add(category);
          } catch (e) {
            print('Error parsing category: $e');
            print('Problematic JSON: $json');
            continue;
          }
        }

        print('Successfully parsed categories: ${loadedCategories.length}');
        if (loadedCategories.isNotEmpty) {
          categories.assignAll(loadedCategories);
          await _storage.write(_categoriesKey, 
            loadedCategories.map((cat) => cat.toJson()).toList()
          );
          print('Categories saved to local storage: ${loadedCategories.length}');
          return loadedCategories;
        }
      } else {
        print('Failed to load categories. Status code: ${response.statusCode}');
        print('Response data: ${response.data}');
        
        if (response.statusCode == 401) {
          _authService.handleAuthError('401');
        }
      }
      return [];
    } catch (e, stackTrace) {
      print('Error in getCategories: $e');
      print('Stack trace: $stackTrace');
      // Try to use cached data if available
      final storedCategories = _storage.read(_categoriesKey);
      if (storedCategories != null) {
        try {
          final List<ProductCategory> loadedCategories = (storedCategories as List)
              .map((json) => ProductCategory.fromJson(json))
              .toList();
          categories.assignAll(loadedCategories);
          print('Using cached categories after error: ${loadedCategories.length}');
          return loadedCategories;
        } catch (e) {
          print('Error parsing cached categories: $e');
        }
      }
      return [];
    } finally {
      isLoading.value = false;
      print('Final categories count: ${categories.length}');
    }
  }

  // Clear categories from local storage
  Future<void> clearLocalStorage() async {
    await _storage.remove(_categoriesKey);
    categories.clear();
  }

  // Get a specific category by ID
  Future<ProductCategory?> getCategoryById(int id) async {
    // Check local categories first
    final localCategory = categories.firstWhereOrNull((cat) => cat.id == id);
    if (localCategory != null) {
      return localCategory;
    }

    try {
      final token = _authService.getToken();
      if (token == null) {
        print('No token available');
        return null;
      }

      final response = await _provider.getCategory(token, id);
      print('Get category by ID response: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          return ProductCategory.fromJson(data);
        }
      }
    } catch (e) {
      print('Error fetching category: $e');
    }
    return null;
  }
}
