// ignore_for_file: deprecated_member_use

import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/widgets/logout_confirmation_dialog.dart';
import 'package:antarkanma/app/widgets/profile_image.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ... [previous imports and class definition remain the same] ...

class ProfilePage extends GetView<AuthController> {
  final AuthService authService = Get.find<AuthService>();

  ProfilePage({super.key});

  UserLocationController? _getLocationController() {
    if (!authService.isLoggedIn.value) return null;
    try {
      return Get.find<UserLocationController>();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor1,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(authService),
              if (authService.isLoggedIn.value) _buildAddressCard(),
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
    return Container(
      height: Dimenssions.height250,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            logoColor,
            logoColor.withOpacity(0.8),
            logoColor.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: logoColor.withOpacity(0.3), width: 2),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: logoColor.withOpacity(0.3), width: 2),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
          // Profile content
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Image
                GestureDetector(
                  onTap: () => Get.toNamed(Routes.userEditProfile),
                  child: Container(
                    margin: EdgeInsets.only(top: Dimenssions.height20),
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'profile_image',
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: logoColor, width: 3),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.9),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: user != null
                                ? ProfileImage(
                                    user: user,
                                    size: Dimenssions.height100,
                                  )
                                : CircleAvatar(
                                    radius: Dimenssions.height50,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.person,
                                      size: Dimenssions.height50,
                                      color: logoColor,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(Dimenssions.height8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: logoColor, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.edit,
                              size: Dimenssions.height15,
                              color: logoColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: Dimenssions.height20),
                // User Info
                Text(
                  authService.userName ?? 'Guest User',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font22,
                    fontWeight: semiBold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Dimenssions.height8),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimenssions.width15,
                    vertical: Dimenssions.height5,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: logoColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(Dimenssions.radius20),
                  ),
                  child: Text(
                    authService.userPhone ?? 'No phone number',
                    style: secondaryTextStyle.copyWith(
                      fontSize: Dimenssions.font14,
                      color: Colors.white,
                      fontWeight: medium,
                    ),
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
    final locationController = _getLocationController();
    if (locationController == null) return const SizedBox.shrink();

    return GetBuilder<UserLocationController>(
      builder: (controller) {
        return Container(
          margin: EdgeInsets.all(Dimenssions.height15),
          padding: EdgeInsets.all(Dimenssions.height15),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: logoColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(Dimenssions.radius15),
            boxShadow: [
              BoxShadow(
                color: logoColor.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                      Container(
                        padding: EdgeInsets.all(Dimenssions.height8),
                        decoration: BoxDecoration(
                          border: Border.all(color: logoColor),
                          borderRadius: BorderRadius.circular(Dimenssions.radius8),
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: logoColor,
                          size: Dimenssions.height22,
                        ),
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: logoColor),
                      borderRadius: BorderRadius.circular(Dimenssions.radius20),
                    ),
                    child: TextButton(
                      onPressed: () => Get.toNamed(Routes.userAddress),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimenssions.width15,
                          vertical: Dimenssions.height8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimenssions.radius20),
                        ),
                      ),
                      child: Text(
                        'Lihat Semua',
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font14,
                          color: logoColor,
                          fontWeight: medium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Dimenssions.height15),
              if (controller.defaultAddress != null) ...[
                Container(
                  padding: EdgeInsets.all(Dimenssions.height15),
                  decoration: BoxDecoration(
                    border: Border.all(color: logoColor.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(Dimenssions.radius15),
                  ),
                  child: Obx(() => Text(
                        controller.defaultAddress!.fullAddress,
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
                  child: ElevatedButton(
                    onPressed: () => Get.toNamed(Routes.userAddAddress),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: logoColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimenssions.radius15),
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
        color: Colors.white,
        border: Border.all(color: logoColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
        boxShadow: [
          BoxShadow(
            color: logoColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
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
              onTap: () => Get.toNamed(Routes.userEditProfile),
            ),
            _MenuItem(
              icon: Icons.headset_mic_outlined,
              title: 'Bantuan',
              onTap: () {
                Get.snackbar(
                  'Info',
                  'Fitur bantuan akan segera hadir',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
          ]),
          Divider(
            height: Dimenssions.height30,
            color: logoColor.withOpacity(0.3),
          ),
          _buildMenuGroup('Umum', [
            _MenuItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Kebijakan & Privasi',
              onTap: () {
                Get.snackbar(
                  'Info',
                  'Halaman kebijakan & privasi akan segera hadir',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            _MenuItem(
              icon: Icons.description_outlined,
              title: 'Ketentuan Layanan',
              onTap: () {
                Get.snackbar(
                  'Info',
                  'Halaman ketentuan layanan akan segera hadir',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            _MenuItem(
              icon: Icons.star_outline,
              title: 'Rating Aplikasi',
              onTap: () => _showRatingDialog(),
            ),
          ]),
          SizedBox(height: Dimenssions.height20),
          Container(
            height: Dimenssions.height45,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: alertColor),
              borderRadius: BorderRadius.circular(Dimenssions.radius15),
            ),
            child: ElevatedButton.icon(
              onPressed: () => Get.dialog(const LogoutConfirmationDialog()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Dimenssions.radius15),
                ),
              ),
              icon: Icon(
                Icons.logout,
                color: alertColor,
                size: Dimenssions.height20,
              ),
              label: Text(
                'Keluar',
                style: primaryTextStyle.copyWith(
                  color: alertColor,
                  fontSize: Dimenssions.font14,
                  fontWeight: medium,
                ),
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
        SizedBox(height: Dimenssions.height15),
        ...items.map((item) => _buildMenuItemWidget(item)),
      ],
    );
  }

  Widget _buildMenuItemWidget(_MenuItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: Dimenssions.height10),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(Dimenssions.radius8),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: Dimenssions.height12,
            horizontal: Dimenssions.width10,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: logoColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(Dimenssions.radius8),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(Dimenssions.height8),
                decoration: BoxDecoration(
                  border: Border.all(color: logoColor),
                  borderRadius: BorderRadius.circular(Dimenssions.radius8),
                ),
                child: Icon(
                  item.icon,
                  color: logoColor,
                  size: Dimenssions.height20,
                ),
              ),
              SizedBox(width: Dimenssions.width15),
              Expanded(
                child: Text(
                  item.title,
                  style: secondaryTextStyle.copyWith(
                    fontSize: Dimenssions.font14,
                    fontWeight: medium,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: logoColor,
                size: Dimenssions.height15,
              ),
            ],
          ),
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
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: logoColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(Dimenssions.radius15),
          ),
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
                        color: logoColor,
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
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: logoColor),
                      borderRadius: BorderRadius.circular(Dimenssions.radius15),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        controller.submitRating();
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(Dimenssions.radius15),
                        ),
                      ),
                      child: Text(
                        'Kirim',
                        style: primaryTextStyle.copyWith(
                          color: logoColor,
                        ),
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
