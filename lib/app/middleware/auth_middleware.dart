import 'package:flutter/material.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/routes/app_pages.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/user_model.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();

    if (authService.currentUser.value == null) {
      // User not logged in, redirect to login
      return const RouteSettings(name: Routes.login);
    }

    // Check if user has USER role using the isUser getter
    if (!authService.currentUser.value!.isUser) {
      // Not a user, redirect to login
      return const RouteSettings(name: Routes.login);
    }

    // User logged in and has USER role, allow access
    return null;
  }
}
