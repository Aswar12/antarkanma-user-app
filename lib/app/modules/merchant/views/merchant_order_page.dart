import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';

class MerchantOrderPage extends StatelessWidget {
  const MerchantOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Merchant Orders'),
      ),
      body: Center(
        child: Text(
          'Here are your orders',
          style: primaryTextStyle,
        ),
      ),
    );
  }
}
