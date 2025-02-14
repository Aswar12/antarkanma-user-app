import 'dart:async';

import 'package:antarkanma/app/controllers/merchant_detail_controller.dart';
import 'package:antarkanma/app/controllers/product_detail_controller.dart';
import 'package:antarkanma/app/controllers/checkout_controller.dart';
import 'package:antarkanma/app/data/repositories/review_repository.dart';
import 'package:antarkanma/app/services/shipping_service.dart';
import 'package:antarkanma/app/data/providers/shipping_provider.dart';
import 'package:get/get.dart';
import '../controllers/homepage_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/user_main_controller.dart';
import '../controllers/splash_controller.dart';
import '../controllers/permission_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/user_location_controller.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/user_location_service.dart';
import '../services/location_service.dart';
import '../services/transaction_service.dart';
import '../services/category_service.dart';
import '../services/image_service.dart';
import '../services/merchant_service.dart';
import '../services/product_service.dart';
import '../data/providers/user_location_provider.dart';
import '../data/providers/transaction_provider.dart';
import '../data/providers/product_category_provider.dart';
import '../data/providers/merchant_provider.dart';
import '../data/providers/product_provider.dart';
import 'package:flutter/foundation.dart';

class MainBinding extends Bindings {
  static bool _isInitializing = false;
  static bool _isInitialized = false;
  static final Completer<void> _initializationCompleter = Completer<void>();

