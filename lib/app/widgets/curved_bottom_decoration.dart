import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';

class CurvedBottomDecoration extends StatelessWidget {
  final double height;
  final Color color;
  final double radius;

  const CurvedBottomDecoration({
    Key? key,
    required this.height,
    this.color = Colors.white,
    this.radius = 30,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radius),
        ),
      ),
    );
  }
}
