import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class SavedPlacesWidget extends StatelessWidget {
  const SavedPlacesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
          child: Text(
            'Mau ke mana hari ini?',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font16,
              fontWeight: bold,
              color: navyColor,
            ),
          ),
        ),
        SizedBox(height: Dimenssions.height10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: Dimenssions.width15),
          child: Row(
            children: [
              _buildPlaceItem(
                icon: Icons.home,
                label: 'Rumah',
                address: 'Jl. Mawar Indah...',
              ),
              SizedBox(width: Dimenssions.width10),
              _buildPlaceItem(
                icon: Icons.work,
                label: 'Kantor',
                address: 'The Office Tower...',
              ),
              SizedBox(width: Dimenssions.width10),
              Container(
                width: Dimenssions.height45, // ~48px
                height: Dimenssions.height45,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceItem({
    required IconData icon,
    required String label,
    required String address,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimenssions.width15,
        vertical: Dimenssions.height10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Dimenssions.radius30),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Dimenssions.width4),
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: primaryOrange,
              size: Dimenssions.iconSize20,
            ),
          ),
          SizedBox(width: Dimenssions.width10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font14,
                  fontWeight: bold,
                  color: navyColor,
                  height: 1.2,
                ),
              ),
              Text(
                address,
                style: secondaryTextStyle.copyWith(
                  fontSize: Dimenssions.font10,
                  fontWeight: medium,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
