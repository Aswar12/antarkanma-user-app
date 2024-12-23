import 'package:flutter/material.dart';

class MerchantProfilePage extends StatelessWidget {
  const MerchantProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Profile'),
      ),
      body: Center(
        child: Text('Merchant Profile Content'),
      ),
    );
  }
}
