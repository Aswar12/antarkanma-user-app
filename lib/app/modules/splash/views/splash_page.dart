import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/splash_controller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button during initialization
      child: Scaffold(
        backgroundColor: logoColor,
        body: SafeArea(
          child: Obx(() => AnimatedOpacity(
                opacity: controller.isInitializing ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
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

                      // Loading indicator
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(backgroundColor1),
                      ),

                      SizedBox(height: Dimenssions.height20),

                      // Welcome Text
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Dimenssions.width20,
                        ),
                        child: Text(
                          'Welcome to Antarkanma!',
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font16,
                            fontWeight: medium,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ),
      ),
    );
  }
}
