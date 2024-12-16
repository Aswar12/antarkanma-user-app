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
      body: Column(
        children: [
          _buildHeader(authService),
          _buildContent(authService),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return GetBuilder<UserLocationController>(
      builder: (locationController) {
        return Card(
          color: backgroundColor2,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimenssions.radius15),
          ),
          child: Padding(
            padding: EdgeInsets.all(Dimenssions.width15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Alamat Pengiriman',
                      style: primaryTextStyle.copyWith(
                        fontSize: Dimenssions.font16,
                        fontWeight: semiBold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed('/main/address'),
                      child: Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: Dimenssions.font14,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Dimenssions.height10),
                if (locationController.defaultAddress != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: primaryColor,
                        size: Dimenssions.font20,
                      ),
                      SizedBox(width: Dimenssions.width10),
                      Expanded(
                        child: Obx(() => Text(
                              locationController.defaultAddress!.fullAddress,
                              style: secondaryTextStyle.copyWith(
                                fontSize: Dimenssions.font14,
                              ),
                            )),
                      ),
                    ],
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
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (Get.isRegistered<UserLocationController>()) {
                          Get.toNamed('/main/add-address');
                        } else {
                          Get.snackbar('Error', 'Controller tidak ditemukan');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: EdgeInsets.symmetric(
                          vertical: Dimenssions.height10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimenssions.radius15),
                        ),
                      ),
                      child: Text(
                        'Tambah Alamat',
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AuthService authService) {
    final user = authService.getUser();
    return Obx(() => AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: backgroundColor1,
          flexibleSpace: SafeArea(
            child: Container(
              padding: EdgeInsets.all(Dimenssions.width30),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => controller.updateProfileImage(),
                    child: user != null
                        ? ProfileImage(
                            user: user,
                            size: Dimenssions.height55,
                          )
                        : CircleAvatar(
                            radius: Dimenssions.width20,
                            backgroundColor: Colors.grey,
                            child:
                                const Icon(Icons.person, color: Colors.white),
                          ),
                  ),
                  SizedBox(width: Dimenssions.width15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authService.userName,
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font24,
                            fontWeight: medium,
                          ),
                        ),
                        Text(
                          authService.userPhone,
                          style: subtitleTextStyle.copyWith(
                            fontSize: Dimenssions.font16,
                          ),
                        )
                      ],
                    ),
                  ),
                  IconButton(
                    color: logoColorSecondary,
                    icon: Image.asset(
                      color: logoColorSecondary,
                      'assets/button_exit.png',
                      width: Dimenssions.height25,
                    ),
                    onPressed: () =>
                        Get.dialog(const LogoutConfirmationDialog()),
                  )
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildContent(AuthService authService) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: Dimenssions.width30),
        width: double.infinity,
        decoration: BoxDecoration(color: backgroundColor3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Dimenssions.height25),
            _buildAddressCard(),
            SizedBox(height: Dimenssions.height25),

            Text(
              'Akun',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font18,
                fontWeight: semiBold,
              ),
            ),
            _buildMenuItem('Edit Profil', () => Get.toNamed('/edit-profile')),
            _buildMenuItem('Orderan Kamu', () => Get.toNamed('/orders')),
            _buildMenuItem('Bantuan', () => Get.toNamed('/help')),
            SizedBox(height: Dimenssions.height30),
            Text(
              'Umum',
              style: primaryTextStyle.copyWith(
                fontSize: Dimenssions.font18,
                fontWeight: semiBold,
              ),
            ),
            _buildMenuItem(
                'Kebijakan & Privasi', () => Get.toNamed('/privacy-policy')),
            _buildMenuItem(
                'Ketentuan Layanan', () => Get.toNamed('/terms-of-service')),
            _buildMenuItem('Rating Aplikasi', () => _showRatingDialog()),
            const Spacer(),
            // _buildLogoutButton(authService),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(top: Dimenssions.height20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: secondaryTextStyle.copyWith(
                fontSize: Dimenssions.font16,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: logoColorSecondary,
              size: Dimenssions.font20,
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
          padding: EdgeInsets.all(Dimenssions.width20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rating Aplikasi',
                style: TextStyle(
                  fontSize: Dimenssions.font18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: Dimenssions.height20),
              FittedBox(
                // Menggunakan FittedBox untuk menyesuaikan ukuran
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => controller.setRating(index + 1),
                        child: const Icon(
                          Icons.star_border,
                          size: 32,
                          color: Colors.amber,
                        ),
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
                    child: const Text('Batal'),
                  ),
                  SizedBox(width: Dimenssions.width10),
                  ElevatedButton(
                    onPressed: () {
                      controller.submitRating();
                      Get.back();
                    },
                    child: const Text('Kirim'),
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
