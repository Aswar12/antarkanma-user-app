// ignore_for_file: constant_identifier_names
part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  
  // Core Routes
  static const splash = _Paths.splash;
  
  // Auth Routes
  static const login = _Paths.login;
  static const register = _Paths.register;
  
  // Main Routes
  static const userMainPage = _Paths.userMainPage;
  
  // User Feature Routes
  static const userProfile = _Paths.userMainPage + _Paths.profile;
  static const userChat = _Paths.userMainPage + _Paths.chat;
  static const userOrder = _Paths.userMainPage + _Paths.order;
  static const userHome = _Paths.userMainPage + _Paths.home;
  
  // Address Management Routes
  static const userAddress = _Paths.userMainPage + _Paths.address;
  static const userAddAddress = _Paths.userMainPage + _Paths.addAddress;
  static const userEditAddress = _Paths.userMainPage + _Paths.editAddress;
  static const userSelectAddress = _Paths.userMainPage + _Paths.selectAddress;
  static const userMapPicker = _Paths.userMainPage + _Paths.mapPicker;
  
  // Shopping Routes
  static const cart = _Paths.cart;
  static const checkoutSuccess = _Paths.checkoutSuccess;
  static const productDetail = _Paths.productDetail;
  static const merchantDetail = _Paths.merchantDetail;
  static const userCheckout = _Paths.userMainPage + _Paths.checkout;
  static const userEditProfile = _Paths.userMainPage + _Paths.editProfile;
}

abstract class _Paths {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const userMainPage = '/usermain';
  static const profile = '/profile';
  static const chat = '/chat';
  static const order = '/order';
  static const home = '/home';
  static const address = '/address';
  static const addAddress = '/add-address';
  static const editAddress = '/edit-address';
  static const selectAddress = '/select-address';
  static const mapPicker = '/map-picker';
  static const cart = '/cart';
  static const checkoutSuccess = '/checkout-success';
  static const productDetail = '/product-detail';
  static const merchantDetail = '/merchant-detail';
  static const checkout = '/checkout';
  static const editProfile = '/edit-profile';
}
