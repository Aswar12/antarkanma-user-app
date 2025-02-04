import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class MerchantDetailSection extends StatelessWidget {
  final MerchantModel merchant;

  const MerchantDetailSection({
    super.key,
    required this.merchant,
  });

  String _getOperatingHours() {
    if (merchant.openingTime == null || merchant.closingTime == null) {
      return 'Jam operasional tidak tersedia';
    }
    return '${merchant.openingTime} - ${merchant.closingTime} (${merchant.operatingDays?.join(", ") ?? "Tidak tersedia"})';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: Dimenssions.height10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image and Info
          Stack(
            children: [
              // Background Image or Color
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: backgroundColor3,
                  image: merchant.logoUrl != null && merchant.logoUrl!.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(merchant.logoUrl!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.4),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                ),
              ),
              // Merchant Info Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(Dimenssions.width20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              merchant.name,
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font20,
                                fontWeight: semiBold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Dimenssions.width8,
                              vertical: Dimenssions.height4,
                            ),
                            decoration: BoxDecoration(
                              color: merchant.isActive ? Colors.green : alertColor,
                              borderRadius: BorderRadius.circular(Dimenssions.radius8),
                            ),
                            child: Text(
                              merchant.isActive ? 'Buka' : 'Tutup',
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font12,
                                color: Colors.white,
                                fontWeight: medium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Dimenssions.height8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: Dimenssions.width4),
                          Expanded(
                            child: Text(
                              merchant.address,
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Description and Info Combined Section
          Container(
            margin: EdgeInsets.all(Dimenssions.width15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: backgroundColor2,
                    borderRadius: BorderRadius.circular(Dimenssions.radius12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Description Section
                      if (merchant.description != null &&
                          merchant.description!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(Dimenssions.width12),
                          decoration: BoxDecoration(
                            color: backgroundColor2,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(Dimenssions.radius12),
                              topRight: Radius.circular(Dimenssions.radius12),
                            ),
                          ),
                          child: Text(
                            merchant.description!,
                            style: secondaryTextStyle.copyWith(
                              fontSize: Dimenssions.font14,
                              height: 1.5,
                            ),
                          ),
                        ),

                      // Info Section with gradient background
                      Container(
                        padding: EdgeInsets.all(Dimenssions.width12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              backgroundColor2,
                              backgroundColor2.withOpacity(0.95),
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(Dimenssions.radius12),
                            bottomRight: Radius.circular(Dimenssions.radius12),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Operating Hours
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(Dimenssions.width6),
                                    decoration: BoxDecoration(
                                      color: logoColorSecondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(Dimenssions.radius8),
                                    ),
                                    child: Icon(
                                      Icons.access_time,
                                      color: logoColorSecondary,
                                      size: 16,
                                    ),
                                  ),
                                  SizedBox(width: Dimenssions.width8),
                                  Expanded(
                                    child: Text(
                                      _getOperatingHours(),
                                      style: secondaryTextStyle.copyWith(
                                        fontSize: Dimenssions.font12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 24,
                              width: 1,
                              color: backgroundColor3.withOpacity(0.5),
                              margin: EdgeInsets.symmetric(horizontal: Dimenssions.width12),
                            ),
                            // Product Count
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(Dimenssions.width6),
                                  decoration: BoxDecoration(
                                    color: logoColorSecondary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(Dimenssions.radius8),
                                  ),
                                  child: Icon(
                                    Icons.shopping_bag,
                                    color: logoColorSecondary,
                                    size: 16,
                                  ),
                                ),
                                SizedBox(width: Dimenssions.width8),
                                Text(
                                  '${merchant.productCount} Produk',
                                  style: secondaryTextStyle.copyWith(
                                    fontSize: Dimenssions.font12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: Dimenssions.height10),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (merchant.id != null) {
                            Get.toNamed('/chat', arguments: {
                              'merchantId': merchant.id,
                              'merchantName': merchant.name,
                            });
                          }
                        },
                        icon: Icon(Icons.chat_outlined,
                            color: Colors.white, size: 20),
                        label: Text(
                          'Chat Penjual',
                          style: primaryTextStyle.copyWith(
                            color: Colors.white,
                            fontWeight: medium,
                            fontSize: Dimenssions.font14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: logoColorSecondary,
                          padding: EdgeInsets.symmetric(
                              vertical: Dimenssions.height10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Dimenssions.width12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final phoneNumber = merchant.phoneNumber;
                          if (phoneNumber.isNotEmpty) {
                            final url = 'tel:$phoneNumber';
                            if (await url_launcher.canLaunch(url)) {
                              await url_launcher.launch(url);
                            }
                          }
                        },
                        icon: Icon(Icons.phone_outlined,
                            color: Colors.white, size: 20),
                        label: Text(
                          'Hubungi',
                          style: primaryTextStyle.copyWith(
                            color: Colors.white,
                            fontWeight: medium,
                            fontSize: Dimenssions.font14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: logoColorSecondary,
                          padding: EdgeInsets.symmetric(
                              vertical: Dimenssions.height10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
