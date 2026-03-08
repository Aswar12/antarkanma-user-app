import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/chat_model.dart';
import 'package:antarkanma/app/data/repositories/chat_repository.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/theme.dart';
import 'package:geolocator/geolocator.dart';

class ChatController extends GetxController with WidgetsBindingObserver {
  final ChatRepository _repository = ChatRepository();
  final AuthService _authService = Get.find<AuthService>();

  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isSending = false.obs;

  // Recipient info
  final RxString recipientName = 'Chat'.obs;
  final RxString recipientType = ''.obs; // MERCHANT, COURIER
  final RxString recipientAvatar = ''.obs;
  final RxString chatStatus = ''.obs;

  final messageController = TextEditingController();
  final scrollController = ScrollController();

  int? chatId;
  int? orderId;
  int? merchantId;
  int? productId;
  int? recipientId;

  // Retrieve current user ID
  int get currentUserId => _authService.currentUser.value?.id ?? 0;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    final args = Get.arguments;
    if (args != null) {
      if (args['orderId'] != null) {
        orderId = args['orderId'];
        merchantId = args['merchantId'];
        chatId = args['chatId']; // This will be null initially for new chats

        // Check if courier exists (only for courier chat)
        if (merchantId == null) {
          final courierStatus = args['courierStatus'];
          if (courierStatus == null || courierStatus == 'IDLE') {
            // Initiate anyway so backend can handle it, or show error if we know for sure
            // no courier is assigned. But backend initiator check is safer.
          }
        }

        _startChatSession();
      } else if (args['chatId'] != null) {
        // Handle navigation from Chat List
        chatId = args['chatId'];
        orderId = args['orderId'];
        _startChatSession();
      } else if (args['merchantId'] != null) {
        // Handle direct merchant chat (from product detail, merchant detail, etc.)
        merchantId = args['merchantId'];
        recipientName.value = args['merchantName'] ?? 'Merchant';
        recipientType.value = 'MERCHANT';
        recipientAvatar.value = args['merchantAvatar'] ?? '';
        productId = args['productId'];
        _startDirectMerchantChat();
      }
    }
  }

  void _startChatSession() async {
    try {
      debugPrint(
          'Starting chat session - orderId: $orderId, chatId: $chatId, merchantId: $merchantId');

      if (orderId != null && chatId == null && merchantId != null) {
        // Initiate chat with merchant
        debugPrint('Initiating chat with merchant...');
        await _initiateChatWithMerchant();
      } else if (orderId != null && chatId == null && merchantId == null) {
        // Initiate chat with courier (no merchantId means courier chat)
        debugPrint('Initiating chat with courier...');
        await _initiateChatWithCourier();
      }

      if (chatId != null) {
        debugPrint('Chat session started successfully - chatId: $chatId');

        // Load recipient info (for chat list navigation)
        await _loadRecipientInfo();

        _fetchMessages(initial: true);
      } else {
        debugPrint('Warning: chatId is still null after initiation');
        Get.snackbar(
          'Error',
          'Gagal memulai chat. Silakan coba lagi.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: alertColor.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error starting chat session: $e');
      Get.snackbar(
        'Error',
        'Gagal memulai sesi chat: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: alertColor.withOpacity(0.8),
        colorText: Colors.white,
      );
      Get.back();
    }
  }

  Future<void> _startDirectMerchantChat() async {
    if (merchantId == null) {
      Get.snackbar(
        'Error',
        'Data merchant tidak lengkap',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: alertColor.withOpacity(0.8),
        colorText: Colors.white,
      );
      Get.back();
      return;
    }

    isLoading.value = true;
    try {
      // Create a temporary order ID of 0 for direct chat (no order context)
      // Backend will handle this by creating chat without order association
      final chat = await _repository.initiateDirectMerchantChat(merchantId!);
      isLoading.value = false;

      if (chat?.id != null) {
        chatId = chat!.id;
        recipientId = merchantId;

        _fetchMessages(initial: true);
      } else {
        Get.snackbar(
          'Error',
          'Gagal memulai chat: Merchant tidak tersedia',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: alertColor.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.back();
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: alertColor.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      Get.back();
    }
  }

  Future<void> _initiateChatWithMerchant() async {
    if (orderId == null || merchantId == null) {
      Get.snackbar(
        'Error',
        'Data order tidak lengkap',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: alertColor.withOpacity(0.8),
        colorText: Colors.white,
      );
      Get.back();
      return;
    }

    debugPrint(
        'Initiating chat with merchant - orderId: $orderId, merchantId: $merchantId');

    isLoading.value = true;
    try {
      final chat =
          await _repository.initiateChat(orderId!, merchantId: merchantId!);
      isLoading.value = false;

      debugPrint('Initiate chat response: ${chat?.id}');

      if (chat?.id != null) {
        chatId = chat!.id;
        recipientId = chat!.customerId;

        await _loadMerchantName();

        debugPrint('Merchant chat initiated successfully - chatId: $chatId');

        _fetchMessages(initial: true);
      } else {
        // Fallback: Try to create chat with just order_id
        debugPrint('First attempt failed, trying fallback method...');
        await _initiateChatWithOrderOnly();
      }
    } catch (e) {
      isLoading.value = false;
      debugPrint('Error in _initiateChatWithMerchant: $e');

      // Fallback: Try to create chat with just order_id
      debugPrint('Trying fallback method after exception...');
      await _initiateChatWithOrderOnly();
    }
  }

  Future<void> _initiateChatWithOrderOnly() async {
    if (orderId == null) return;

    try {
      debugPrint('Fallback: Initiating chat with order_id only: $orderId');

      final chat = await _repository.initiateChatWithTransaction(orderId!);

      if (chat?.id != null) {
        chatId = chat!.id;
        debugPrint('Fallback successful - chatId: $chatId');

        await _loadRecipientInfo();
        _fetchMessages(initial: true);
      } else {
        debugPrint('Fallback also failed - chat is null');
        Get.snackbar(
          'Error',
          'Gagal memulai chat: Server tidak merespon',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: alertColor.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.back();
      }
    } catch (e) {
      debugPrint('Fallback failed: $e');
      Get.snackbar(
        'Error',
        'Gagal memulai chat: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: alertColor.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      Get.back();
    }
  }

  Future<void> _loadMerchantName() async {
    if (orderId == null || merchantId == null) return;

    try {
      // Get order data to find merchant name
      final orderData = await _repository.getOrderData(orderId!);

      if (orderData != null) {
        recipientName.value = orderData['merchantName'] ?? 'Merchant';
        recipientType.value = 'MERCHANT';
        recipientAvatar.value = orderData['merchantAvatar'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading merchant name: $e');
      // Use default value if failed to load
      recipientName.value = 'Merchant';
      recipientType.value = 'MERCHANT';
    }
  }

  Future<void> _initiateChatWithCourier() async {
    if (orderId == null) {
      Get.snackbar(
        'Error',
        'Data order tidak lengkap',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: alertColor.withOpacity(0.8),
        colorText: Colors.white,
      );
      Get.back();
      return;
    }

    debugPrint('Initiating chat with courier - orderId: $orderId');

    isLoading.value = true;
    try {
      // First, get transaction data to find courier info
      final transactionData = await _repository.getTransactionData(orderId!);

      // Check if courier exists
      if (transactionData == null) {
        debugPrint('Transaction data not found for order $orderId');
        Get.snackbar(
          'Error',
          'Data pesanan tidak ditemukan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: alertColor.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.back();
        isLoading.value = false;
        return;
      }

      final courierName = transactionData['courierName'];
      final courierStatus = transactionData['courierStatus'];
      final courierId = transactionData['courierId'];

      debugPrint(
          'Courier info - ID: $courierId, Name: $courierName, Status: $courierStatus');

      // Check if courier is assigned using courier_id (more reliable than name)
      if (courierId == null &&
          (courierName == null ||
              courierName == 'Kurir' ||
              courierName == 'Kurir Ditemukan' ||
              courierName.isEmpty)) {
        debugPrint('Courier not assigned yet for order $orderId');
        Get.snackbar(
          'Belum Ada Kurir',
          'Pesanan Anda belum memiliki kurir. Silakan tunggu hingga ada kurir yang menerima.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: alertColor.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        Get.back();
        isLoading.value = false;
        return;
      }

      debugPrint('Courier found: $courierName, Status: $courierStatus');

      // For courier chat, we don't need to pass courierId to initiateChat
      // The backend will determine recipient from transaction data
      debugPrint('Calling initiateChatWithTransaction with orderId: $orderId');
      final chat = await _repository.initiateChatWithTransaction(orderId!);
      isLoading.value = false;

      debugPrint('Initiate chat with courier response - chatId: ${chat?.id}');

      if (chat?.id != null) {
        chatId = chat!.id;
        recipientId = chat!.driverId;

        await _loadCourierInfo();

        debugPrint('Courier chat initiated successfully - chatId: $chatId');

        _fetchMessages(initial: true);
      } else {
        debugPrint(
            'Failed to initiate chat with courier - chat is null or chatId is null');
        Get.snackbar(
          'Error',
          'Gagal memulai chat dengan kurir. Pastikan kurir sudah ditugaskan.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: alertColor.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        Get.back();
      }
    } catch (e) {
      isLoading.value = false;
      debugPrint('Error in _initiateChatWithCourier: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: alertColor.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      Get.back();
    }
  }

  Future<void> _loadCourierInfo() async {
    if (orderId == null) return;

    try {
      // Get transaction data to find courier info
      final transactionData = await _repository.getTransactionData(orderId!);

      if (transactionData != null) {
        recipientName.value = transactionData['courierName'] ?? 'Kurir';
        recipientType.value = 'COURIER';
        recipientAvatar.value = transactionData['courierAvatar'] ?? '';
        chatStatus.value = transactionData['courierStatus'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading courier info: $e');
      // Use default value if failed to load
      recipientName.value = 'Kurir';
      recipientType.value = 'COURIER';
    }
  }

  Future<void> _loadRecipientInfo() async {
    if (chatId == null) {
      debugPrint('_loadRecipientInfo: SKIP - chatId is null');
      return;
    }

    try {
      debugPrint('_loadRecipientInfo: START - chatId=$chatId');
      debugPrint(
          '_loadRecipientInfo: Current recipientName.value="${recipientName.value}"');

      // Get chat details from backend API
      debugPrint('_loadRecipientInfo: Calling getChatDetails($chatId)...');
      final chatDetails = await _repository.getChatDetails(chatId!);

      if (chatDetails != null) {
        final currentUserId = _authService.currentUser.value?.id;
        debugPrint('_loadRecipientInfo: Current user ID: $currentUserId');
        debugPrint('_loadRecipientInfo: Chat details from API: $chatDetails');

        String recipientNameValue = chatDetails['recipientName'] ?? 'Chat';
        String recipientTypeValue = chatDetails['recipientType'] ?? '';
        String recipientAvatarValue = chatDetails['recipientAvatar'] ?? '';
        final recipientIdFromApi = chatDetails['recipientId'];

        debugPrint(
            '_loadRecipientInfo: API returned recipientId=$recipientIdFromApi, recipientName="$recipientNameValue"');

        // BACKEND FIX: API should return correct recipient name (other party)
        // If backend returns wrong name (current user's own name), fetch from order/transaction
        if (recipientIdFromApi == currentUserId && orderId != null) {
          debugPrint(
              '_loadRecipientInfo: WARNING - API returned current user as recipient! Fetching from order...');

          // Try to get customer info from order
          final orderData = await _repository.getOrderData(orderId!);
          if (orderData != null) {
            recipientNameValue = orderData['customerName'] ?? 'Customer';
            recipientTypeValue = 'USER';
            recipientAvatarValue = orderData['customerAvatar'] ?? '';
            debugPrint(
                '_loadRecipientInfo: Fixed from order - recipientName="$recipientNameValue"');
          }
        }

        debugPrint(
            '_loadRecipientInfo: Setting recipientName.value="$recipientNameValue"');
        recipientName.value = recipientNameValue;
        recipientType.value = recipientTypeValue;
        recipientAvatar.value = recipientAvatarValue;
        chatStatus.value = chatDetails['status'] ?? '';

        debugPrint(
            '_loadRecipientInfo: FINAL - Name="${recipientName.value}", Type=${recipientType.value}');
      } else {
        debugPrint('_loadRecipientInfo: ERROR - chatDetails is null from API');
        recipientName.value = 'Chat';
        recipientType.value = '';
      }
    } catch (e) {
      debugPrint('_loadRecipientInfo: EXCEPTION: $e');
      recipientName.value = 'Chat';
      recipientType.value = '';
    }
  }

  Future<void> _fetchMessages({bool initial = false}) async {
    if (chatId == null) return;

    if (initial) isLoading.value = true;

    final newMessages = await _repository.getMessages(chatId!);
    if (newMessages != null) {
      // Backend returns messages in ascending order: [oldest, ..., newest]
      // ListView with reverse: true displays:
      //   - First item (oldest) at bottom
      //   - Last item (newest) at top
      // So we need to reverse the list to get correct display order:
      //   - After reverse: [newest, ..., oldest]
      //   - With reverse: true → newest at bottom, oldest at top ✓
      messages.assignAll(newMessages.reversed.toList());

      // Scroll to show newest messages at bottom
      scrollToBottom();
    }

    if (initial) isLoading.value = false;
  }

  // Public method to fetch messages (called from FCM handler)
  Future<void> fetchMessages() async {
    debugPrint('fetchMessages: Fetching new messages for chatId: $chatId');
    await _fetchMessages();
    debugPrint('fetchMessages: Messages fetched successfully');
  }

  // Delete a message
  Future<void> deleteMessage(ChatMessage message) async {
    try {
      debugPrint('deleteMessage: Deleting message ${message.id}...');

      final success = await _repository.deleteMessage(chatId!, message.id);

      if (success) {
        debugPrint('deleteMessage: Message ${message.id} deleted successfully');

        // Remove from local list
        final messageIndex = messages.indexWhere((m) => m.id == message.id);
        if (messageIndex != -1) {
          messages.removeAt(messageIndex);
        }

        Get.snackbar(
          'Sukses',
          'Pesan berhasil dihapus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        debugPrint('deleteMessage: Failed to delete message ${message.id}');
        Get.snackbar(
          'Error',
          'Gagal menghapus pesan',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: alertColor.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('deleteMessage: Exception: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: alertColor.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> refreshMessages() async {
    await _fetchMessages();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (chatId != null) {
        refreshMessages();
      }
    }
  }

  void scrollToBottom() {
    // Use post frame callback to ensure ListView is built before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        // With reverse: true and reversed list [newest, ..., oldest]:
        // minScrollExtent shows newest messages (at bottom)
        scrollController.animateTo(
          scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    // Validate chatId
    if (chatId == null) {
      Get.snackbar(
        'Error',
        'Chat belum terhubung. Silakan coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: alertColor.withOpacity(0.8),
        colorText: Colors.white,
      );
      return;
    }

    // Validate message text
    if (messageController.text.trim().isEmpty) {
      return; // Don't send empty messages
    }

    final text = messageController.text;
    messageController.clear();

    // Optimistic UI Update (Locally prepend message)
    final optimisticMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      chatId: chatId!,
      senderId: currentUserId,
      message: text,
      type: 'TEXT',
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    // FIX: Use insert(0, ...) instead of add() because ListView has reverse: true
    // With reverse: true, first item in list appears at bottom (newest message position)
    messages.insert(0, optimisticMessage);
    scrollToBottom();

    isSending.value = true;

    try {
      // Send to Backend (MySQL + triggers FCM automatically)
      final newMessage = await _repository.sendMessage(chatId!, message: text);

      if (newMessage != null) {
        // Wait for the next poll or force fetch to ensure IDs are correct
        _fetchMessages();
      } else {
        Get.snackbar("Error", "Gagal mengirim pesan");
        messages.remove(optimisticMessage); // Revert optimistic update
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal mengirim pesan: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: alertColor.withOpacity(0.8),
        colorText: Colors.white,
      );
      messages.remove(optimisticMessage); // Revert optimistic update
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendImage() async {
    if (chatId == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      isSending.value = true;

      // Show loading indicator
      Get.dialog(
        Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(chatSecondary),
          ),
        ),
        barrierDismissible: false,
      );

      try {
        final newMessage =
            await _repository.sendMessage(chatId!, image: File(image.path));

        Get.back(); // Close loading dialog

        if (newMessage != null) {
          _fetchMessages();
          scrollToBottom();
        } else {
          Get.snackbar("Error", "Gagal mengirim gambar");
        }
      } catch (e) {
        Get.back(); // Close loading dialog
        Get.snackbar("Error", "Gagal mengirim gambar: ${e.toString()}");
      } finally {
        isSending.value = false;
      }
    }
  }

  /// Share current location
  Future<void> shareLocation() async {
    if (chatId == null) return;

    try {
      // Show loading indicator
      Get.dialog(
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(chatSecondary),
              ),
              SizedBox(height: 16),
              Text(
                'Mengambil lokasi...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.back(); // Close loading dialog
          Get.snackbar(
            'Permission Denied',
            'Lokasi tidak dapat diakses tanpa izin',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Get.back(); // Close loading dialog
        Get.snackbar(
          'Permission Denied',
          'Silakan aktifkan lokasi di pengaturan',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Get current location with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      Get.back(); // Close loading dialog

      // Confirm before sending
      bool? confirm = await Get.dialog(
        AlertDialog(
          title: Text('Kirim Lokasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Akurasi: ±${position.accuracy.toStringAsFixed(1)} meter'),
              SizedBox(height: 8),
              Text(
                'Lat: ${position.latitude.toStringAsFixed(6)}\nLng: ${position.longitude.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: Text('Kirim'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      isSending.value = true;

      final newMessage = await _repository.shareLocation(
        chatId!,
        latitude: position.latitude,
        longitude: position.longitude,
        locationAccuracy: position.accuracy,
        message: '📍 Lokasi saya saat ini',
      );

      if (newMessage != null) {
        _fetchMessages();
        scrollToBottom();
      } else {
        Get.snackbar("Error", "Gagal berbagi lokasi");
      }
    } catch (e) {
      Get.snackbar(
        "Error",
        "Gagal berbagi lokasi: ${e.toString()}",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSending.value = false;
    }
  }

  /// Show attachment options bottom sheet
  void showAttachmentOptions() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kirim Media',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.image,
                  label: 'Gambar',
                  color: chatSecondary,
                  onTap: () {
                    Get.back();
                    sendImage();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Lokasi',
                  color: Colors.red,
                  onTap: () {
                    Get.back();
                    shareLocation();
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
