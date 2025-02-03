import 'package:get/get.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/sign_in_page.dart';
import '../modules/auth/views/sign_up_page.dart';
import '../modules/checkout/views/checkout_success_page.dart';
import '../modules/splash/views/splash_page.dart';
import '../modules/splash/bindings/splash_binding.dart';
import '../modules/user/user_binding.dart';
import '../modules/user/views/add_edit_address_page.dart';
import '../modules/user/views/address_page.dart';
import '../modules/user/views/address_selection_page.dart';
import '../modules/user/views/cart_page.dart';
import '../modules/user/views/chat_page.dart';
import '../modules/user/views/checkout_page.dart';
import '../modules/user/views/home_page.dart';
import '../modules/user/views/map_picker_page.dart';
import '../modules/user/views/order_page.dart';
import '../modules/user/views/product_detail_page.dart';
import '../modules/user/views/profile_page.dart';
import '../modules/user/views/user_main_page.dart';
import '../modules/user/views/edit_profile_view.dart';
import '../modules/user/controllers/edit_profile_controller.dart';

abstract class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const cart = '/cart';
  static const checkoutSuccess = '/checkout-success';
  static const productDetail = '/product-detail';
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
      page: () => SplashPage(),
      binding: SplashBinding(),
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
      binding: UserBinding(),
    ),
    GetPage(
      name: Routes.checkoutSuccess,
      page: () => const CheckoutSuccessPage(),
      binding: UserBinding(),
    ),
    GetPage(
      name: Routes.productDetail,
      page: () => const ProductDetailPage(),
      binding: UserBinding(),
    ),
    GetPage(
      name: Routes.userMainPage,
      page: () => const UserMainPage(),
      binding: UserBinding(),
      children: [
        GetPage(
          name: '/profile',
          page: () => ProfilePage(),
          binding: UserBinding(),
        ),
        GetPage(
          name: '/chat',
          page: () => const ChatPage(),
          binding: UserBinding(),
        ),
        GetPage(
          name: '/order',
          page: () => const OrderPage(),
          binding: UserBinding(),
        ),
        GetPage(
          name: '/home',
          page: () => const HomePage(),
          binding: UserBinding(),
        ),
        GetPage(
          name: '/address',
          page: () => const AddressPage(),
          binding: UserBinding(),
        ),
        GetPage(
          name: '/add-address',
          page: () => AddEditAddressPage(),
          binding: UserBinding(),
        ),
        GetPage(
          name: '/edit-address',
          page: () => AddEditAddressPage(),
          binding: UserBinding(),
        ),
        GetPage(
          name: '/select-address',
          page: () => AddressSelectionPage(),
          binding: UserBinding(),
        ),
        GetPage(
          name: '/map-picker',
          page: () => const MapPickerView(),
          binding: UserBinding(),
        ),
        GetPage(
          name: '/checkout',
          page: () => CheckoutPage(),
          binding: UserBinding(),
          preventDuplicates: false, // Allow multiple instances of checkout page
        ),
        GetPage(
          name: '/edit-profile',
          page: () => const EditProfileView(),
          binding: UserBinding(),
        ),
      ],
    ),
  ];
}
