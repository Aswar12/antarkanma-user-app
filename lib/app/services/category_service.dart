import 'package:get/get.dart' hide Response;
import 'package:dio/dio.dart';
import '../data/models/product_category_model.dart';
import '../data/providers/product_category_provider.dart';
import 'auth_service.dart';
import 'package:get_storage/get_storage.dart';
import '../utils/logger_util.dart';

class CategoryService extends GetxService {
  final RxList<ProductCategory> categories = <ProductCategory>[].obs;
  final RxBool isLoading = false.obs;
  final AuthService _authService = Get.find<AuthService>();
  late final ProductCategoryProvider _provider;
  final _storage = GetStorage();
  static const String _categoriesKey = 'categories';

  CategoryService() {
    _provider = Get.find<ProductCategoryProvider>();
  }

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
          LoggerUtil.info('Categories loaded from local storage: ${loadedCategories.length}');
          return loadedCategories;
        } catch (e) {
          LoggerUtil.error('Error parsing stored categories', e);
          await _storage.remove(_categoriesKey);
        }
      }

      // If not in local storage or parsing failed, load from API
      final token = _authService.getToken();
      if (token == null) {
        LoggerUtil.info('No token available, will try again later');
        return [];
      }

      LoggerUtil.debug('Fetching categories from API...');
      final response = await _provider.getCategories(token);
      LoggerUtil.debug('API Response Status: ${response.statusCode}');
      LoggerUtil.debug('API Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        LoggerUtil.debug('Raw category data: $data');
        
        final List<ProductCategory> loadedCategories = [];
        for (var json in data) {
          try {
            final category = ProductCategory.fromJson(json);
            loadedCategories.add(category);
          } catch (e) {
            LoggerUtil.error('Error parsing category', e);
            LoggerUtil.debug('Problematic JSON: $json');
            continue;
          }
        }

        LoggerUtil.info('Successfully parsed categories: ${loadedCategories.length}');
        if (loadedCategories.isNotEmpty) {
          categories.assignAll(loadedCategories);
          await _storage.write(_categoriesKey, 
            loadedCategories.map((cat) => cat.toJson()).toList()
          );
          LoggerUtil.info('Categories saved to local storage: ${loadedCategories.length}');
          return loadedCategories;
        }
      } else if (response.statusCode == 401) {
        // Create a DioException for auth error handling
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/categories'),
          response: Response(
            requestOptions: RequestOptions(path: '/categories'),
            statusCode: 401,
            data: response.data,
          ),
          type: DioExceptionType.badResponse,
        );
        await _authService.handleAuthError(dioError);
      }
      return [];
    } catch (e, stackTrace) {
      LoggerUtil.error('Error in getCategories', e, stackTrace);
      // Try to use cached data if available
      final storedCategories = _storage.read(_categoriesKey);
      if (storedCategories != null) {
        try {
          final List<ProductCategory> loadedCategories = (storedCategories as List)
              .map((json) => ProductCategory.fromJson(json))
              .toList();
          categories.assignAll(loadedCategories);
          LoggerUtil.info('Using cached categories after error: ${loadedCategories.length}');
          return loadedCategories;
        } catch (e) {
          LoggerUtil.error('Error parsing cached categories', e);
        }
      }
      return [];
    } finally {
      isLoading.value = false;
      LoggerUtil.debug('Final categories count: ${categories.length}');
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
        LoggerUtil.info('No token available');
        return null;
      }

      final response = await _provider.getCategory(token, id);
      LoggerUtil.debug('Get category by ID response: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data['data'];
        if (data != null) {
          return ProductCategory.fromJson(data);
        }
      } else if (response.statusCode == 401) {
        // Create a DioException for auth error handling
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/categories/$id'),
          response: Response(
            requestOptions: RequestOptions(path: '/categories/$id'),
            statusCode: 401,
            data: response.data,
          ),
          type: DioExceptionType.badResponse,
        );
        await _authService.handleAuthError(dioError);
      }
    } catch (e) {
      LoggerUtil.error('Error fetching category', e);
    }
    return null;
  }
}
