import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/modules/auth/auth_binding.dart';
import 'package:antarkanma/app/modules/auth/views/sign_in_page.dart';
import 'package:antarkanma/app/modules/auth/views/sign_up_page.dart';
import 'package:antarkanma/app/modules/checkout/views/checkout_success_page.dart';
import 'package:antarkanma/app/modules/courier/courier_binding.dart';
import 'package:antarkanma/app/modules/courier/views/courier_main_page.dart';
import 'package:antarkanma/app/modules/courier/views/courier_profile_page.dart';
import 'package:antarkanma/app/modules/merchant/controllers/merchant_profile_controller.dart';
import 'package:antarkanma/app/modules/merchant/views/merchant_main_page.dart';
import 'package:antarkanma/app/modules/merchant/views/merchant_order_page.dart';
import 'package:antarkanma/app/modules/merchant/views/merchant_profile_page.dart';
import 'package:antarkanma/app/modules/merchant/views/product_management_page.dart';
import 'package:antarkanma/app/modules/merchant/views/product_form_page.dart';
import 'package:antarkanma/app/modules/merchant/merchant_binding.dart';
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

  // Merchant routes
  static const merchantMainPage = '/merchantmain';
  static const merchantHome = '/merchant';
  static const merchantProfile = '/merchantmain/profile';
  static const merchantOrders = '/merchantmain/orders';
  static const merchantProducts = '/merchantmain/products';
  static const merchantAddProduct = '/merchantmain/add-product';
  static const merchantEditProduct = '/merchantmain/edit-product/:id';
  static const merchantEditInfo = '/merchantmain/edit-store-info';

  // Courier routes
  static const courierMainPage = '/couriermain';
  static const courierHome = '/courier';
  static const courierProfile = '/couriermain/profile';
  static const courierDeliveries = '/couriermain/deliveries';
  static const courierHistory = '/couriermain/history';
}

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
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
          binding: UserBinding(),
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
      middlewares: [
        AuthMiddleware(), // Tambahkan middleware untuk cek auth
      ],
      children: [
        GetPage(
          name: '/profile',
          page: () => MerchantProfilePage(),
          binding: MerchantBinding(),
        ),
        GetPage(
          name: '/orders',
          page: () => const MerchantOrderPage(),
          binding: MerchantBinding(),
        ),
        GetPage(
          name: '/products',
          page: () => const ProductManagementPage(),
        ),
        GetPage(
          name: '/add-product',
          page: () => const ProductFormPage(),
        ),
        GetPage(
          name: '/edit-product/:id',
          page: () => const ProductFormPage(),
        ),
        GetPage(
          name: '/edit-store-info',
          page: () => MerchantProfilePage(),
        ),
      ],
    ),
    GetPage(
      name: Routes.courierMainPage,
      page: () => const CourierMainPage(),
      binding: CourierBinding(),
      children: [
        GetPage(
          name: '/profile',
          page: () => const CourierProfilePage(),
        ),
      ],
    ),
  ];
}
