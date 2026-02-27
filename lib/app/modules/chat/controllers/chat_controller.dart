import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/app/data/models/chat_model.dart';
import 'package:antarkanma/app/data/repositories/chat_repository.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/services/firestore_service.dart';

class ChatController extends GetxController {
  final ChatRepository _repository = ChatRepository();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = Get.find<AuthService>();

  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isSending = false.obs;

  final messageController = TextEditingController();
  final scrollController = ScrollController();

  int? chatId;
  int? orderId;
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  // Retrieve current user ID
  int get currentUserId => _authService.currentUser.value?.id ?? 0;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null) {
      if (args['chatId'] != null) {
        chatId = args['chatId'];
        orderId = args[
            'orderId']; // Ensure orderId is passed if possible, or derive/fetch it.
        // If we only have chatId, we might need to fetch the chat details to get the orderId
        // because FirestoreService uses orderId as document ID in our design.
        // Wait, the design said chat document ID is `{orderId}`.
        // The repository `initiateChat` returns a Chat object which has `orderId`.
        // If we entered via `chatId`, we assume we can map it.
        // For now, let's assume `chatId` == `orderId` or use `chatId` as the document Key if appropriate.
        // actually, in `_initiateChat` below, we use `chat.id` which is the database ID.
        // Let's stick to using `chatId` (Database ID) consistency for Firestore Doc ID to be safe,
        // OR fix the design to use `chatId`.
        // The previous design said `chats/{orderId}`.
        // But `ChatRepository` works with `chatId`.
        // Let's use `chatId` for Firestore Doc ID to align with the SQL ID.
        _setupFirestoreListener();
      } else if (args['orderId'] != null) {
        _initiateChat(args['orderId']);
      }
    }
  }

  Future<void> _initiateChat(int orderId) async {
    isLoading.value = true;
    final chat = await _repository.initiateChat(orderId);
    if (chat != null) {
      chatId = chat.id;
      this.orderId = orderId;

      // Initialize Firestore Chat Document
      await _firestoreService.createChat(chatId!, currentUserId, chat.driverId);

      _setupFirestoreListener();
    } else {
      Get.snackbar("Error", "Gagal memulai chat");
    }
    isLoading.value = false;
  }

  void _setupFirestoreListener() {
    if (chatId == null) return;

    // Subscribe to Firestore Stream
    _messagesSubscription =
        _firestoreService.getMessagesStream(chatId!).listen((newMessages) {
      messages.assignAll(newMessages);
      scrollToBottom();
    });
  }

  @override
  void onClose() {
    _messagesSubscription?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    if (chatId == null || messageController.text.trim().isEmpty) return;

    final text = messageController.text;
    messageController.clear();
    isSending.value = true;

    // 1. Send to Backend (MySQL + FCM)
    final newMessage = await _repository.sendMessage(chatId!, message: text);

    // 2. Send to Firestore (Real-time UI)
    if (newMessage != null) {
      // We use the returned message to get the ID and Timestamp from server if needed,
      // but Firestore generates its own.
      // To avoid duplicates if the stream listener picks it up,
      // we just push to Firestore. The stream will update `messages`.
      // We construct a ChatMessage for Firestore.
      final fsMessage = ChatMessage(
        id: 0, // Placeholder
        chatId: chatId!,
        senderId: currentUserId,
        message: text,
        type: 'text',
        isRead: false,
        createdAt: DateTime.now().toString(), updatedAt: '',
      );
      await _firestoreService.sendMessage(chatId!, fsMessage);
      // We don't manually add to `messages` because the stream will do it.
      scrollToBottom();
    } else {
      Get.snackbar("Error", "Gagal mengirim pesan");
    }

    isSending.value = false;
  }

  Future<void> sendImage() async {
    if (chatId == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      isSending.value = true;

      // 1. Upload to Backend (MySQL + Storage)
      final newMessage =
          await _repository.sendMessage(chatId!, image: File(image.path));

      // 2. Send Metadata to Firestore
      if (newMessage != null) {
        // Assuming newMessage.imagePath contains the URL returned by backend
        final fsMessage = ChatMessage(
          id: 0,
          chatId: chatId!,
          senderId: currentUserId,
          message: '',
          type: 'image',
          imagePath: newMessage.imagePath,
          isRead: false,
          createdAt: DateTime.now().toString(),
          updatedAt: DateTime.now().toString(),
        );
        await _firestoreService.sendMessage(chatId!, fsMessage);
        scrollToBottom();
      } else {
        Get.snackbar("Error", "Gagal mengirim gambar");
      }
      isSending.value = false;
    }
  }
}
