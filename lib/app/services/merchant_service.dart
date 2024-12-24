import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/data/providers/auth_provider.dart';
import 'package:antarkanma/app/data/providers/merchant_provider.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';

class MerchantService {
  final AuthProvider _authProvider = AuthProvider();
  final StorageService _storageService = StorageService.instance;
  final MerchantProvider _merchantProvider = MerchantProvider();

  Future<MerchantModel?> fetchMerchantData() async {
    try {
      final token = _storageService.getToken();

      if (token == null) {
        showCustomSnackbar(
            title: 'Error', message: 'Token tidak valid', isError: true);
        return null;
      }

      final userData = _storageService.getUser();
      if (userData == null || userData['id'] == null) {
        showCustomSnackbar(
            title: 'Error', message: 'User ID tidak ditemukan', isError: true);
        return null;
      }

      final userId = userData['id'].toString(); // Convert to string
      final response =
          await _merchantProvider.getMerchantsByOwnerId(userId, token);

      if (response.statusCode == 200) {
        if (response.data is List) {
          if (response.data.isNotEmpty) {
            return MerchantModel.fromJson(
                response.data[0]); // Return the first MerchantModel instance
          } else {
            showCustomSnackbar(
                title: 'Error',
                message: 'Data merchant tidak ditemukan',
                isError: true);
            return null;
          }
        } else if (response.data is Map<String, dynamic>) {
          return MerchantModel.fromJson(
              response.data); // Return the MerchantModel instance
        }
      }

      showCustomSnackbar(
          title: 'Error',
          message: 'Gagal mengambil data merchant',
          isError: true);
      return null;
    } catch (e) {
      showCustomSnackbar(
          title: 'Error',
          message: 'Gagal mengambil data merchant: ${e.toString()}',
          isError: true);
      return null;
    }
  }
}
