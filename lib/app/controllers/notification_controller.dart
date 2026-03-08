import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/data/models/notification_model.dart';
import 'package:antarkanma/app/services/notification_api_service.dart';

class NotificationController extends GetxController {
  final NotificationApiService _apiService = NotificationApiService();

  final notifications = <NotificationModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final unreadCount = 0.obs;
  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
    fetchUnreadCount();
  }

  @override
  void onClose() {
    super.onClose();
  }

  /// Fetch all notifications
  Future<void> fetchNotifications({bool? unreadOnly}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final notificationList =
          await _apiService.getNotifications(unreadOnly: unreadOnly);

      if (notificationList != null) {
        notifications.assignAll(notificationList);
      } else {
        notifications.clear();
      }
    } catch (e) {
      errorMessage.value = 'Gagal memuat notifikasi: ${e.toString()}';
      notifications.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch unread notification count
  Future<void> fetchUnreadCount() async {
    try {
      final count = await _apiService.getUnreadCount();
      if (count != null) {
        unreadCount.value = count;
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(int notificationId) async {
    try {
      final success = await _apiService.markAsRead(notificationId);
      if (success) {
        // Update local state
        final notificationIndex =
            notifications.indexWhere((n) => n.id == notificationId);
        if (notificationIndex != -1) {
          final notification = notifications[notificationIndex];
          notifications[notificationIndex] = NotificationModel(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            data: notification.data,
            isRead: true,
            createdAt: notification.createdAt,
            imageUrl: notification.imageUrl,
          );
        }
        // Refresh unread count
        fetchUnreadCount();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final success = await _apiService.markAllAsRead();
      if (success) {
        // Update all notifications to read
        for (int i = 0; i < notifications.length; i++) {
          final notification = notifications[i];
          notifications[i] = NotificationModel(
            id: notification.id,
            type: notification.type,
            title: notification.title,
            message: notification.message,
            data: notification.data,
            isRead: true,
            createdAt: notification.createdAt,
            imageUrl: notification.imageUrl,
          );
        }
        // Reset unread count
        unreadCount.value = 0;
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      final success = await _apiService.deleteNotification(notificationId);
      if (success) {
        // Remove from local state
        notifications.removeWhere((n) => n.id == notificationId);
        // Refresh unread count
        fetchUnreadCount();
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Refresh notifications
  Future<void> refreshNotifications() async {
    await fetchNotifications();
    await fetchUnreadCount();
  }

  /// Navigate to notification detail or action
  void navigateToNotification(NotificationModel notification) async {
    // Mark as read when tapped
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    // You can handle routing logic based on notification type here
    // e.g., if (notification.type == 'order_ready') { Get.toNamed('/order-detail', arguments: notification.data?['order_id']); }
  }

  int getNotificationColor(String type) {
    switch (type) {
      case 'order_ready':
      case 'order_approved':
      case 'order_completed':
      case 'order_picked_up':
      case 'courier_arrived_at_customer':
        return 0xFF4CAF50; // Green
      case 'order_canceled':
      case 'order_rejected':
        return 0xFFF44336; // Red
      case 'courier_found':
      case 'courier_at_merchant':
        return 0xFF2196F3; // Blue
      default:
        return 0xFFFFA000; // Orange (Primary brand)
    }
  }

  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'order_ready':
      case 'order_completed':
        return Icons.shopping_bag;
      case 'order_approved':
        return Icons.check_circle_outline;
      case 'order_canceled':
      case 'order_rejected':
        return Icons.cancel_outlined;
      case 'order_picked_up':
      case 'courier_found':
      case 'courier_at_merchant':
      case 'courier_arrived_at_customer':
        return Icons.delivery_dining;
      default:
        return Icons.notifications_none;
    }
  }
}
