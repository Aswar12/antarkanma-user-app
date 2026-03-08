import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/data/models/chat_model.dart';
import 'package:antarkanma/app/data/repositories/chat_repository.dart';
import 'package:antarkanma/app/services/auth_service.dart';
import 'package:antarkanma/app/routes/app_pages.dart';

class ChatListController extends GetxController {
  final ChatRepository _repository = ChatRepository();
  final AuthService _authService = Get.find<AuthService>();

  final chats = <ChatModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchChats();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> fetchChats() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      debugPrint('Fetching chat list from API...');
      final chatList = await _repository.getChatList();

      if (chatList != null && chatList.isNotEmpty) {
        chats.assignAll(chatList);
      } else {
        debugPrint('No chats found');
        chats.clear();
      }
    } catch (e) {
      debugPrint('Error fetching chat list: $e');
      errorMessage.value = 'Gagal memuat chat: ${e.toString()}';
      chats.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToChat(ChatModel chat) {
    Get.toNamed(Routes.userChat, arguments: {
      'chatId': chat.id,
      'orderId': chat.orderId,
      'recipientName': chat.recipientName,
    });
  }

  int getTotalUnreadCount() {
    return chats.fold(0, (sum, chat) => sum + (chat.unreadCount ?? 0));
  }

  Future<void> markAsRead(int chatId) async {
    try {
      await _repository.markChatAsRead(chatId);
      // Update local state
      final chatIndex = chats.indexWhere((c) => c.id == chatId);
      if (chatIndex != -1) {
        chats[chatIndex].unreadCount = 0;
        chats.refresh();
      }
    } catch (e) {
      debugPrint('Error marking chat as read: $e');
    }
  }

  Future<void> refresh() async {
    await fetchChats();
  }

  Future<void> deleteChat(ChatModel chat) async {
    try {
      debugPrint('deleteChat: Deleting chat ${chat.id}...');

      final success = await _repository.deleteChat(chat.id);

      if (success) {
        debugPrint('deleteChat: Chat ${chat.id} deleted successfully');

        // Remove from local list
        final chatIndex = chats.indexWhere((c) => c.id == chat.id);
        if (chatIndex != -1) {
          chats.removeAt(chatIndex);
        }

        Get.snackbar(
          'Sukses',
          'Chat berhasil dihapus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        debugPrint('deleteChat: Failed to delete chat ${chat.id}');
        Get.snackbar(
          'Error',
          'Gagal menghapus chat',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: alertColor.withOpacity(0.8),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('deleteChat: Exception: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: alertColor.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
}
