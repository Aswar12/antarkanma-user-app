import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/category_model.dart';
import 'package:antarkanma/app/data/providers/category_provider.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/storage_service.dart';

class CategoryService extends GetxService {
  final CategoryProvider _provider = CategoryProvider();
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storage = StorageService.instance;

  static const String CATEGORIES_STORAGE_KEY = 'categories';
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;

  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      print('Starting to load categories...');

      // Try to load from local storage first
      final storedCategories = _storage.getList(CATEGORIES_STORAGE_KEY);
      if (storedCategories != null) {
        print('Found stored categories: ${storedCategories.length}');
        try {
          categories.value = storedCategories
              .map((json) => CategoryModel.fromJson(json))
              .toList();
          print('Loaded categories from storage: ${categories.length}');
        } catch (e) {
          print('Error parsing stored categories: $e');
        }
      } else {
        print('No stored categories found');
      }

      // Get fresh data from API
      final token = _authService.getToken();
      if (token == null) {
        print('No token available, using cached categories only');
        return;
      }

      print('Fetching categories from API...');
      final response = await _provider.getCategories(token);
      print('API Response Status: ${response.statusCode}');
      print('API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        try {
          // Try to parse the response data
          final responseData = response.data;
          List<dynamic> categoryList;

          if (responseData is Map) {
            // Handle nested data structure
            if (responseData.containsKey('data')) {
              final data = responseData['data'];
              if (data is List) {
                categoryList = data;
              } else if (data is Map && data.containsKey('data')) {
                categoryList = data['data'] as List;
              } else {
                categoryList = [];
              }
            } else {
              categoryList = [];
            }
          } else if (responseData is List) {
            categoryList = responseData;
          } else {
            categoryList = [];
          }

          print('Parsed category list: $categoryList');

          final List<CategoryModel> newCategories = [];
          for (var json in categoryList) {
            try {
              final category = CategoryModel.fromJson(json);
              newCategories.add(category);
            } catch (e) {
              print('Error parsing category: $json');
              print('Error details: $e');
            }
          }

          print('Successfully parsed categories: ${newCategories.length}');
          if (newCategories.isNotEmpty) {
            print(
                'Category names: ${newCategories.map((c) => c.name).join(", ")}');
            categories.value = newCategories;

            // Save to local storage
            await _storage.saveList(CATEGORIES_STORAGE_KEY,
                newCategories.map((cat) => cat.toJson()).toList());
            print('Categories saved to local storage');
          } else {
            print('No categories found in API response');
          }
        } catch (parseError) {
          print('Error parsing API response: $parseError');
        }
      } else {
        print('API returned error status: ${response.statusCode}');
        print('Error response: ${response.data}');
      }
    } catch (e) {
      print('Error in loadCategories: $e');
    } finally {
      isLoading.value = false;
      print(
          'Category loading completed. Total categories: ${categories.length}');
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> clearLocalStorage() async {
    print('Clearing category local storage');
    await _storage.remove(CATEGORIES_STORAGE_KEY);
    categories.clear();
    print('Category local storage cleared');
  }
}
