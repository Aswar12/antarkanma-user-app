class Config {
  // Production: static String baseUrl = 'https://dev.antarkanmaa.my.id/api';

  // HOST CONFIGURATION:
  // 1. Localhost (ADB Reverse): 'http://localhost:8000/api' -> run: adb reverse tcp:8000 tcp:8000
  // 2. Android Emulator: 'http://10.0.2.2:8000/api'
  // 3. Physical Device (Local IP): 'http://192.168.x.x:8000/api'
  static String baseUrl = 'http://localhost:8000/api';

  static const int receiveTimeout = 45000; // Increased to 45 seconds
  static const int connectTimeout = 45000; // Increased to 45 seconds

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
