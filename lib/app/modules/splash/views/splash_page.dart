import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';
import '../controllers/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: logoColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/Logo_AntarkanmaNoBg.png',
                width: 200,
                height: 200,
              ),
              SizedBox(height: Dimenssions.height30),

              // Loading Indicator
              Obx(() {
                if (controller.isLoading) {
                  return Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(logoColorSecondary),
                      ),
                      SizedBox(height: Dimenssions.height20),
                      // Loading State Text
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: Dimenssions.width20),
                        child: Text(
                          controller.currentState,
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font16,
                            fontWeight: medium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ),
    );
  }
}
