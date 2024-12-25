import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../theme.dart';
import '../controllers/courier_controller.dart';

class CourierProfilePage extends GetView<CourierController> {
  const CourierProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor3,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        children: [
          _buildProfileHeader(),
          _buildMenuItems(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: backgroundColor2,
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage(controller.profileImage.value),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => Text(
                controller.courierName.value,
                style: primaryTextStyle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )),
          const SizedBox(height: 4),
          Obx(() => Text(
                'ID: ${controller.courierId.value}',
                style: subtitleTextStyle,
              )),
          const SizedBox(height: 12),
          Obx(() => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: controller.isOnline.value
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  controller.isOnline.value ? 'Aktif' : 'Tidak Aktif',
                  style: TextStyle(
                    color:
                        controller.isOnline.value ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akun',
            style: primaryTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            'Edit Profil',
            Icons.person_outline,
            onTap: () {
              // Handle edit profile
            },
          ),
          _buildMenuItem(
            'Informasi Kendaraan',
            Icons.motorcycle_outlined,
            onTap: () {
              // Handle vehicle info
            },
          ),
          _buildMenuItem(
            'Dokumen',
            Icons.description_outlined,
            onTap: () {
              // Handle documents
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Pendapatan',
            style: primaryTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            'Riwayat Pendapatan',
            Icons.account_balance_wallet_outlined,
            onTap: () {
              // Handle earnings history
            },
          ),
          _buildMenuItem(
            'Bonus Performa',
            Icons.star_outline,
            onTap: () {
              // Handle bonus info
            },
          ),
          _buildMenuItem(
            'Poin Loyalitas',
            Icons.card_giftcard_outlined,
            onTap: () {
              // Handle loyalty points
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Pengaturan',
            style: primaryTextStyle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildMenuItem(
            'Notifikasi',
            Icons.notifications_outlined,
            onTap: () {
              // Handle notifications
            },
          ),
          _buildMenuItem(
            'Pusat Bantuan',
            Icons.help_outline,
            onTap: () {
              // Handle help center
            },
          ),
          _buildMenuItem(
            'Kebijakan Privasi',
            Icons.privacy_tip_outlined,
            onTap: () {
              // Handle privacy policy
            },
          ),
          _buildMenuItem(
            'Keluar',
            Icons.logout,
            onTap: () => controller.logout(),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon,
      {required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: color ?? primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: primaryTextStyle.copyWith(
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color ?? secondaryTextColor,
            ),
          ],
        ),
      ),
    );
  }
}
