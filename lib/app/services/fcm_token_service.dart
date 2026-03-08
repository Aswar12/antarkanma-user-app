import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/providers/notification_provider.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/modules/chat/controllers/chat_controller.dart';
import 'package:antarkanma/app/modules/chat/controllers/chat_list_controller.dart';
import 'package:antarkanma/app/controllers/order_controller.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMTokenService extends GetxService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationProvider _notificationProvider = NotificationProvider();
  FlutterLocalNotificationsPlugin? _localNotifications;
  late final AuthService _authService;

  final _currentToken = RxnString();
  final _isTokenRegistered = RxBool(false);

  String? get currentToken => _currentToken.value;
  bool get isTokenRegistered => _isTokenRegistered.value;

  Future<FCMTokenService> init() async {
    // Request permission for iOS
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get initial FCM token
    await _initializeFCMToken();

    // Listen to token refresh
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Initialize AuthService lazily
    try {
      _authService = Get.find<AuthService>();
      // Listen to auth changes to handle token registration
      ever(_authService.currentUser, (user) {
        if (user != null &&
            _currentToken.value != null &&
            !_isTokenRegistered.value) {
          registerFCMToken(_currentToken.value!);
        }
      });
    } catch (e) {
      print('AuthService not yet initialized: $e');
    }

    return this;
  }

  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/notification_icon');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications!.initialize(initializationSettings);

    // Create notification channel for order updates
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'antarkanma_order_channel',
      'Pesanan',
      description: 'Notifikasi untuk update status pesanan',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _localNotifications!
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initializeFCMToken() async {
    try {
      String? token = await _messaging.getToken();
      print('Initializing FCM token: $token');

      if (token != null) {
        _currentToken.value = token;

        // Only register if AuthService is initialized and user is logged in
        try {
          final authService = Get.find<AuthService>();
          final user = authService.currentUser.value;
          if (user != null) {
            await registerFCMToken(token);
          }
        } catch (e) {
          print('AuthService not yet initialized during token init: $e');
        }
      }
    } catch (e) {
      print('Error initializing FCM token: $e');
    }
  }

  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      print(
          'Handling token refresh. Old: ${_currentToken.value}, New: $newToken');

      final oldToken = _currentToken.value;
      _currentToken.value = newToken;

      try {
        final authService = Get.find<AuthService>();
        final user = authService.currentUser.value;
        if (user != null) {
          // If we had an old token, unregister it first
          if (oldToken != null) {
            await _notificationProvider.unregisterFCMToken(oldToken);
          }
          // Register the new token
          await registerFCMToken(newToken);
        }
      } catch (e) {
        print('AuthService not yet initialized during token refresh: $e');
      }
    } catch (e) {
      print('Error handling token refresh: $e');
    }
  }

  Future<void> registerFCMToken(String fcmtoken) async {
    try {
      final authService = Get.find<AuthService>();
      final user = authService.currentUser.value;
      
      if (user != null) {
        debugPrint(
            'Registering FCM token for user ${user.id} with role ${user.role}');

        await _notificationProvider.registerFCMToken(
          fcmtoken,
          user.id.toString(),
          role: user.role,
        );

        _isTokenRegistered.value = true;
        debugPrint('FCM token registered successfully');
      } else {
        debugPrint('Cannot register FCM token: No user logged in (skipping silently)');
        // Don't set _isTokenRegistered to false here, as we want to retry when user logs in
      }
    } catch (e) {
      _isTokenRegistered.value = false;
      debugPrint('Error registering token with backend: $e');
      
      // If 401 error, trigger re-authentication
      if (e.toString().contains('Authentication failed')) {
        debugPrint('Token expired, clearing auth state...');
        try {
          final authService = Get.find<AuthService>();
          await authService.logout(); // Logout to clear storage
          Get.offAllNamed('/login'); // Redirect to login
        } catch (logoutError) {
          debugPrint('Error during logout: $logoutError');
        }
      }
      // Don't rethrow, just log the error
    }
  }

  Future<void> unregisterToken() async {
    try {
      final token = _currentToken.value;
      if (token != null) {
        print('Unregistering FCM token: $token');

        await _notificationProvider.unregisterFCMToken(token);
        _currentToken.value = null;
        _isTokenRegistered.value = false;

        print('FCM token unregistered successfully');
      }
    } catch (e) {
      print('Error unregistering token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print("Handling foreground message: ${message.messageId}");
    print("Data: ${message.data}");
    print(
        "Notification: ${message.notification?.title}, ${message.notification?.body}");

    // Handle chat messages
    if (message.data['type'] == 'CHAT_MESSAGE') {
      _handleChatMessage(message);
    } else if (message.data['type'] == 'chat') {
      // Legacy handler for backward compatibility
      _handleLegacyChatMessage(message);
    }
    
    // Handle order update messages - trigger refresh
    if (message.data.containsKey('order_id')) {
      _handleOrderUpdate(message);
    }
  }

  void _handleOrderUpdate(RemoteMessage message) {
    print("Order update received, triggering refresh...");
    
    // Refresh orders if OrderController is available
    if (Get.isRegistered<OrderController>()) {
      try {
        Get.find<OrderController>().refreshOrders();
        print("Orders refreshed successfully");
      } catch (e) {
        print("Error refreshing orders: $e");
      }
    }
    
    // Show local notification for order update
    _showOrderUpdateNotification(message);
  }

  void _showOrderUpdateNotification(RemoteMessage message) async {
    try {
      final title = message.notification?.title ?? 'Update Pesanan';
      final body = message.notification?.body ?? 'Pesanan Anda telah diperbarui';
      
      await _localNotifications?.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'antarkanma_order_channel',
            'Pesanan',
            channelDescription: 'Notifikasi update status pesanan',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/notification_icon',
          ),
        ),
        payload: json.encode(message.data),
      );
    } catch (e) {
      print("Error showing order update notification: $e");
    }
  }

  void _handleChatMessage(RemoteMessage message) {
    final data = message.data;

    print("Chat message received from: ${data['sender_name']}");
    print("Chat ID: ${data['chat_id']}, Order ID: ${data['order_id']}");

    // Show local notification immediately
    _showChatNotification(
      title: data['sender_name'] ?? 'Pesan Baru',
      body: message.notification?.body ?? 'Anda memiliki pesan baru',
      chatId: data['chat_id'],
    );

    // 1. Refresh chat list in background (if controller exists)
    if (Get.isRegistered<ChatListController>()) {
      print("ChatListController found, refreshing chat list...");
      Get.find<ChatListController>().fetchChats();
    }

    // 2. If chat page is open for this chat, fetch new messages
    if (Get.isRegistered<ChatController>()) {
      try {
        final chatController = Get.find<ChatController>();
        final currentChatId = chatController.chatId;
        
        if (currentChatId?.toString() == data['chat_id']) {
          print("Chat page is open for this chat, fetching new messages...");
          chatController.fetchMessages(); // Fetch new messages
        } else {
          print("Chat page is open but for different chat: $currentChatId vs ${data['chat_id']}");
        }
      } catch (e) {
        print("Error checking chat controller: $e");
      }
    }

    // Legacy handler for backward compatibility
    if (data['type'] == 'chat') {
      _handleLegacyChatMessage(message);
    }
  }

  void _handleLegacyChatMessage(RemoteMessage message) {
    // Legacy handler for backward compatibility
    print("Legacy chat message received");
    
    if (Get.isRegistered<ChatController>()) {
      print("ChatController found, Firestore stream should update UI");
    } else {
      // Show snackbar if not in chat
      if (message.notification != null) {
        Get.snackbar(
          message.notification!.title ?? 'Pesan Baru',
          message.notification!.body ?? '',
          onTap: (_) {
            // Handle tap to navigate to chat
          },
          backgroundColor: Get.theme.colorScheme.surface,
          colorText: Get.theme.textTheme.bodyLarge?.color,
          margin: const EdgeInsets.all(10),
          borderRadius: 10,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  void _showChatNotification({
    required String title,
    required String body,
    String? chatId,
  }) async {
    try {
      print("Showing local notification: $title - $body");
      
      // Lazy initialize FlutterLocalNotificationsPlugin if needed
      if (_localNotifications == null) {
        try {
          _localNotifications = Get.find<FlutterLocalNotificationsPlugin>();
        } catch (e) {
          print("FlutterLocalNotificationsPlugin not registered, skipping local notification");
          return;
        }
      }
      
      await _localNotifications!.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_channel',
            'Chat Messages',
            channelDescription: 'Notifikasi pesan chat',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_notification',
            showWhen: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode({'chatId': chatId, 'type': 'CHAT_MESSAGE'}),
      );
      
      print("Local notification shown successfully");
    } catch (e) {
      print("Error showing local notification: $e");
    }
  }
}
