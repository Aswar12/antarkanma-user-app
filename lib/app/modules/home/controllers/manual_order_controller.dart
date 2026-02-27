import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import 'package:antarkanma/config.dart';
import 'package:antarkanma/app/services/storage_service.dart';
import '../../../routes/app_pages.dart';
import '../../../controllers/user_location_controller.dart';

class ManualOrderItem {
  String name;
  int quantity;
  double estimatedPrice;
  String note;
  Rx<File?> image = Rx<File?>(null);

  final nameController = TextEditingController();
  final qtyController = TextEditingController(text: '1');
  final priceController = TextEditingController();
  final noteController = TextEditingController();

  final VoidCallback? onUpdate;

  ManualOrderItem({
    this.name = '',
    this.quantity = 1,
    this.estimatedPrice = 0,
    this.note = '',
    this.onUpdate,
  }) {
    nameController.text = name;
    qtyController.text = quantity.toString();
    priceController.text = estimatedPrice > 0 ? estimatedPrice.toString() : '';
    noteController.text = note;

    nameController.addListener(() {
      name = nameController.text;
    });
    qtyController.addListener(() {
      quantity = int.tryParse(qtyController.text) ?? 1;
      onUpdate?.call();
    });
    priceController.addListener(() {
      estimatedPrice = double.tryParse(priceController.text) ?? 0;
      onUpdate?.call();
    });
    noteController.addListener(() {
      note = noteController.text;
    });
  }
}

class JastipStore {
  final storeNameController = TextEditingController();
  final storeAddressController = TextEditingController();
  final items = <ManualOrderItem>[].obs;

  // Callback to parent controller for total calc
  final VoidCallback? onUpdate;

  JastipStore({this.onUpdate}) {
    items.add(ManualOrderItem(onUpdate: onUpdate));
  }

  void addItem() {
    items.add(ManualOrderItem(onUpdate: onUpdate));
  }

  void removeItem(int index) {
    if (items.length > 1) {
      items.removeAt(index);
      onUpdate?.call();
    }
  }
}

class ManualOrderController extends GetxController {
  final stores = <JastipStore>[].obs;

  final deliveryAddress = 'Pilih Alamat'.obs;
  final totalEstimatedPrice = 0.0.obs;
  final isLoading = false.obs;

  final ImagePicker _picker = ImagePicker();

  @override
  void onInit() {
    super.onInit();
    addStore(); // Start with 1 empty store
    _loadDefaultAddress();
  }

  void addStore() {
    stores.add(JastipStore(onUpdate: calculateTotal));
  }

  void removeStore(int index) {
    if (stores.length > 1) {
      stores.removeAt(index);
      calculateTotal();
    }
  }

  void _loadDefaultAddress() {
    if (Get.isRegistered<UserLocationController>()) {
      final locController = Get.find<UserLocationController>();
      if (locController.selectedLocation != null) {
        deliveryAddress.value = locController.selectedLocation!.address;
      }
    }
  }

  Future<void> pickImage(int storeIndex, int itemIndex) async {
    final XFile? photo =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (photo != null) {
      stores[storeIndex].items[itemIndex].image.value = File(photo.path);
    }
  }

  void calculateTotal() {
    double total = 0;
    for (var store in stores) {
      for (var item in store.items) {
        total += (item.quantity * item.estimatedPrice);
      }
    }
    totalEstimatedPrice.value = total;
  }

  void selectLocation() {
    Get.snackbar(
        'Info', 'Fitur pilih lokasi akan menggunakan data UserLocation');
  }

  Future<void> submitOrder() async {
    // Validate each store
    for (int i = 0; i < stores.length; i++) {
      var store = stores[i];
      if (store.storeNameController.text.isEmpty) {
        Get.snackbar('Error', 'Nama Toko #${i + 1} wajib diisi');
        return;
      }
      if (store.storeAddressController.text.isEmpty) {
        Get.snackbar('Error', 'Alamat Toko #${i + 1} wajib diisi');
        return;
      }

      bool hasValidItem = false;
      for (var item in store.items) {
        if (item.name.isNotEmpty) hasValidItem = true;
      }

      if (!hasValidItem) {
        Get.snackbar(
            'Error', 'Minimal isi satu barang belanjaan di Toko #${i + 1}');
        return;
      }
    }

    final locController = Get.find<UserLocationController>();
    if (locController.selectedLocation == null) {
      Get.snackbar('Error',
          'Mohon pilih alamat pengiriman di Halaman Utama atau Profil');
      return;
    }

    isLoading.value = true;

    try {
      String token = StorageService.instance.getToken() ?? '';

      // Note: Backend Logic needs to be updated to handle multi-store.
      // For now, if single store, we use the old structure.
      // If multi-store, we might need to loop and create multiple orders OR update backend.
      // Assuming Backend only accepts 1 store per Request for now, we will LOOP requests.
      // This is a temporary Frontend-side Multi-Order solution.

      int successCount = 0;

      for (var store in stores) {
        var formData = dio.FormData.fromMap({
          'user_location_id': locController.selectedLocation!.id,
          'store_name': store.storeNameController.text,
          'store_address': store.storeAddressController.text,
          'delivery_address': locController.selectedLocation!.address,
          // Total per store or Global?
          // Backend uses `total_estimated_price` for the Transaction.
          // If we split into multiple orders, each should span a transaction or grouped?
          // Simplest approach: Items total for this store.
          'total_estimated_price': store.items.fold(
              0.0, (sum, item) => sum + (item.quantity * item.estimatedPrice)),
        });

        for (int i = 0; i < store.items.length; i++) {
          var item = store.items[i];
          formData.fields.addAll([
            MapEntry('items[$i][name]', item.name),
            MapEntry('items[$i][quantity]', item.quantity.toString()),
            MapEntry(
                'items[$i][estimated_price]', item.estimatedPrice.toString()),
            MapEntry('items[$i][note]', item.note),
          ]);

          if (item.image.value != null) {
            formData.files.add(MapEntry(
              'items[$i][image]',
              await dio.MultipartFile.fromFile(item.image.value!.path),
            ));
          }
        }

        var dioClient = dio.Dio();
        var response = await dioClient.post(
          '${Config.baseUrl}/manual-order',
          data: formData,
          options: dio.Options(
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ),
        );

        if (response.statusCode == 200 &&
            response.data['meta']['status'] == 'success') {
          successCount++;
        }
      }

      if (successCount == stores.length) {
        Get.defaultDialog(
            title: 'Berhasil',
            middleText: successCount > 1
                ? '$successCount Pesanan Jastip berhasil dibuat!'
                : 'Pesanan Jastip berhasil dibuat!',
            textConfirm: 'OK',
            onConfirm: () {
              Get.back(); // close dialog
              Get.back(); // back to home
            });
      } else {
        Get.snackbar('Info',
            'Berhasil membuat $successCount dari ${stores.length} pesanan. Cek riwayat transaksi.');
      }
    } on dio.DioException catch (e) {
      print('Manual Order Error: ${e.response?.data}');
      String message = e.response?.data['meta']['message'] ??
          e.message ??
          'Terjadi kesalahan';
      Get.snackbar('Error', message);
    } catch (e) {
      print('Manual Order Error: $e');
      Get.snackbar('Error', 'Terjadi kesalahan internal');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    for (var store in stores) {
      store.storeNameController.dispose();
      store.storeAddressController.dispose();
    }
    super.onClose();
  }
}
