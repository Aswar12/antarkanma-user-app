import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class PromoBannerWidget extends StatelessWidget {
  const PromoBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
      child: Container(
        width: double.infinity,
        height: Dimenssions.height150, // Aspect ratio ~21/9
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimenssions.radius16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryOrange,
              Color(0xFFFFA726), // Orange 400 equivalent
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryOrange.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative shapes (simplified triangle pattern)
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.change_history,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Transform.rotate(
                angle: 0.5,
                child: Icon(
                  Icons.change_history,
                  size: 120,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(Dimenssions.width20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimenssions.width8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius:
                                BorderRadius.circular(Dimenssions.radius15),
                          ),
                          child: Text(
                            'Promo Spesial',
                            style: primaryTextStyle.copyWith(
                              fontSize: Dimenssions.font10,
                              fontWeight: bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: Dimenssions.height4),
                        Text(
                          'Diskon 50%',
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font24,
                            fontWeight: bold, // heavy/black
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Khusus pengguna baru hari ini!',
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font12,
                            fontWeight: medium,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: Dimenssions.height80,
                    height: Dimenssions.height80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.celebration,
                        color: Colors.white,
                        size: Dimenssions.iconSize24 * 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pagination dots
            Positioned(
              bottom: Dimenssions.height12,
              right: Dimenssions.width16,
              child: Row(
                children: [
                  _buildDot(isActive: true),
                  SizedBox(width: 4),
                  _buildDot(isActive: false),
                  SizedBox(width: 4),
                  _buildDot(isActive: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return Container(
      width: isActive ? 16 : 6,
      height: 4,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
