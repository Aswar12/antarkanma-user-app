import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color backgroundColor;

  const CustomBackButton({
    Key? key,
    required this.onPressed,
    this.backgroundColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: EdgeInsets.all(Dimenssions.height8),
        decoration: BoxDecoration(
          color: backgroundColor.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.arrow_back, color: logoColorSecondary),
      ),
      onPressed: onPressed,
    );
  }
}
