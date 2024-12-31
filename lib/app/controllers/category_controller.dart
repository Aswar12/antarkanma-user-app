import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/product_category_model.dart';  // Updated import
import 'package:antarkanma/app/data/providers/category_provider.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/storage_service.dart';

class CategoryController extends GetxController {
  final CategoryProvider _provider = CategoryProvider();
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storage = StorageService.instance;

  static const String CATEGORIES_STORAGE_KEY = 'categories';
  final RxList<ProductCategory> categories = <ProductCategory>[].obs;  // Updated type
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    getCategories();  // Updated method name
  }

  Future<List<ProductCategory>> getCategories() async {
    // Try to load from local storage first
    final storedCategories = _storage.getList(CATEGORIES_STORAGE_KEY);
    if (storedCategories != null) {
      categories.value =
          storedCategories.map((json) => ProductCategory.fromJson(json)).toList();
    }

    try {
      isLoading.value = true;
      final token = _authService.getToken();
      if (token == null) return [];

      final response = await _provider.getCategories(token);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final List<ProductCategory> newCategories =
            data.map((json) => ProductCategory.fromJson(json)).toList();

        categories.value = newCategories;

        // Save to local storage
        await _storage.saveList(CATEGORIES_STORAGE_KEY,
            newCategories.map((cat) => cat.toJson()).toList());
      }
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      isLoading.value = false;
    }
    return categories; // Ensure we return the categories
  }

  Future<void> refreshCategories() async {
    await getCategories();
  }
}
