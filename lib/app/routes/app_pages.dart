import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../bindings/auth_binding.dart';
import '../bindings/initial_binding.dart';
import '../bindings/feature_bindings/home_binding.dart';
import '../bindings/feature_bindings/merchant_binding.dart';
import '../bindings/feature_bindings/checkout_binding.dart';
import '../bindings/feature_bindings/profile_binding.dart';
import '../bindings/feature_bindings/product_detail_binding.dart';
import '../bindings/feature_bindings/cart_binding.dart';

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

import '../services/auth_service.dart';

abstract class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const cart = '/cart';
  static const checkoutSuccess = '/checkout-success';
  static const productDetail = '/product-detail';
  static const merchantDetail = '/merchant-detail';
  static const userMainPage = '/usermain';
  static const userProfile = '/usermain/profile';
  static const userChat = '/usermain/chat';
  static const userOrder = '/usermain/order';
  static const userHome = '/usermain/home';
  static const userAddress = '/usermain/address';
  static const userAddAddress = '/usermain/add-address';
  static const userEditAddress = '/usermain/edit-address';
  static const userSelectAddress = '/usermain/select-address';
  static const userMapPicker = '/usermain/map-picker';
  static const userCheckout = '/usermain/checkout';
  static const userEditProfile = '/usermain/edit-profile';
}

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashPage(),
      binding: InitialBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => SignInPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => SignUpPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.cart,
      page: () => const CartPage(),
      binding: CartBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: Routes.checkoutSuccess,
      page: () => const CheckoutSuccessPage(),
      binding: HomeBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: Routes.productDetail,
      page: () => const ProductDetailPage(),
      binding: ProductDetailBinding(),
      preventDuplicates: true,
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.merchantDetail,
      page: () => const MerchantDetailPage(),
      binding: MerchantBinding(),
    ),
    GetPage(
      name: Routes.userMainPage,
      page: () => const UserMainPage(),
      binding: HomeBinding(),
      middlewares: [AuthGuard()],
      children: [
        GetPage(
          name: '/profile',
          page: () => ProfilePage(),
          binding: ProfileBinding(),
        ),
        GetPage(
          name: '/chat',
          page: () => const ChatPage(),
        ),
        GetPage(
          name: '/order',
          page: () => const OrderPage(),
        ),
        GetPage(
          name: '/home',
          page: () => const HomePage(),
          binding: HomeBinding(),
        ),
        GetPage(
          name: '/address',
          page: () => const AddressPage(),
          binding: ProfileBinding(),
        ),
        GetPage(
          name: '/add-address',
          page: () => AddEditAddressPage(),
          binding: ProfileBinding(),
        ),
        GetPage(
          name: '/edit-address',
          page: () => AddEditAddressPage(),
          binding: ProfileBinding(),
        ),
        GetPage(
          name: '/select-address',
          page: () => AddressSelectionPage(),
          binding: ProfileBinding(),
        ),
        GetPage(
          name: '/map-picker',
          page: () => const MapPickerView(),
          binding: ProfileBinding(),
        ),
        GetPage(
          name: '/checkout',
          page: () => CheckoutPage(),
          binding: CheckoutBinding(),
        ),
        GetPage(
          name: '/edit-profile',
          page: () => const EditProfileView(),
          binding: ProfileBinding(),
        ),
      ],
    ),
  ];
}

class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();
    return authService.isLoggedIn.value ? null : RouteSettings(name: Routes.login);
  }
}
