import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/data/models/chat_model.dart';
import 'package:antarkanma/app/services/image_service.dart';
import '../../controllers/chat_list_controller.dart';

class ChatListTile extends StatelessWidget {
  final ChatModel chat;

  const ChatListTile({
    Key? key,
    required this.chat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ChatListController>();

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Dimenssions.width15,
        vertical: Dimenssions.height5,
      ),
      padding: EdgeInsets.all(Dimenssions.height12),
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => controller.navigateToChat(chat),
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
        child: Row(
          children: [
            // Avatar with image or icon
            _buildAvatar(),
            SizedBox(width: Dimenssions.width12),

            // Chat Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.recipientName,
                          style: primaryTextStyle.copyWith(
                            fontSize: Dimenssions.font14,
                            fontWeight: semiBold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: Dimenssions.width8),
                      Text(
                        _formatTime(chat.lastMessageAt),
                        style: secondaryTextStyle.copyWith(
                          fontSize: Dimenssions.font10,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Dimenssions.height4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? 'Belum ada pesan',
                          style: secondaryTextStyle.copyWith(
                            fontSize: Dimenssions.font12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.unreadCount != null &&
                          chat.unreadCount! > 0) ...[
                        SizedBox(width: Dimenssions.width8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Dimenssions.width6,
                            vertical: Dimenssions.height2,
                          ),
                          decoration: BoxDecoration(
                            color: alertColor,
                            shape: BoxShape.circle,
                          ),
                          constraints: BoxConstraints(
                            minWidth: Dimenssions.width20,
                            minHeight: Dimenssions.height20,
                          ),
                          child: Text(
                            chat.unreadCount! > 9
                                ? '9+'
                                : chat.unreadCount.toString(),
                            style: primaryTextStyle.copyWith(
                              fontSize: Dimenssions.font10,
                              fontWeight: bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    // Check if avatar URL is available and valid
    final hasAvatar = chat.recipientAvatar != null &&
        chat.recipientAvatar!.isNotEmpty &&
        chat.recipientAvatar!.startsWith('http');

    if (hasAvatar) {
      // Show profile image
      return Container(
        width: Dimenssions.width50,
        height: Dimenssions.height50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: logoColorSecondary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: ClipOval(
          child: ImageService.to.buildProductThumbnail(
            chat.recipientAvatar!,
            size: Dimenssions.height50,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Show placeholder with icon
      return Container(
        width: Dimenssions.width50,
        height: Dimenssions.height50,
        decoration: BoxDecoration(
          color: logoColorSecondary.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: logoColorSecondary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          _getIconForType(chat.recipientType),
          color: logoColorSecondary,
          size: Dimenssions.font24,
        ),
      );
    }
  }

  IconData _getIconForType(String type) {
    switch (type.toUpperCase()) {
      case 'MERCHANT':
        return Icons.store;
      case 'COURIER':
        return Icons.delivery_dining;
      case 'USER':
        return Icons.person;
      default:
        return Icons.chat_bubble;
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';

    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        return DateFormat('HH:mm').format(dateTime);
      } else if (difference.inDays == 1) {
        return 'Kemarin';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE', 'id_ID').format(dateTime);
      } else {
        return DateFormat('dd/MM/yy').format(dateTime);
      }
    } catch (e) {
      return '';
    }
  }
}
