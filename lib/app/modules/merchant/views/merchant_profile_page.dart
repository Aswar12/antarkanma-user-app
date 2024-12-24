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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildAddressCard(),
              _buildMenuSection(),
              SizedBox(height: Dimenssions.height10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final merchant = controller.merchant;
    return SizedBox(
      height: Dimenssions.height250,
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: Dimenssions.height250,
            child: merchant?.logo != null
                ? Stack(
                    children: [
                      Image.network(
                        merchant!.logo!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
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
                GestureDetector(
                  onTap: () => Get.toNamed('/merchant/edit-profile'),
                  child: Container(
                    margin: EdgeInsets.only(top: Dimenssions.height30),
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'merchant_logo',
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: merchant != null
                                ? MerchantProfileImage(
                                    merchant: merchant,
                                    size: Dimenssions.height100,
                                  )
                                : CircleAvatar(
                                    radius: Dimenssions.height50,
                                    backgroundColor: Colors.grey[300],
                                    child: Icon(
                                      Icons.store,
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
                              color: logoColor,
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
                Text(
                  controller.merchantName,
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font20,
                    fontWeight: semiBold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: Dimenssions.height5),
                Text(
                  controller.merchantDescription,
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
                    color: logoColor,
                    size: Dimenssions.height22,
                  ),
                  SizedBox(width: Dimenssions.width10),
                  Text(
                    'Alamat Merchant',
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font16,
                      fontWeight: semiBold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Get.toNamed('/merchant/address'),
                child: Text(
                  'Lihat Semua',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font14,
                    color: logoColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimenssions.height10),
          // Placeholder for address details
          Text(
            'Alamat belum ditambahkan',
            style: secondaryTextStyle.copyWith(
              fontSize: Dimenssions.font14,
            ),
          ),
        ],
      ),
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
              onTap: () => Get.toNamed('/merchant/edit-profile'),
            ),
            _MenuItem(
              icon: Icons.shopping_bag_outlined,
              title: 'Orderan Kamu',
              onTap: () => Get.toNamed('/merchant/orders'),
            ),
            _MenuItem(
              icon: Icons.headset_mic_outlined,
              title: 'Bantuan',
              onTap: () => Get.toNamed('/merchant/help'),
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
              color: logoColor,
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
