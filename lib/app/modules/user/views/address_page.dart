// lib/app/modules/user/views/address_page.dart

import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/app/widgets/custom_snackbar.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressPage extends GetView<UserLocationController> {
  const AddressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor8,
      appBar: AppBar(
        title: const Text('Alamat Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed('/add-address'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(controller.errorMessage.value),
                ElevatedButton(
                  onPressed: controller.loadAddresses,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        if (controller.addresses.isEmpty) {
          return _buildEmptyState();
        }

        return _buildAddressList();
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Belum ada alamat tersimpan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Get.toNamed('/main/add-address'),
            child: const Text('Tambah Alamat'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return RefreshIndicator(
      onRefresh: controller.loadAddresses,
      child: ListView.builder(
        itemCount: controller.addresses.length,
        itemBuilder: (context, index) {
          final address = controller.addresses[index];
          return _buildAddressItem(address);
        },
      ),
    );
  }

  Widget _buildAddressItem(UserLocationModel address) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                address.customerName ?? 'Alamat ${address.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (address.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Utama',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(address.fullAddress),
            Text(address.phoneNumber),
            Text(
              address.addressType,
              style: TextStyle(
                color: logoColorSecondary,
              ),
            ),
          ],
        ),
        onTap: () => _showAddressOptions(address),
      ),
    );
  }

  void _showAddressOptions(UserLocationModel address) {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        child: Wrap(
          children: [
            ListTile(
              iconColor: logoColorSecondary,
              leading: Icon(
                Icons.edit,
                color: logoColorSecondary,
              ),
              title: Text(
                'Edit Alamat',
                style: primaryTextStyle,
              ),
              onTap: () {
                Get.back();
                Get.toNamed('/main/edit-address', arguments: address);
              },
            ),
            if (!address.isDefault)
              ListTile(
                leading: Icon(
                  color: logoColorSecondary,
                  Icons.check_circle_outline,
                ),
                title: Text(
                  'Jadikan Alamat Utama',
                  style: primaryTextStyle,
                ),
                onTap: () {
                  Get.back();
                  _setDefaultAddress(address);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Hapus Alamat',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                _deleteAddress(address);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _setDefaultAddress(UserLocationModel address) async {
    final result = await controller.setDefaultAddress(address.id!);
    if (result) {
      showCustomSnackbar(
        title: 'Sukses',
        message: 'Alamat utama berhasil diubah',
        backgroundColor: Colors.green,
      );
    } else {
      showCustomSnackbar(
        title: 'Gagal',
        message: controller.errorMessage.value,
        backgroundColor: Colors.red,
      );
    }
  }

// Update fungsi _deleteAddress
  void _deleteAddress(UserLocationModel address) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus Alamat'),
        content: const Text('Anda yakin ingin menghapus alamat ini?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await controller.deleteAddress(address.id!);
      if (result) {
        showCustomSnackbar(
          title: 'Sukses',
          message: 'Alamat berhasil dihapus',
          backgroundColor: Colors.green,
        );
      } else {
        showCustomSnackbar(
          title: 'Gagal',
          message: controller.errorMessage.value,
          backgroundColor: Colors.red,
        );
      }
    }
  }
}
