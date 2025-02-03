import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartButton extends StatelessWidget {
  final int itemCount;
  final VoidCallback onPressed;
  final Color backgroundColor;

  const CartButton({
    super.key,
    required this.itemCount,
    required this.onPressed,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          margin: EdgeInsets.all(Dimenssions.height8),
          padding: EdgeInsets.all(Dimenssions.height8),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.shopping_cart,
              color: itemCount > 0 ? logoColorSecondary : Colors.grey,
            ),
            onPressed: itemCount > 0 ? onPressed : null,
          ),
        ),
        if (itemCount > 0)
          Positioned(
            right: Dimenssions.width8,
            top: Dimenssions.height8,
            child: Container(
              padding: EdgeInsets.all(Dimenssions.height4),
              decoration: BoxDecoration(
                color: alertColor,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(
                minWidth: Dimenssions.width18,
                minHeight: Dimenssions.height18,
              ),
              child: Text(
                itemCount.toString(),
                style: TextStyle(
                  color: backgroundColor1,
                  fontSize: Dimenssions.font10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
