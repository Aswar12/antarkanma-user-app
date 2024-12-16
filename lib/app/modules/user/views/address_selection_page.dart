import 'package:antarkanma/app/services/user_location_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';
import 'package:antarkanma/theme.dart';

class AddressSelectionPage extends StatelessWidget {
  final UserLocationController controller =
      Get.put(UserLocationController(locationService: UserLocationService()));

  AddressSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor2,
      appBar: AppBar(
        iconTheme: IconThemeData(color: logoColorSecondary),
        shadowColor: logoColorSecondary,
        backgroundColor: backgroundColor1,
        title: Text('Pilih Alamat', style: primaryTextStyle),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.userLocations.isEmpty) {
          return const Center(child: Text('Tidak ada alamat tersedia.'));
        }

        return ListView.builder(
          itemCount: controller.userLocations.length,
          itemBuilder: (context, index) {
            final address = controller.userLocations[index];
            return _buildAddressItem(address);
          },
        );
      }),
    );
  }

  Widget _buildAddressItem(UserLocationModel address) {
    return Card(
      color: backgroundColor8,
      shadowColor: backgroundColor4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          address.customerName ?? 'Alamat ${address.id}',
          style: primaryTextStyle,
        ),
        subtitle: Text(
          address.fullAddress,
          style: subtitleTextStyle,
        ),
        trailing: address.isDefault
            ? Icon(Icons.star, color: logoColorSecondary)
            : null,
        onTap: () {
          controller.selectLocation(address);
          Get.back(
              result:
                  address); // Kembali ke halaman sebelumnya dan bawa alamat yang dipilih
        },
      ),
    );
  }
}
