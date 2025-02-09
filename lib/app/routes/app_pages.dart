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
import '../bindings/main_binding.dart';
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
      binding: MainBinding(),
    ),
    GetPage(
      name: Routes.login,
      page: () => SignInPage(),
      binding: MainBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => SignUpPage(),
      binding: MainBinding(),
    ),
    GetPage(
      name: Routes.cart,
      page: () => const CartPage(),
      binding: MainBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: Routes.checkoutSuccess,
      page: () => const CheckoutSuccessPage(),
      binding: MainBinding(),
      middlewares: [AuthGuard()],
    ),
    GetPage(
      name: Routes.productDetail,
      page: () => const ProductDetailPage(),
      binding: MainBinding(),
      preventDuplicates: true,
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.merchantDetail,
      page: () => const MerchantDetailPage(),
      binding: MainBinding(),
    ),
    GetPage(
      name: Routes.userMainPage,
      page: () => const UserMainPage(),
      binding: MainBinding(),
      middlewares: [AuthGuard()],
      children: [
        GetPage(
          name: '/profile',
          page: () => ProfilePage(),
          binding: MainBinding(),
        ),
        GetPage(
          name: '/chat',
          page: () => const ChatPage(),
          binding: MainBinding(),
        ),
        GetPage(
          name: '/order',
          page: () => const OrderPage(),
          binding: MainBinding(),
        ),
        GetPage(
          name: '/home',
          page: () => const HomePage(),
          binding: MainBinding(),
        ),
        GetPage(
          name: '/address',
          page: () => const AddressPage(),
          binding: MainBinding(),
        ),
        GetPage(
          name: '/add-address',
          page: () => AddEditAddressPage(),
          binding: MainBinding(),
        ),
        GetPage(
          name: '/edit-address',
          page: () => AddEditAddressPage(),
          binding: MainBinding(),
        ),
        GetPage(
          name: '/select-address',
          page: () => AddressSelectionPage(),
          binding: MainBinding(),
        ),
        GetPage(
          name: '/map-picker',
          page: () => const MapPickerView(),
          binding: MainBinding(),
        ),
        GetPage(
          name: '/checkout',
          page: () => CheckoutPage(),
          binding: MainBinding(),
        ),
        GetPage(
          name: '/edit-profile',
          page: () => const EditProfileView(),
          binding: MainBinding(),
        ),
      ],
    ),
  ];
}

class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();
    return authService.isLoggedIn.value ? null : const RouteSettings(name: Routes.login);
  }
}
