import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../data/models/category_model.dart';
import '../../config.dart';
import 'auth_service.dart';

class CategoryService extends GetxService {
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final AuthService _authService = Get.find<AuthService>();

  // Load categories from API
  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      final token = _authService.getToken();

      if (token == null) {
        print('No token available');
        return;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/product-categories'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];

        final List<CategoryModel> loadedCategories = data
            .map((json) {
              try {
                return CategoryModel.fromJson(json);
              } catch (e) {
                print('Error parsing category: $e');
                print('Problematic JSON: $json');
                return null;
              }
            })
            .whereType<CategoryModel>() // Filter out null values
            .toList();

        // Update the categories list
        categories.assignAll(loadedCategories);
      } else {
        print('Failed to load categories. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 401) {
          _authService.handleAuthError('401');
        }

        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Clear categories from local storage
  Future<void> clearLocalStorage() async {
    categories.clear();
  }

  // Get a specific category by ID
  Future<CategoryModel?> getCategoryById(int id) async {
    try {
      final token = _authService.getToken();

      if (token == null) {
        print('No token available');
        return null;
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/product-category/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final data = responseData['data'];
        if (data != null) {
          return CategoryModel.fromJson(data);
        }
        return null;
      } else {
        print('Failed to load category. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 401) {
          _authService.handleAuthError('401');
        }

        throw Exception('Failed to load category');
      }
    } catch (e) {
      print('Error fetching category: $e');
      return null;
    }
  }
}
