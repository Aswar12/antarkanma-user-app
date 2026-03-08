// ignore_for_file: deprecated_member_use

import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/widgets/logout_confirmation_dialog.dart';
import 'package:antarkanma/app/widgets/profile_image.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:antarkanma/app/controllers/theme_controller.dart';

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
      backgroundColor:
          Get.isDarkMode ? AppColors.navy : const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(authService, context),
            if (authService.isLoggedIn.value) ...[
              _buildFloatingStatsCard(),
              _buildMenuSections(),
            ] else
              _buildGuestMenu(),
            SizedBox(height: Dimenssions.height30),
            _buildVersionInfo(),
            SizedBox(height: Dimenssions.height40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthService authService, BuildContext context) {
    final user = authService.getUser();
    final isGuest = !authService.isLoggedIn.value;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 40,
                left: 24,
                right: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: isGuest
                        ? null
                        : () => Get.toNamed(Routes.userEditProfile),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 4,
                              ),
                            ),
                            child: user != null
                                ? ProfileImage(
                                    user: user,
                                    size: 96,
                                  )
                                : CircleAvatar(
                                    radius: 48,
                                    backgroundColor: Colors.grey[300],
                                    child: Icon(
                                      Icons.person,
                                      size: 48,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                          ),
                          if (!isGuest)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.navy, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Text(
                  authService.userName ?? 'Guest User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  authService.userPhone ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                if (!isGuest)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFFFB923C)],
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.stars, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'MEMBER SILVER',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingStatsCard() {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Get.isDarkMode
                ? const Color(0xFF334155)
                : const Color(0xFFF1F5F9),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
                icon: Icons.confirmation_number_outlined,
                iconColor: AppColors.primary,
                iconBgColor: Get.isDarkMode
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.orange.shade50,
                label: 'Voucher',
                value: '12',
                valueColor: Get.isDarkMode ? Colors.white : Colors.black),
            _buildDivider(),
            _buildStatItem(
                icon: Icons.control_point_duplicate,
                iconColor: Colors.blue,
                iconBgColor: Get.isDarkMode
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.blue.shade50,
                label: 'AntarPoints',
                value: '2.450',
                valueColor: Get.isDarkMode ? Colors.white : Colors.black),
            _buildDivider(),
            _buildStatItem(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: Colors.green,
                iconBgColor: Get.isDarkMode
                    ? Colors.green.withOpacity(0.2)
                    : Colors.green.shade50,
                label: 'AntarPay',
                value: 'Rp 500k',
                valueColor: Get.isDarkMode
                    ? Colors.green.shade400
                    : Colors.green.shade600),
            _buildDivider(),
            _buildStatItem(
                icon: Icons.share_outlined,
                iconColor: Colors.purple,
                iconBgColor: Get.isDarkMode
                    ? Colors.purple.withOpacity(0.2)
                    : Colors.purple.shade50,
                label: 'Referral',
                value: 'Earn',
                valueColor: Get.isDarkMode ? Colors.white : Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 32,
      width: 1,
      color: Get.isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Get.isDarkMode
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSections() {
    return GetBuilder<UserLocationController>(
      init: _getLocationController(),
      builder: (locationController) {
        String addressSubtitle = 'Tambahkan alamat pengiriman';
        if (locationController.defaultAddress != null) {
          addressSubtitle = locationController.defaultAddress!.fullAddress;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMenuGroup('AKUN', [
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profil',
                  onTap: () => Get.toNamed(Routes.userEditProfile),
                ),
                _buildMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Alamat Pengiriman',
                  subtitle: addressSubtitle,
                  onTap: () => Get.toNamed(Routes.userAddress),
                ),
              ]),
              const SizedBox(height: 24),
              _buildMenuGroup('AKTIVITAS', [
                _buildMenuItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Orderan Kamu',
                  onTap: () => Get.toNamed(Routes.userOrder),
                ),
                _buildMenuItem(
                  icon: Icons.favorite_border,
                  title: 'Favorit Saya',
                  onTap: () => Get.toNamed(Routes.wishlist),
                ),
              ]),
              const SizedBox(height: 24),
              _buildMenuGroup('LAINNYA', [
                _buildMenuItem(
                  icon: Icons.brightness_6_outlined,
                  title: 'Tampilan Tema',
                  onTap: () => _showThemeSelectionDialog(),
                ),
                _buildMenuItem(
                  icon: Icons.star_outline,
                  title: 'Rating Aplikasi',
                  onTap: () => _showRatingDialog(),
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Bantuan & Pusat Dukungan',
                  onTap: () => Get.snackbar(
                      'Info', 'Fitur bantuan akan segera hadir',
                      snackPosition: SnackPosition.BOTTOM),
                ),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: 'Syarat & Ketentuan',
                  onTap: () => Get.snackbar(
                      'Info', 'Syarat & Ketentuan akan segera hadir',
                      snackPosition: SnackPosition.BOTTOM),
                ),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Keluar Sesi',
                  titleColor: Colors.red.shade500,
                  iconColor: Colors.red.shade500,
                  showChevron: false,
                  onTap: () => Get.dialog(const LogoutConfirmationDialog()),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuestMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMenuGroup('LAINNYA', [
            _buildMenuItem(
              icon: Icons.brightness_6_outlined,
              title: 'Tampilan Tema',
              onTap: () => _showThemeSelectionDialog(),
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              title: 'Bantuan & Pusat Dukungan',
              onTap: () => Get.snackbar(
                  'Info', 'Fitur bantuan akan segera hadir',
                  snackPosition: SnackPosition.BOTTOM),
            ),
            _buildMenuItem(
              icon: Icons.login,
              title: 'Masuk / Daftar',
              titleColor: AppColors.primary,
              iconColor: AppColors.primary,
              showChevron: false,
              onTap: () => Get.offAllNamed(Routes.login),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildMenuGroup(String header, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            header,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Get.isDarkMode
                  ? const Color(0xFF64748B)
                  : const Color(0xFF94A3B8),
              letterSpacing: 1.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Get.isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Get.isDarkMode
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final int idx = entry.key;
              final Widget item = entry.value;
              return Column(
                children: [
                  item,
                  if (idx != items.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: Get.isDarkMode
                          ? const Color(0xFF334155).withOpacity(0.5)
                          : const Color(0xFFF8FAFC),
                      indent: 56,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Color? iconColor,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    final tColor = titleColor ??
        (Get.isDarkMode ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A));
    final iColor = iconColor ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: iColor, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Get.isDarkMode
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right,
                  color: Get.isDarkMode
                      ? const Color(0xFF475569)
                      : const Color(0xFFCBD5E1),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: Text(
        'Antarkanma Version 2.4.0',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Get.isDarkMode
              ? const Color(0xFF475569)
              : const Color(0xFF94A3B8),
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

  void _showThemeSelectionDialog() {
    final themeController = Get.find<ThemeController>();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(Dimenssions.height20),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Dimenssions.radius20),
            topRight: Radius.circular(Dimenssions.radius20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Tampilan Tema',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font18,
                fontWeight: semiBold,
              ),
            ),
            SizedBox(height: Dimenssions.height20),
            _buildThemeOption(
              'Terang',
              ThemeMode.light,
              themeController,
              Icons.wb_sunny_outlined,
            ),
            _buildThemeOption(
              'Gelap',
              ThemeMode.dark,
              themeController,
              Icons.nightlight_round_outlined,
            ),
            _buildThemeOption(
              'Sistem',
              ThemeMode.system,
              themeController,
              Icons.settings_system_daydream_outlined,
            ),
            SizedBox(height: Dimenssions.height20),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    String title,
    ThemeMode mode,
    ThemeController controller,
    IconData icon,
  ) {
    return Obx(() {
      final isSelected = controller.themeMode.value == mode;
      return InkWell(
        onTap: () {
          controller.saveTheme(mode);
          Get.back();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: Dimenssions.height15),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? logoColorSecondary : secondaryTextColor,
                size: Dimenssions.height24,
              ),
              SizedBox(width: Dimenssions.width15),
              Expanded(
                child: Text(
                  title,
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font16,
                    color: isSelected ? logoColorSecondary : null,
                    fontWeight: isSelected ? semiBold : regular,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: logoColorSecondary,
                  size: Dimenssions.height24,
                ),
            ],
          ),
        ),
      );
    });
  }
}
