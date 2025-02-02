import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const QuantityButton({
    Key? key,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: logoColorSecondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: logoColorSecondary,
        ),
      ),
    );
  }
}
