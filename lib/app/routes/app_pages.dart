import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../modules/auth/views/sign_in_page.dart';
import '../modules/auth/views/sign_up_page.dart';
import '../modules/checkout/views/checkout_success_page.dart';
import '../modules/splash/views/splash_page.dart';
import '../modules/user/views/add_edit_address_page.dart';
import '../modules/user/views/address_page.dart';
import '../modules/user/views/address_selection_page.dart';
import '../modules/user/views/cart_page.dart';
import '../modules/user/views/chat_page.dart';
import '../modules/user/views/checkout_page.dart';
import '../modules/user/views/home_page.dart';
import '../modules/user/views/map_picker_page.dart';
import '../modules/user/views/merchant_detail_page.dart';
import '../modules/user/views/order_page.dart';
import '../modules/user/views/product_detail_page.dart';
import '../modules/user/views/profile_page.dart';
import '../modules/user/views/user_main_page.dart';
import '../modules/user/views/edit_profile_view.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = [
    // Core Routes
    GetPage(
      name: _Paths.splash,
      page: () => const SplashPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 500),
    ),

    // Authentication Routes
    GetPage(
      name: _Paths.login,
      page: () => SignInPage(),
      middlewares: [LoginGuard()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.register,
      page: () => SignUpPage(),
      middlewares: [LoginGuard()],
      transition: Transition.fadeIn,
    ),

    // Main User Routes
    GetPage(
      name: _Paths.userMainPage,
      page: () => const UserMainPage(),
      middlewares: [AuthGuard()],
      transition: Transition.fadeIn,
      children: [
        // Home Section
        GetPage(
          name: _Paths.home,
          page: () => const HomePage(),
          preventDuplicates: true,
          transition: Transition.fadeIn,
        ),

        // Profile Section
        GetPage(
          name: _Paths.profile,
          page: () => ProfilePage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: _Paths.editProfile,
          page: () => const EditProfileView(),
          transition: Transition.rightToLeft,
        ),

        // Communication Section
        GetPage(
          name: _Paths.chat,
          page: () => const ChatPage(),
          transition: Transition.rightToLeft,
        ),

        // Order Management
        GetPage(
          name: _Paths.order,
          page: () => const OrderPage(),
          transition: Transition.rightToLeft,
        ),

        // Address Management
        GetPage(
          name: _Paths.address,
          page: () => const AddressPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: _Paths.addAddress,
          page: () => AddEditAddressPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: _Paths.editAddress,
          page: () => AddEditAddressPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: _Paths.selectAddress,
          page: () => AddressSelectionPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: _Paths.mapPicker,
          page: () => const MapPickerView(),
          transition: Transition.rightToLeft,
        ),

        // Shopping & Checkout
        GetPage(
          name: _Paths.checkout,
          page: () => const CheckoutPage(),
          transition: Transition.rightToLeft,
        ),
      ],
    ),

    // Shopping Routes
    GetPage(
      name: _Paths.cart,
      page: () => const CartPage(),
      middlewares: [AuthGuard()],
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.checkoutSuccess,
      page: () => const CheckoutSuccessPage(),
      middlewares: [AuthGuard()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.productDetail,
      page: () => const ProductDetailPage(),
      preventDuplicates: true,
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: _Paths.merchantDetail,
      page: () => const MerchantDetailPage(),
      preventDuplicates: true,
      transition: Transition.rightToLeft,
    ),
  ];
}

class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      final authService = Get.find<AuthService>();
      final storageService = Get.find<StorageService>();

      final token = storageService.getToken();
      final rememberMe = storageService.getRememberMe();

      if (!authService.isLoggedIn.value || token == null || !rememberMe) {
        return const RouteSettings(name: _Paths.splash);
      }
      return null;
    } catch (e) {
      debugPrint('AuthGuard error: $e');
      return const RouteSettings(name: _Paths.splash);
    }
  }
}

class LoginGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    try {
      final authService = Get.find<AuthService>();
      final storageService = Get.find<StorageService>();

      final token = storageService.getToken();
      final rememberMe = storageService.getRememberMe();

      if (authService.isLoggedIn.value && token != null && rememberMe) {
        return const RouteSettings(name: _Paths.userMainPage);
      }
      return null;
    } catch (e) {
      debugPrint('LoginGuard error: $e');
      return null;
    }
  }
}
