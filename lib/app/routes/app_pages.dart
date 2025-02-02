import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/modules/auth/bindings/auth_binding.dart';
import 'package:antarkanma/app/modules/auth/views/sign_in_page.dart';
import 'package:antarkanma/app/modules/auth/views/sign_up_page.dart';
import 'package:antarkanma/app/modules/checkout/views/checkout_success_page.dart';
import 'package:antarkanma/app/modules/splash/views/splash_page.dart';
import 'package:antarkanma/app/modules/user/user_binding.dart';
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
import 'package:antarkanma/app/middleware/auth_middleware.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/controllers/auth_controller.dart';
import 'package:antarkanma/app/controllers/checkout_controller.dart';
import 'package:antarkanma/app/controllers/user_location_controller.dart';

abstract class Routes {
  // Common routes
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const main = '/main';
  static const checkoutSuccess = '/checkout-success';
  static const cart = '/cart';
  static const productDetail = '/product-detail';
  static const home = '/home';
  static const orderHistory = '/order-history';

  // User routes
  static const userMainPage = '/usermain';
  static const userHome = '/usermain/home';
  static const userProfile = '/usermain/profile';
  static const userChat = '/usermain/chat';
  static const userOrder = '/usermain/order';
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
      binding: AuthBinding(),
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
        Get.put(CartController(), permanent: true);
        Get.put(AuthController(), permanent: true);
      }),
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
      bindings: [
        AuthBinding(),
        UserBinding(),
      ],
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
          page: () => CheckoutPage(),
          binding: BindingsBuilder(() {
            // Ensure core services and controllers are available
            if (!Get.isRegistered<AuthService>()) {
              Get.put(AuthService(), permanent: true);
            }
            if (!Get.isRegistered<AuthController>()) {
              Get.put(AuthController(), permanent: true);
            }
            if (!Get.isRegistered<CartController>()) {
              Get.put(CartController(), permanent: true);
            }
            if (!Get.isRegistered<UserLocationController>()) {
              Get.put(UserLocationController(
                locationService: Get.find(),
              ), permanent: true);
            }
            // Initialize CheckoutController
            Get.put(CheckoutController(
              userLocationController: Get.find(),
              authController: Get.find(),
            ));
          }),
        ),
        GetPage(
          name: '/edit-profile',
          page: () => const EditProfileView(),
        ),
      ],
    ),
  ];
}
