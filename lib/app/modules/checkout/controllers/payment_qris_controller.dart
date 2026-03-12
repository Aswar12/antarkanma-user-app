import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:antarkanma/app/data/providers/transaction_provider.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:image_picker/image_picker.dart';

class PaymentQrisController extends GetxController {
  final TransactionModel transaction;
  final TransactionProvider _transactionProvider = TransactionProvider();
  final ImagePicker _picker = ImagePicker();

  PaymentQrisController({required this.transaction});

  final RxString merchantProofPath = ''.obs;
  final RxString platformProofPath = ''.obs;

  final RxBool isUploadingMerchant = false.obs;
  final RxBool isUploadingPlatform = false.obs;

  // We are checking if payments have been completed.
  RxBool get isMerchantPaid =>
      (transaction.merchantPaidAt != null || merchantProofPath.value.isNotEmpty).obs;
  RxBool get isPlatformPaid =>
      (transaction.platformPaidAt != null || platformProofPath.value.isNotEmpty).obs;

  Future<void> pickMerchantProof() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await uploadProof('merchant', image.path);
    }
  }

  Future<void> pickPlatformProof() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await uploadProof('platform', image.path);
    }
  }

  Future<void> uploadProof(String paymentType, String imagePath) async {
    try {
      if (paymentType == 'merchant') {
        isUploadingMerchant.value = true;
      } else {
        isUploadingPlatform.value = true;
      }

      final response = await _transactionProvider.verifyQrisPayment(
        transactionId: transaction.id!,
        paymentType: paymentType,
        imagePath: imagePath,
      );

      if (response.statusCode == 200) {
        if (paymentType == 'merchant') {
          merchantProofPath.value = imagePath;
        } else {
          platformProofPath.value = imagePath;
        }

        CustomSnackbarX.showSuccess(
          title: 'Berhasil',
          message: 'Bukti pembayaran $paymentType berhasil diunggah',
        );

        // Update transaction object to reflect payment
        if (paymentType == 'merchant') {
          transaction.merchantPaidAt = DateTime.now();
        } else {
          transaction.platformPaidAt = DateTime.now();
        }

        // Check if both are paid, then close
        if (isMerchantPaid.value && isPlatformPaid.value) {
           Future.delayed(const Duration(seconds: 2), () {
             completePayment();
           });
        }
      } else {
        // Errors are usually handled inside provider, but we fallback here just in case.
        final message = response.data?['meta']?['message'] ?? 'Gagal mengunggah bukti pembayaran';
        CustomSnackbarX.showError(
          title: 'Error',
          message: message,
        );
      }
    } catch (e) {
      // Transaction Provider handles snackbars for throw dio.DioException so we might just catch it here
      print('Exception in uploadProof: $e');
    } finally {
      if (paymentType == 'merchant') {
        isUploadingMerchant.value = false;
      } else {
        isUploadingPlatform.value = false;
      }
    }
  }

  void completePayment() {
    Get.offNamed(Routes.checkoutSuccess, arguments: Get.arguments);
  }
}
