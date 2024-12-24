// ignore_for_file: deprecated_member_use

import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/user_location_service.dart';
import 'package:antarkanma/app/widgets/logout_confirmation_dialog.dart';
import 'package:antarkanma/app/widgets/profile_image.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfilePage extends GetView<AuthController> {
  final AuthService authService = Get.find<AuthService>();
  late final UserLocationController locationController;

  ProfilePage({super.key}) {
    if (!Get.isRegistered<UserLocationController>()) {
      Get.put(UserLocationController(
          locationService: Get.find<UserLocationService>()));
    }
    locationController = Get.find<UserLocationController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor3,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(authService),
              _buildAddressCard(),
              _buildMenuSection(),
              SizedBox(height: Dimenssions.height10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthService authService) {
    final user = authService.getUser();
    return SizedBox(
      height: Dimenssions.height250,
      child: Stack(
        children: [
          // Background Image with Overlay
          SizedBox(
            width: double.infinity,
            height: Dimenssions.height250,
            child: user?.profilePhotoUrl != null
                ? Stack(
                    children: [
                      // Blurred Background Image
                      Image.network(
                        user!.profilePhotoUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      // Dark Overlay
                      Container(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ],
                  )
                : Container(
                    color: backgroundColor2,
                  ),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Image
                GestureDetector(
                  onTap: () => Get.toNamed('/main/edit-profile'),
                  child: Container(
                    margin: EdgeInsets.only(top: Dimenssions.height30),
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'profile_image',
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: user != null
                                ? ProfileImage(
                                    user: user,
                                    size: Dimenssions.height100,
                                  )
                                : CircleAvatar(
                                    radius: Dimenssions.height50,
                                    backgroundColor: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      size: Dimenssions.height50,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(Dimenssions.height5),
                            decoration: BoxDecoration(
                              color: logoColorSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.edit,
                              size: Dimenssions.height15,
                              color: backgroundColor1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Dimenssions.height15),
                // User Info
                Text(
                  authService.userName,
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font20,
                    fontWeight: semiBold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: Dimenssions.height5),
                Text(
                  authService.userPhone,
                  style: secondaryTextStyle.copyWith(
                    fontSize: Dimenssions.font14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return GetBuilder<UserLocationController>(
      builder: (locationController) {
        return Container(
          margin: EdgeInsets.all(Dimenssions.height15),
          padding: EdgeInsets.all(Dimenssions.height15),
          decoration: BoxDecoration(
            color: backgroundColor2,
            borderRadius: BorderRadius.circular(Dimenssions.radius15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: logoColorSecondary,
                        size: Dimenssions.height22,
                      ),
                      SizedBox(width: Dimenssions.width10),
                      Text(
                        'Alamat Pengiriman',
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font16,
                          fontWeight: semiBold,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Get.toNamed('/main/address'),
                    child: Text(
                      'Lihat Semua',
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font14,
                        color: logoColorSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Dimenssions.height10),
              if (locationController.defaultAddress != null) ...[
                Container(
                  padding: EdgeInsets.all(Dimenssions.height10),
                  decoration: BoxDecoration(
                    color: backgroundColor3,
                    borderRadius: BorderRadius.circular(Dimenssions.radius15),
                  ),
                  child: Obx(() => Text(
                        locationController.defaultAddress!.fullAddress,
                        style: secondaryTextStyle.copyWith(
                          fontSize: Dimenssions.font14,
                        ),
                      )),
                ),
              ] else ...[
                Text(
                  'Tambahkan alamat pengiriman Anda untuk memudahkan proses pengiriman',
                  style: secondaryTextStyle.copyWith(
                    fontSize: Dimenssions.font14,
                  ),
                ),
                SizedBox(height: Dimenssions.height15),
                SizedBox(
                  height: Dimenssions.height45,
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Get.toNamed('/main/add-address'),
                    style: TextButton.styleFrom(
                      backgroundColor: logoColorSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimenssions.radius15),
                      ),
                    ),
                    child: Text(
                      'Tambah Alamat',
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font14,
                        color: backgroundColor1,
                        fontWeight: medium,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuSection() {
    return Container(
      margin: EdgeInsets.all(Dimenssions.height15),
      padding: EdgeInsets.all(Dimenssions.height15),
      decoration: BoxDecoration(
        color: backgroundColor2,
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuGroup('Akun', [
            _MenuItem(
              icon: Icons.person_outline,
              title: 'Edit Profil',
              onTap: () => Get.toNamed('/main/edit-profile'),
            ),
            _MenuItem(
              icon: Icons.shopping_bag_outlined,
              title: 'Orderan Kamu',
              onTap: () => Get.toNamed('/orders'),
            ),
            _MenuItem(
              icon: Icons.headset_mic_outlined,
              title: 'Bantuan',
              onTap: () => Get.toNamed('/help'),
            ),
          ]),
          SizedBox(height: Dimenssions.height20),
          _buildMenuGroup('Umum', [
            _MenuItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Kebijakan & Privasi',
              onTap: () => Get.toNamed('/privacy-policy'),
            ),
            _MenuItem(
              icon: Icons.description_outlined,
              title: 'Ketentuan Layanan',
              onTap: () => Get.toNamed('/terms-of-service'),
            ),
            _MenuItem(
              icon: Icons.star_outline,
              title: 'Rating Aplikasi',
              onTap: () => _showRatingDialog(),
            ),
          ]),
          SizedBox(height: Dimenssions.height20),
          SizedBox(
            height: Dimenssions.height45,
            width: double.infinity,
            child: TextButton(
              onPressed: () => Get.dialog(const LogoutConfirmationDialog()),
              style: TextButton.styleFrom(
                backgroundColor: alertColor.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimenssions.radius15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout,
                    color: alertColor,
                    size: Dimenssions.height20,
                  ),
                  SizedBox(width: Dimenssions.width10),
                  Text(
                    'Keluar',
                    style: primaryTextStyle.copyWith(
                      color: alertColor,
                      fontSize: Dimenssions.font14,
                      fontWeight: medium,
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

  Widget _buildMenuGroup(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font16,
            fontWeight: semiBold,
          ),
        ),
        SizedBox(height: Dimenssions.height10),
        ...items.map((item) => _buildMenuItemWidget(item)),
      ],
    );
  }

  Widget _buildMenuItemWidget(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: Dimenssions.height15,
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: logoColorSecondary,
              size: Dimenssions.height20,
            ),
            SizedBox(width: Dimenssions.width15),
            Expanded(
              child: Text(
                item.title,
                style: secondaryTextStyle.copyWith(
                  fontSize: Dimenssions.font14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: secondaryTextColor,
              size: Dimenssions.height15,
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimenssions.radius15),
        ),
        child: Container(
          padding: EdgeInsets.all(Dimenssions.height20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rating Aplikasi',
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font18,
                  fontWeight: semiBold,
                ),
              ),
              SizedBox(height: Dimenssions.height20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Dimenssions.width5,
                    ),
                    child: InkWell(
                      onTap: () => controller.setRating(index + 1),
                      child: Icon(
                        Icons.star_border,
                        size: Dimenssions.height30,
                        color: logoColorSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: Dimenssions.height20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: Text(
                      'Batal',
                      style: primaryTextStyle.copyWith(
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                  SizedBox(width: Dimenssions.width10),
                  TextButton(
                    onPressed: () {
                      controller.submitRating();
                      Get.back();
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: logoColorSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimenssions.radius15),
                      ),
                    ),
                    child: Text(
                      'Kirim',
                      style: primaryTextStyle.copyWith(
                        color: backgroundColor1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
