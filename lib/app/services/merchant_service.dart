import 'package:antarkanma/app/data/providers/merchant_provider.dart';
import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:image_picker/image_picker.dart';

class MerchantService {
  final MerchantProvider _merchantProvider = MerchantProvider();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService.instance;

  // Ambil token dari AuthService
  get token => _authService.getToken();

  // Ambil user dari StorageService
  Map<String, dynamic>? get user => _storageService.getUser();

  // Ambil owner ID dari user
  int? get ownerId =>
      user != null ? int.tryParse(user!['id'].toString()) : null;

  MerchantModel? _currentMerchant;

  Future<MerchantModel?> getMerchant() async {
    try {
      if (ownerId == null) {
        throw Exception(
            "Owner ID is null. User must be logged in to fetch merchant.");
      }

      final response =
          await _merchantProvider.getMerchantsByOwnerId(token, ownerId!);
      print('API Response: ${response.data}');

      // Karena merchant selalu single, ambil data pertama dari list
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

      // Check if the response has the expected structure
      if (response.data != null &&
          response.data['meta'] != null &&
          response.data['meta']['status'] == 'success' &&
          response.data['data'] != null &&
          response.data['data']['data'] is List) {
        // Access the actual product data array from the paginated response
        final productsData = response.data['data']['data'] as List;

        // Convert each product JSON to ProductModel
        return productsData.map((json) => ProductModel.fromJson(json)).toList();
      }

      print('Unexpected response structure: ${response.data}');
      return [];
    } catch (e) {
      print('Error fetching merchant products: $e');
      return [];
    }
  }

  Future<bool> createProduct(Map<String, dynamic> productData, List<XFile> images) async {
    try {
      if (_currentMerchant?.id == null) {
        final merchant = await getMerchant();
        if (merchant == null) {
          throw Exception('Failed to get merchant information');
        }
      }

      // First create the product
      final productResponse = await _merchantProvider.createProduct(
        token,
        _currentMerchant!.id!,
        productData,
      );

      if (productResponse.statusCode != 200 && productResponse.statusCode != 201) {
        throw Exception('Failed to create product');
      }

      // Get the created product ID
      final productId = productResponse.data['data']['id'];

      // Then upload the gallery images
      if (images.isNotEmpty) {
        final imagePaths = images.map((image) => image.path).toList();
        final galleryResponse = await _merchantProvider.uploadProductGallery(
          token,
          productId,
          imagePaths,
        );

        if (galleryResponse.statusCode != 200 && galleryResponse.statusCode != 201) {
          throw Exception('Failed to upload product gallery');
        }
      }

      return true;
    } catch (e) {
      print('Error creating product: $e');
      return false;
    }
  }

  Future<bool> updateOperationalHours(String openingTime, String closingTime,
      List<String> operatingDays) async {
    try {
      // Validasi input dasar
      if (openingTime.isEmpty || closingTime.isEmpty || operatingDays.isEmpty) {
        print('Validation error: All fields must be filled');
        return false;
      }

      // Validasi format waktu
      final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
      if (!timeRegex.hasMatch(openingTime) ||
          !timeRegex.hasMatch(closingTime)) {
        print('Validation error: Invalid time format. Use HH:mm');
        return false;
      }

      // Pastikan merchant ID tersedia
      if (_currentMerchant?.id == null) {
        print('Error: Merchant ID not found');
        return false;
      }

      // Siapkan payload untuk update
      final payload = {
        'opening_time': openingTime,
        'closing_time': closingTime,
        'operating_days': operatingDays, // Send as an array
      };

      print('Updating merchant ${_currentMerchant!.id} with payload: $payload');

      // Panggil provider untuk update merchant
      final response = await _merchantProvider.updateMerchant(
          token, _currentMerchant!.id!, payload);

      // Periksa respons dari API
      if (response.statusCode == 200) {
        print('Operational hours updated successfully');
        return true;
      } else {
        print(
            'Failed to update operational hours: ${response.data['message']}');
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
      // Pastikan merchant ID tersedia
      if (_currentMerchant?.id == null) {
        print('Error: Merchant ID not found');
        return false;
      }

      // Siapkan payload
      final payload = {
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (description != null) 'description': description,
      };

      // Cek apakah ada data yang akan diupdate
      if (payload.isEmpty) {
        print('No data to update');
        return false;
      }

      // Panggil provider untuk update merchant
      final response = await _merchantProvider.updateMerchant(
          token, _currentMerchant!.id!, payload);

      // Periksa respons dari API
      if (response.statusCode == 200) {
        print('Merchant details updated successfully');
        return true;
      } else {
        print('Failed to update merchant details: ${response.data['message']}');
        return false;
      }
    } catch (e) {
      print('Error updating merchant details: $e');
      return false;
    }
  }
}
