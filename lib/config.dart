class Config {
  static String baseUrl = 'https://dev.antarkanmaa.my.id/api';
  static const int receiveTimeout = 15000;
  static const int connectTimeout = 15000;

  // API Endpoints
  static const String products = '/products';
  static const String categories = '/categories';
  static const String orders = '/orders';
  static const String merchants = '/merchants';
  static const String login = '/login';
  static const String register = '/register';
  static const String refresh = '/refresh'; // Added refresh endpoint
  static const String logout = '/logout'; // Added logout endpoint
  static const String profile = '/user/profile';
  static const String profilePhoto = '/user/profile/photo';
  static const String changePassword = '/change-password';
  static const String userLocations = '/user/locations';
  static const String defaultLocation = '/user/locations/default';
}
