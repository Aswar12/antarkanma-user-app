import 'package:antarkanma/app/modules/merchant/controllers/merchant_profile_controller.dart';
import 'package:antarkanma/app/services/merchant_service.dart';
import 'package:antarkanma/app/widgets/logout_confirmation_dialog.dart';
import 'package:antarkanma/app/widgets/merchant_profile_image.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MerchantProfilePage extends GetView<MerchantProfileController> {
  final MerchantService merchantService = Get.find<MerchantService>();

  MerchantProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor3,
      appBar: AppBar(
        title: Text(
          'Profil Toko',
          style: primaryTextStyle.copyWith(color: logoColor),
        ),
        backgroundColor: transparentColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(Dimenssions.width16),
          children: [
            _buildHeader(),
            _buildStoreInfoCard(),
            _buildOperationalHoursCard(),
            _buildShippingSettingsCard(),
            _buildPaymentMethodsCard(),
            _buildMenuSection(),
            SizedBox(height: Dimenssions.height10),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final merchant = controller.merchant;
    return Container(
      height: Dimenssions.height200,
      margin: EdgeInsets.only(bottom: Dimenssions.height16),
      child: Stack(
        children: [
          Container(
            height: Dimenssions.height150,
            decoration: BoxDecoration(
              color: backgroundColor2,
              borderRadius: BorderRadius.circular(Dimenssions.radius15),
              image: merchant?.logo != null
                  ? DecorationImage(
                      image: NetworkImage(merchant!.logo!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  _buildProfileImage(merchant),
                  SizedBox(height: Dimenssions.height8),
                  Text(
                    controller.merchantName,
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font18,
                      fontWeight: semiBold,
                    ),
                  ),
                  Text(
                    controller.merchantDescription,
                    style: secondaryTextStyle.copyWith(
                      fontSize: Dimenssions.font14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(dynamic merchant) {
    return GestureDetector(
      onTap: () => Get.toNamed('/merchant/edit-profile'),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: CircleAvatar(
          radius: Dimenssions.height40,
          backgroundColor: Colors.grey[300],
          backgroundImage:
              merchant?.logo != null ? NetworkImage(merchant.logo) : null,
          child: merchant?.logo == null
              ? Icon(
                  Icons.store,
                  size: Dimenssions.height40,
                  color: Colors.grey[600],
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStoreInfoCard() {
    return Card(
      margin: EdgeInsets.only(bottom: Dimenssions.height16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimenssions.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: logoColor),
                SizedBox(width: Dimenssions.width8),
                Text(
                  'Informasi Toko',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font16,
                    fontWeight: semiBold,
                  ),
                ),
              ],
            ),
            Divider(height: Dimenssions.height24),
            _buildInfoRow('Email', 'merchant@example.com'),
            _buildInfoRow('Telepon', '+62 812-3456-7890'),
            _buildInfoRow('Alamat', 'Jl. Example No. 123, Kota Example'),
            SizedBox(height: Dimenssions.height16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.toNamed('/merchant/edit-store-info'),
                icon: Icon(Icons.edit, size: Dimenssions.height18),
                label: Text('Edit Informasi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: logoColor,
                  side: BorderSide(color: logoColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimenssions.height8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: Dimenssions.width100,
            child: Text(label, style: secondaryTextStyle),
          ),
          Text(': ', style: secondaryTextStyle),
          Expanded(
            child: Text(value, style: primaryTextStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationalHoursCard() {
    return Card(
      margin: EdgeInsets.only(bottom: Dimenssions.height16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimenssions.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: logoColor),
                SizedBox(width: Dimenssions.width8),
                Text(
                  'Jam Operasional',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font16,
                    fontWeight: semiBold,
                  ),
                ),
              ],
            ),
            Divider(height: Dimenssions.height24),
            _buildTimeRow('Senin - Jumat', '08:00 - 17:00'),
            _buildTimeRow('Sabtu', '09:00 - 15:00'),
            _buildTimeRow('Minggu', 'Tutup'),
            SizedBox(height: Dimenssions.height16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.toNamed('/merchant/edit-hours'),
                icon: Icon(Icons.edit, size: Dimenssions.height18),
                label: Text('Atur Jam Operasional'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: logoColor,
                  side: BorderSide(color: logoColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(String day, String hours) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimenssions.height8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: secondaryTextStyle),
          Text(hours, style: primaryTextStyle),
        ],
      ),
    );
  }

  Widget _buildShippingSettingsCard() {
    return Card(
      margin: EdgeInsets.only(bottom: Dimenssions.height16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimenssions.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: logoColor),
                SizedBox(width: Dimenssions.width8),
                Text(
                  'Pengaturan Pengiriman',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font16,
                    fontWeight: semiBold,
                  ),
                ),
              ],
            ),
            Divider(height: Dimenssions.height24),
            Text(
              'Wilayah Pengiriman',
              style: primaryTextStyle.copyWith(fontWeight: medium),
            ),
            SizedBox(height: Dimenssions.height8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAreaChip('Jakarta'),
                _buildAreaChip('Bogor'),
                _buildAreaChip('Depok'),
              ],
            ),
            SizedBox(height: Dimenssions.height16),
            Text(
              'Biaya Pengiriman',
              style: primaryTextStyle.copyWith(fontWeight: medium),
            ),
            SizedBox(height: Dimenssions.height8),
            _buildShippingCostRow('Regular', 'Rp 10.000'),
            _buildShippingCostRow('Express', 'Rp 20.000'),
            SizedBox(height: Dimenssions.height16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.toNamed('/merchant/edit-shipping'),
                icon: Icon(Icons.edit, size: Dimenssions.height18),
                label: Text('Atur Pengiriman'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: logoColor,
                  side: BorderSide(color: logoColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaChip(String area) {
    return Chip(
      label: Text(area),
      backgroundColor: logoColor.withOpacity(0.1),
      labelStyle: TextStyle(color: logoColor),
    );
  }

  Widget _buildShippingCostRow(String type, String cost) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimenssions.height8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(type, style: secondaryTextStyle),
          Text(cost, style: primaryTextStyle),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Card(
      margin: EdgeInsets.only(bottom: Dimenssions.height16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimenssions.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: logoColor),
                SizedBox(width: Dimenssions.width8),
                Text(
                  'Metode Pembayaran',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font16,
                    fontWeight: semiBold,
                  ),
                ),
              ],
            ),
            Divider(height: Dimenssions.height24),
            _buildPaymentMethodRow('Transfer Bank', true),
            _buildPaymentMethodRow('E-Wallet', true),
            _buildPaymentMethodRow('COD', false),
            SizedBox(height: Dimenssions.height16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Get.toNamed('/merchant/edit-payment'),
                icon: Icon(Icons.edit, size: Dimenssions.height18),
                label: Text('Atur Pembayaran'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: logoColor,
                  side: BorderSide(color: logoColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodRow(String method, bool isActive) {
    return Padding(
      padding: EdgeInsets.only(bottom: Dimenssions.height8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(method, style: primaryTextStyle),
          Switch(
            value: isActive,
            onChanged: (value) {
              // Handle payment method toggle
            },
            activeColor: logoColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Card(
      margin: EdgeInsets.only(bottom: Dimenssions.height16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
      ),
      child: Padding(
        padding: EdgeInsets.all(Dimenssions.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Menu Lainnya',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font16,
                fontWeight: semiBold,
              ),
            ),
            Divider(height: Dimenssions.height24),
            _buildMenuItem(
              icon: Icons.shopping_bag_outlined,
              title: 'Orderan Kamu',
              onTap: () => Get.toNamed('/merchant/orders'),
            ),
            _buildMenuItem(
              icon: Icons.headset_mic_outlined,
              title: 'Bantuan',
              onTap: () => Get.toNamed('/merchant/help'),
            ),
            SizedBox(height: Dimenssions.height16),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () => Get.dialog(const LogoutConfirmationDialog()),
                icon: Icon(Icons.logout, color: alertColor),
                label: Text('Keluar'),
                style: TextButton.styleFrom(
                  backgroundColor: alertColor.withOpacity(0.1),
                  foregroundColor: alertColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: logoColor),
      title: Text(title, style: primaryTextStyle),
      trailing: Icon(Icons.arrow_forward_ios, size: Dimenssions.height16),
      onTap: onTap,
    );
  }
}
