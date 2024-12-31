import 'package:antarkanma/app/data/providers/merchant_provider.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/services/product_service.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class MerchantService {
  final MerchantProvider _merchantProvider = MerchantProvider();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService.instance;
  final ProductService _productService = Get.find<ProductService>();

  get token => _authService.getToken();
  Map<String, dynamic>? get user => _storageService.getUser();
  int? get ownerId => user != null ? int.tryParse(user!['id'].toString()) : null;

  MerchantModel? _currentMerchant;

  Future<MerchantModel?> getMerchant() async {
    try {
      if (ownerId == null) {
        throw Exception("Owner ID is null. User must be logged in to fetch merchant.");
      }

      final response = await _merchantProvider.getMerchantsByOwnerId(token, ownerId!);

      if (response.data != null &&
          response.data['data'] is List &&
          response.data['data'].isNotEmpty) {
        _currentMerchant = MerchantModel.fromJson(response.data['data'][0]);
        return _currentMerchant;
      }
      return null;
    } catch (e) {
      print('Error fetching merchant: $e');
      return null;
    }
  }

  Future<List<ProductModel>> getMerchantProducts() async {
    try {
      if (_currentMerchant?.id == null) {
        final merchant = await getMerchant();
        if (merchant == null) {
          throw Exception('Failed to get merchant information');
        }
      }

      final response = await _merchantProvider.getMerchantProducts(
        token,
        _currentMerchant!.id!,
      );

      if (response.data != null &&
          response.data['meta'] != null &&
          response.data['meta']['status'] == 'success' &&
          response.data['data'] != null &&
          response.data['data']['data'] is List) {
        final productsData = response.data['data']['data'] as List;
        return productsData.map((json) => ProductModel.fromJson(json)).toList();
      }

      print('Unexpected response structure: ${response.data}');
      return [];
    } catch (e) {
      print('Error fetching merchant products: $e');
      return [];
    }
  }

  Future<bool> createProduct(
      Map<String, dynamic> productData, List<XFile> images) async {
    try {
      if (_currentMerchant?.id == null) {
        final merchant = await getMerchant();
        if (merchant == null) {
          throw Exception('Failed to get merchant information');
        }
      }

      final productResponse = await _merchantProvider.createProduct(
        token,
        _currentMerchant!.id!,
        productData,
      );

      if (productResponse.data == null || 
          productResponse.data['meta'] == null || 
          productResponse.data['meta']['status'] != 'success') {
        throw Exception(productResponse.data?['meta']?['message'] ?? 'Failed to create product');
      }

      final createdProductData = productResponse.data['data'];
      final productId = createdProductData['id'];

      if (images.isNotEmpty) {
        final imagePaths = images.map((image) => image.path).toList();
        final galleryResponse = await _merchantProvider.uploadProductGallery(
          token,
          productId,
          imagePaths,
        );

        if (galleryResponse.data == null || 
            galleryResponse.data['meta'] == null || 
            galleryResponse.data['meta']['status'] != 'success') {
          throw Exception(galleryResponse.data?['meta']?['message'] ?? 'Failed to upload gallery');
        }

        if (galleryResponse.data['data'] != null) {
          createdProductData['gallery'] = galleryResponse.data['data'];
        }
      }

      await _productService.addProductToLocal(createdProductData);
      return true;
    } catch (e) {
      print('Error creating product: $e');
      return false;
    }
  }

  Future<bool> updateProduct(
      int productId, Map<String, dynamic> productData, List<XFile> newImages) async {
    try {
      if (_currentMerchant?.id == null) {
        final merchant = await getMerchant();
        if (merchant == null) {
          throw Exception('Failed to get merchant information');
        }
      }

      // Update product details
      final productResponse = await _merchantProvider.updateProduct(
        token,
        productId,
        productData,
      );

      if (productResponse.data == null || 
          productResponse.data['meta'] == null || 
          productResponse.data['meta']['status'] != 'success') {
        throw Exception(productResponse.data?['meta']?['message'] ?? 'Failed to update product');
      }

      // Upload new images if any
      if (newImages.isNotEmpty) {
        final imagePaths = newImages.map((image) => image.path).toList();
        final galleryResponse = await _merchantProvider.uploadProductGallery(
          token,
          productId,
          imagePaths,
        );

        if (galleryResponse.data == null || 
            galleryResponse.data['meta'] == null || 
            galleryResponse.data['meta']['status'] != 'success') {
          throw Exception(galleryResponse.data?['meta']?['message'] ?? 'Failed to upload gallery');
        }
      }

      return true;
    } catch (e) {
      print('Error updating product: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> updateProductGallery(
      int productId, int galleryId, String imagePath) async {
    try {
      final response = await _merchantProvider.updateProductGallery(
        token,
        productId,
        galleryId,
        imagePath,
      );

      if (response.data != null && 
          response.data['meta'] != null && 
          response.data['meta']['status'] == 'success') {
        return {
          'success': true,
          'message': response.data['meta']['message'] ?? 'Gallery image updated successfully',
          'data': response.data['data']
        };
      } else {
        return {
          'success': false,
          'message': response.data?['meta']?['message'] ?? 'Failed to update gallery image'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error updating gallery image: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteProductGallery(
      int productId, int galleryId) async {
    try {
      final response = await _merchantProvider.deleteProductGallery(
        token,
        productId,
        galleryId,
      );

      if (response.data != null && 
          response.data['meta'] != null && 
          response.data['meta']['status'] == 'success') {
        return {
          'success': true,
          'message': response.data['meta']['message'] ?? 'Gallery image deleted successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data?['meta']?['message'] ?? 'Failed to delete gallery image'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error deleting gallery image: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteProduct(int productId) async {
    try {
      final response = await _merchantProvider.deleteProduct(token, productId);

      if (response.data != null && 
          response.data['meta'] != null && 
          response.data['meta']['status'] == 'success') {
        return {
          'success': true,
          'message': response.data['meta']['message'] ?? 'Product deleted successfully'
        };
      } else {
        return {
          'success': false,
          'message': response.data?['meta']?['message'] ?? 'Failed to delete product'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error deleting product: $e'};
    }
  }

  Future<bool> updateOperationalHours(
      String openingTime, String closingTime, List<String> operatingDays) async {
    try {
      if (openingTime.isEmpty || closingTime.isEmpty || operatingDays.isEmpty) {
        print('Validation error: All fields must be filled');
        return false;
      }

      final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
      if (!timeRegex.hasMatch(openingTime) || !timeRegex.hasMatch(closingTime)) {
        print('Validation error: Invalid time format. Use HH:mm');
        return false;
      }

      if (_currentMerchant?.id == null) {
        print('Error: Merchant ID not found');
        return false;
      }

      final payload = {
        'opening_time': openingTime,
        'closing_time': closingTime,
        'operating_days': operatingDays,
      };

      final response = await _merchantProvider.updateMerchant(
          token, _currentMerchant!.id!, payload);

      if (response.data != null && 
          response.data['meta'] != null && 
          response.data['meta']['status'] == 'success') {
        print('Operational hours updated successfully');
        return true;
      } else {
        print('Failed to update operational hours: ${response.data?['meta']?['message']}');
        return false;
      }
    } catch (e) {
      print('Error updating operational hours: $e');
      return false;
    }
  }

  Future<bool> updateMerchantDetails({
    String? name,
    String? address,
    String? phoneNumber,
    String? description,
  }) async {
    try {
      if (_currentMerchant?.id == null) {
        print('Error: Merchant ID not found');
        return false;
      }

      final payload = {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (description != null) 'description': description,
      };

      if (payload.isEmpty) {
        print('No data to update');
        return false;
      }

      final response = await _merchantProvider.updateMerchant(
          token, _currentMerchant!.id!, payload);

      if (response.data != null && 
          response.data['meta'] != null && 
          response.data['meta']['status'] == 'success') {
        print('Merchant details updated successfully');
        return true;
      } else {
        print('Failed to update merchant details: ${response.data?['meta']?['message']}');
        return false;
      }
    } catch (e) {
      print('Error updating merchant details: $e');
      return false;
    }
  }
}
