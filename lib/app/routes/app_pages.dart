import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/modules/auth/auth_binding.dart';
import 'package:antarkanma/app/modules/auth/views/sign_in_page.dart';
import 'package:antarkanma/app/modules/auth/views/sign_up_page.dart';
import 'package:antarkanma/app/modules/checkout/views/checkout_success_page.dart';
import 'package:antarkanma/app/modules/courier/courier_binding.dart';
import 'package:antarkanma/app/modules/courier/views/courier_main_page.dart';
import 'package:antarkanma/app/modules/courier/views/courier_profile_page.dart';
import 'package:antarkanma/app/modules/merchant/views/merchant_main_page.dart';
import 'package:antarkanma/app/modules/merchant/views/merchant_profile_page.dart';
import 'package:antarkanma/app/modules/merchant/merchant_binding.dart';
import 'package:antarkanma/app/modules/splash/views/splash_page.dart';
import 'package:antarkanma/app/modules/user/user_binding.dart';
// Ensure this import is present
import 'package:antarkanma/app/modules/user/views/add_edit_address_page.dart';
import 'package:antarkanma/app/modules/user/views/address_page.dart';
import 'package:antarkanma/app/modules/user/views/address_selection_page.dart';
import 'package:antarkanma/app/modules/user/views/cart_page.dart';
import 'package:antarkanma/app/modules/user/views/chat_page.dart';
import 'package:antarkanma/app/modules/user/views/checkout_page.dart';
import 'package:antarkanma/app/modules/user/views/home_page.dart';
import 'package:antarkanma/app/modules/user/views/map_picker_page.dart';
import 'package:antarkanma/app/modules/user/views/order_page.dart';
import 'package:antarkanma/app/modules/user/views/product_detail_page.dart';
import 'package:antarkanma/app/modules/user/views/profile_page.dart';
import 'package:antarkanma/app/modules/user/views/user_main_page.dart';
import 'package:antarkanma/app/modules/user/views/edit_profile_view.dart';
import 'package:get/get.dart';

abstract class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const checkoutSuccess = '/checkout-success';
  // Merchant Profile Page
  static const String merchantProfilePage = '/merchantprofile';
// Courier Profile Page
  static const String courierProfilePage = '/courierprofile';
  // User routes
  static const home = '/home';
  static const main = '/main';
  static const profile = '/usermain/profile';
  static const chat = '/usermain/chat';
  static const cart = '/cart';
  static const order = '/usermain/order';
  static const orderHistory = '/usermain/order-history';
  static const productDetail = '/product-detail';
  // User routes
  static const String userMainPage = '/usermain';
  static const String merchantMainPage = '/merchantmain';
  static const String courierMainPage = '/couriermain';

  static const merchantHome = '/merchant';
  static const merchantProducts = '/merchant/products';
  static const merchantOrders = '/merchant/orders';

  // Courier routes
  static const courierHome = '/courier';
  static const courierDeliveries = '/courier/deliveries';
  static const courierHistory = '/courier/history';
}

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
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
      name: Routes.splash,
      page: () => const SplashPage(),
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
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<CartController>()) {
          Get.put(CartController(), permanent: true);
        }
      }),
    ),
    GetPage(
      name: Routes.userMainPage,
      page: () => const UserMainPage(),
      binding: UserBinding(),
      children: [
        GetPage(
          name: '/profile',
          page: () => ProfilePage(),
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
        ),
        GetPage(
          name: '/address',
          page: () => const AddressPage(),
        ),
        GetPage(
          name: '/add-address',
          page: () => AddEditAddressPage(),
        ),
        GetPage(
          name: '/edit-address',
          page: () => AddEditAddressPage(),
        ),
        GetPage(
          name: '/select-address',
          page: () => AddressSelectionPage(),
        ),
        GetPage(
          name: '/map-picker',
          page: () => const MapPickerView(),
        ),
        GetPage(
          name: '/checkout',
          page: () => CheckoutPage(), // Halaman Checkout
          binding: UserBinding(), // Bindings sesuai kebutuhan
        ),
        GetPage(
          name: '/edit-profile',
          page: () => const EditProfileView(),
          binding: UserBinding(),
        ),
      ],
    ),
    GetPage(
      name: Routes.merchantMainPage,
      page: () => const MerchantMainPage(),
      binding: MerchantBinding(),
      children: [
        GetPage(
          name: Routes.merchantProfilePage,
          page: () => MerchantProfilePage(),
          binding: MerchantBinding(),
        ),
      ],
    ),
    GetPage(
      name: Routes.courierMainPage,
      page: () => const CourierMainPage(),
      binding: CourierBinding(),
      children: [
        GetPage(
          name: Routes.courierProfilePage,
          page: () => const CourierProfilePage(),
        ),
      ],
    ),
  ];
}