  @override
  Future<void> dependencies() async {
    // If already initialized, return immediately
    if (_isInitialized) {
      debugPrint('MainBinding already initialized');
      return;
    }

    // If initialization is in progress, wait for it to complete
    if (_isInitializing) {
      debugPrint('MainBinding initialization in progress, waiting...');
      await _initializationCompleter.future;
      return;
    }

    // Start initialization
    _isInitializing = true;
    debugPrint('Starting MainBinding initialization...');

    try {
      // Delay initialization slightly to allow Flutter engine to stabilize
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Initialize providers first to set up network handling
      await _retryWithDelay(() => _initializeProviders(), maxRetries: 1);

      // Initialize base services with network dependencies
      await _initializeBaseServices();

      // Initialize core services with retry mechanism
      await _retryWithDelay(() => _initializeCoreServices());

      // Initialize controllers last
      await _initializeControllers();

      // Add a small delay before completing initialization
      if (kDebugMode) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _isInitialized = true;
      _isInitializing = false;
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }
      debugPrint('MainBinding initialization completed successfully');
    } catch (e) {
      _isInitializing = false;
      debugPrint('Error in MainBinding initialization: $e');
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.completeError(e);
      }
      rethrow;
    }
  }

  Future<T> _retryWithDelay<T>(Future<T> Function() operation,
      {int maxRetries = 3}) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        debugPrint('Operation failed (attempt $attempts/$maxRetries): $e');
        if (attempts == maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempts));
      }
    }
    throw Exception('Max retries reached');
  }

  Future<void> _initializeBaseServices() async {
    try {
      debugPrint('Initializing base services...');
      // Get pre-initialized services
      final authService = Get.find<AuthService>();
      final storageService = Get.find<StorageService>();

      // Register them permanently
      Get.put<AuthService>(
        authService,
        permanent: true,
      );
      Get.put<StorageService>(
        storageService,
        permanent: true,
      );

      // Initialize image service
      final imageService = ImageService();
      await imageService.ensureInitialized();
      Get.put<ImageService>(
        imageService,
        permanent: true,
      );
      debugPrint('Base services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing base services: $e');
      rethrow;
    }
  }

  Future<void> _initializeProviders() async {
    try {
      debugPrint('Initializing providers...');
      // Initialize providers in order
      final userLocationProvider = UserLocationProvider();
      Get.put<UserLocationProvider>(
        userLocationProvider,
        permanent: true,
      );

      final transactionProvider = TransactionProvider();
      Get.put<TransactionProvider>(
        transactionProvider,
        permanent: true,
      );

      final productCategoryProvider = ProductCategoryProvider();
      Get.put<ProductCategoryProvider>(
        productCategoryProvider,
        permanent: true,
      );

      final merchantProvider = MerchantProvider();
      Get.put<MerchantProvider>(
        merchantProvider,
        permanent: true,
      );

      final productProvider = ProductProvider();
      Get.put<ProductProvider>(
        productProvider,
        permanent: true,
      );

      final shippingProvider = ShippingProvider();
      Get.put<ShippingProvider>(
        shippingProvider,
        permanent: true,
      );

      debugPrint('Providers initialized successfully');
    } catch (e) {
      debugPrint('Error initializing providers: $e');
      rethrow;
    }
  }

  Future<void> _initializeCoreServices() async {
    try {
      debugPrint('Initializing core services...');
      debugPrint('Initializing location-related services...');

      // Initialize permission controller first
      final permissionController = PermissionController();
      Get.put<PermissionController>(
        permissionController,
        permanent: true,
      );

      // Wait for all permissions to be properly initialized
      await permissionController.checkInitialPermissions();
      debugPrint('Permissions initialized');

      // Initialize core location service
      final locationService = LocationService();
      await locationService.init();
      Get.put<LocationService>(
        locationService,
        permanent: true,
      );
      debugPrint('Core location service initialized');

      // Initialize user location service only if storage service is ready
      final storageService = Get.find<StorageService>();
      if (!storageService.isEmpty()) {
        final userLocationService = UserLocationService();
        if (userLocationService.canInitialize()) {
          await userLocationService.ensureInitialized();
          Get.put<UserLocationService>(
            userLocationService,
            permanent: true,
          );
          debugPrint('User location service initialized');
        } else {
          debugPrint(
              'Skipping user location service initialization - prerequisites not met');
        }
      } else {
        debugPrint(
            'Skipping user location service initialization - storage not ready');
      }

      // Initialize other services
      final transactionService = TransactionService();
      Get.put<TransactionService>(
        transactionService,
        permanent: true,
      );

      final categoryService = CategoryService();
      Get.put<CategoryService>(
        categoryService,
        permanent: true,
      );

      final merchantService = MerchantService();
      Get.put<MerchantService>(
        merchantService,
        permanent: true,
      );

      final productService = ProductService();
      Get.put<ProductService>(
        productService,
        permanent: true,
      );

      final shippingService = ShippingService();
      Get.put<ShippingService>(
        shippingService,
        permanent: true,
      );

      debugPrint('Core services initialized successfully');
    } catch (e) {
      debugPrint('Error initializing core services: $e');
      rethrow;
    }
  }

  Future<void> _initializeControllers() async {
    try {
      debugPrint('Initializing controllers...');
      // Initialize splash controller first
      final splashController = SplashController(
        storageService: Get.find<StorageService>(),
        authService: Get.find<AuthService>(),
      );
      Get.put<SplashController>(
        splashController,
        permanent: true,
      );

      // Initialize critical controllers
      Get.lazyPut<UserMainController>(
        () => UserMainController(),
        fenix: true,
      );

      // Initialize HomePageController with all required services
      Get.put<HomePageController>(
        HomePageController(
          productService: Get.find<ProductService>(),
          merchantService: Get.find<MerchantService>(),
          categoryService: Get.find<CategoryService>(),
          authService: Get.find<AuthService>(),
          locationService: Get.find<LocationService>(),
        ),
        permanent: true,
      );

      // Initialize other controllers lazily
      Get.lazyPut<AuthController>(
        () => AuthController(),
        fenix: true,
      );
      Get.lazyPut<CartController>(
        () => CartController(),
        fenix: true,
      );
      Get.lazyPut<OrderController>(
        () => OrderController(),
        fenix: true,
      );
      Get.lazyPut<UserLocationController>(
        () => UserLocationController(),
        fenix: true,
      );

      // Initialize MerchantDetailController
      Get.lazyPut<MerchantDetailController>(
        () => MerchantDetailController(
          merchantService: Get.find<MerchantService>(),
          productService: Get.find<ProductService>(),
        ),
        fenix: true,
      );

      // Initialize ProductDetailController with required dependencies
      Get.lazyPut<ProductDetailController>(
        () => ProductDetailController(
          reviewRepository: ReviewRepository(
            provider: Get.find<ProductProvider>(),
          ),
          merchantService: Get.find<MerchantService>(),
        ),
        fenix: true,
      );

      // Initialize CheckoutController with required dependencies
      Get.lazyPut<CheckoutController>(
        () => CheckoutController(
          userLocationController: Get.find<UserLocationController>(),
          authController: Get.find<AuthController>(),
          cartController: Get.find<CartController>(),
          shippingService: Get.find<ShippingService>(),
          transactionService: Get.find<TransactionService>(),
        ),
        fenix: true,
      );

      debugPrint('Controllers initialized successfully');
    } catch (e) {
      debugPrint('Error initializing controllers: $e');
      rethrow;
    }
  }
}
