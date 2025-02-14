import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/product_category_model.dart';
import 'package:antarkanma/app/data/providers/category_provider.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/routes/app_pages.dart';

class CategoryController extends GetxController {
  final CategoryProvider _provider = CategoryProvider();
  final StorageService _storage = StorageService.instance;

  static const String CATEGORIES_STORAGE_KEY = 'categories_data';
  final RxList<ProductCategory> categories = <ProductCategory>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    await _storage.ensureInitialized();
    getCategories(silent: true); // Load silently on init
  }

  Future<List<ProductCategory>> getCategories({bool silent = false}) async {
    // Try to load from local storage first
    final storedData = _storage.getMap(CATEGORIES_STORAGE_KEY);
    if (storedData != null) {
      try {
        final List<dynamic> storedCategories = storedData['categories'] ?? [];
        categories.value = storedCategories
            .map((json) => ProductCategory.fromJson(json))
            .toList();
      } catch (e) {
        print('Error parsing stored categories: $e');
      }
    }

    try {
      if (!silent) isLoading.value = true;
      final token = _storage.getString('token');
      if (token == null) {
        // If no token and not a silent request, redirect to login
        if (!silent) Get.offAllNamed(Routes.login);
        return categories;
      }

      final response = await _provider.getCategories(token, silent: silent);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final List<ProductCategory> newCategories =
            data.map((json) => ProductCategory.fromJson(json)).toList();

        categories.value = newCategories;

        // Save to local storage
        await _storage.saveMap(CATEGORIES_STORAGE_KEY, {
          'categories': newCategories.map((cat) => cat.toJson()).toList(),
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (!silent) {
        Get.snackbar(
          'Error',
          'Gagal memuat kategori',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      if (!silent) isLoading.value = false;
    }
    return categories;
  }

  Future<void> refreshCategories() async {
    await getCategories(silent: false);
  }
}
