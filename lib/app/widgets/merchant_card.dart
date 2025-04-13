import 'package:antarkanma/app/data/models/merchant_model.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:antarkanma/app/widgets/cached_image_view.dart';
import 'package:antarkanma/app/widgets/shimmer_loading.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MerchantCard extends StatelessWidget {
  final MerchantModel merchant;
  final VoidCallback? onTap;

  const MerchantCard({
    super.key,
    required this.merchant,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        } else {
          Get.toNamed(
            Routes.merchantDetail,
            arguments: {'merchantId': merchant.id},
            preventDuplicates: true,
          );
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.45,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: Dimenssions.width4,
              vertical: Dimenssions.height4,
            ),
            decoration: BoxDecoration(
              color: backgroundColor2,
              borderRadius: BorderRadius.circular(Dimenssions.radius20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Dimenssions.radius20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Merchant Image
                  Hero(
                    tag: 'merchant-${merchant.id}',
                    child:
                        merchant.logoUrl != null && merchant.logoUrl!.isNotEmpty
                            ? CachedImageView(
                                imageUrl: merchant.logoUrl!,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                color: backgroundColor3,
                                child: Center(
                                  child: Icon(
                                    Icons.store_rounded,
                                    color: secondaryTextColor.withOpacity(0.5),
                                    size: Dimenssions.iconSize24 * 2,
                                  ),
                                ),
                              ),
                  ),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.6),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.3, 0.5, 0.8, 1.0],
                      ),
                    ),
                  ),

                  // Content Overlay
                  Padding(
                    padding: EdgeInsets.all(Dimenssions.width12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimenssions.width8,
                            vertical: Dimenssions.height4,
                          ),
                          decoration: BoxDecoration(
                            color: merchant.isActive
                                ? Colors.green.withOpacity(0.9)
                                : alertColor.withOpacity(0.9),
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                spreadRadius: 0,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
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

                        const Spacer(),

                        // Merchant Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Merchant Name
                            Text(
                              merchant.name,
                              style: primaryTextStyle.copyWith(
                                fontSize: Dimenssions.font16,
                                fontWeight: semiBold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: Dimenssions.height4),

                            // Address
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: Dimenssions.iconSize16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                SizedBox(width: Dimenssions.width4),
                                Expanded(
                                  child: Text(
                                    merchant.address,
                                    style: secondaryTextStyle.copyWith(
                                      fontSize: Dimenssions.font12,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Dimenssions.height8),

                            // Bottom Row: Distance, Duration, and Product Count
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Dimenssions.width8,
                                      vertical: Dimenssions.height4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(
                                          Dimenssions.radius12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.directions_bike_outlined,
                                          size: Dimenssions.iconSize16,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: Dimenssions.width4),
                                        merchant.distance != null
                                            ? Text(
                                                '${merchant.distance?.toStringAsFixed(1)} km',
                                                style: secondaryTextStyle.copyWith(
                                                  fontSize: Dimenssions.font12,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : ShimmerLoading(
                                                width: Dimenssions.width30,
                                                height: Dimenssions.height12,
                                                radius: Dimenssions.radius4,
                                              ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: Dimenssions.width8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Dimenssions.width8,
                                      vertical: Dimenssions.height4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(
                                          Dimenssions.radius12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: Dimenssions.iconSize16,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: Dimenssions.width4),
                                        merchant.duration != null
                                            ? Text(
                                                '${merchant.duration} min',
                                                style: secondaryTextStyle.copyWith(
                                                  fontSize: Dimenssions.font12,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : ShimmerLoading(
                                                width: Dimenssions.width30,
                                                height: Dimenssions.height12,
                                                radius: Dimenssions.radius4,
                                              ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: Dimenssions.width8),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Dimenssions.width8,
                                      vertical: Dimenssions.height4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          logoColorSecondary.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(
                                          Dimenssions.radius12),
                                    ),
                                    child: Text(
                                      '${merchant.productCount} Produk',
                                      style: secondaryTextStyle.copyWith(
                                        fontSize: Dimenssions.font12,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
