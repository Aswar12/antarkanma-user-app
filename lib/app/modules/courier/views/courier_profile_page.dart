import 'package:flutter/material.dart';

class CourierProfilePage extends StatelessWidget {
  const CourierProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courier Profile'),
      ),
      body: Center(
        child: Text('Courier Profile Content'),
      ),
    );
  }
}
