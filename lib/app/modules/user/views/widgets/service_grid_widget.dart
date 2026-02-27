import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/routes/app_pages.dart';

class ServiceGridWidget extends StatelessWidget {
  const ServiceGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildServiceItem(
            icon: Icons.restaurant,
            label: 'Antar Makanan',
            onTap: () {
              // Navigate to Food
            },
          ),
          _buildServiceItem(
            icon: Icons.two_wheeler, // Moped icon
            label: 'Ojek',
            onTap: () {
              // Navigate to Ride
            },
          ),
          _buildServiceItem(
            icon: Icons.local_shipping,
            label: 'Jastip',
            onTap: () {
              print('Jastip button clicked');
              try {
                Get.toNamed(Routes.manualOrder);
              } catch (e) {
                print('Navigation error: $e');
                Get.snackbar('Error', 'Gagal navigasi: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: Dimenssions.height65, // ~64px
            height: Dimenssions.height65,
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.05), // orange-50 equivalent
              borderRadius: BorderRadius.circular(Dimenssions.radius15),
              border: Border.all(
                color: primaryOrange.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: Dimenssions.height45,
                height: Dimenssions.height45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Dimenssions.radius12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: primaryOrange,
                  size: Dimenssions.iconSize24 * 1.2,
                ),
              ),
            ),
          ),
          SizedBox(height: Dimenssions.height10 / 2),
          Text(
            label,
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font12,
              fontWeight: bold,
              color: navyColor,
            ),
          ),
        ],
      ),
    );
  }
}
