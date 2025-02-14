import 'package:get/get.dart';
import '../../../routes/app_pages.dart';
import '../../../services/storage_service.dart';

class SplashController extends GetxController {
  final StorageService storageService;

  SplashController({required this.storageService});

  @override
  void onInit() {
    super.onInit();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    try {
      await storageService.ensureInitialized();
      await Future.delayed(const Duration(seconds: 2));
      
      final token = storageService.getToken();
      final userData = storageService.getUser();
      final rememberMe = storageService.getRememberMe();

      if (token != null && userData != null && rememberMe) {
        Get.offAllNamed(Routes.userMainPage);
      } else {
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      print('Error in splash initialization: $e');
      Get.offAllNamed(Routes.login);
    }
  }
}
