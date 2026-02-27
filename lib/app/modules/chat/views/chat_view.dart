import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:antarkanma/app/data/models/chat_model.dart';
import 'package:antarkanma/theme.dart';
import '../controllers/chat_controller.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: chatBackgroundLight,
      body: Stack(
        children: [
          Column(
            children: [
              // Custom Header + Status Bar
              _buildHeader(),

              // Chat Content
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(chatSecondary),
                      ),
                    );
                  }

                  if (controller.messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 48,
                              color: chatTextSecondary.withOpacity(0.5)),
                          SizedBox(height: 16),
                          Text(
                            "Belum ada pesan. Mulai obrolan!",
                            style: secondaryTextStyle.copyWith(
                                color: chatTextSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: controller.scrollController,
                    padding: EdgeInsets.only(
                      top: 16,
                      bottom: 180, // Space for input area + quick replies
                      left: 16,
                      right: 16,
                    ),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[index];
                      final bool isMe =
                          message.senderId == controller.currentUserId;

                      // Show date separator if needed (simplified logic for now)
                      bool showDate = false;
                      if (index == 0) {
                        showDate = true;
                      } else {
                        final prevDate = DateTime.parse(
                                controller.messages[index - 1].createdAt)
                            .toLocal();
                        final currDate =
                            DateTime.parse(message.createdAt).toLocal();
                        if (prevDate.day != currDate.day ||
                            prevDate.month != currDate.month ||
                            prevDate.year != currDate.year) {
                          showDate = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDate) _buildDateSeparator(message.createdAt),
                          _buildMessageBubble(message, isMe),
                        ],
                      );
                    },
                  );
                }),
              ),
            ],
          ),

          // Bottom Input Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInputArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                  height: MediaQuery.of(Get.context!).padding.top), // Safe Area
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Get.back(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back_ios_new,
                            size: 20, color: chatTextSecondary),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade200,
                                ),
                                child: ClipOval(
                                  // Placeholder image or NetworkImage if available
                                  child: Icon(Icons.person, color: Colors.grey),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // TODO: Get name dynamically from controller
                                "Driver",
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: chatTextDark,
                                ),
                              ),
                              Text(
                                "Driver Antarkanma",
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                  color: chatTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.call, color: chatPrimary, size: 20),
                    ),
                  ],
                ),
              ),
              // Status Bar
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: chatSecondary.withOpacity(0.1),
                  border: Border(
                      top: BorderSide(color: chatSecondary.withOpacity(0.2))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.moped, size: 16, color: chatSecondary),
                        SizedBox(width: 8),
                        Text(
                          "Driver sedang menuju lokasi",
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "LIHAT PETA",
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: chatSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSeparator(String timestamp) {
    // Ideally format this based on logic (Today, Yesterday, Date)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "HARI INI", // Placeholder, use DateFormat
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 10,
              color: chatTextSecondary,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: Get.width * 0.85),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          textDirection: isMe ? TextDirection.rtl : TextDirection.ltr,
          children: [
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isMe ? chatPrimary : chatBubbleMerchant,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: isMe ? Radius.circular(16) : Radius.circular(0),
                    bottomRight:
                        isMe ? Radius.circular(0) : Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                  border: isMe ? null : Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.type == 'image' && message.imagePath != null)
                      // Placeholder for Image Display
                      Icon(Icons.image,
                          color: isMe ? Colors.white : chatTextDark),
                    if (message.message != null && message.message!.isNotEmpty)
                      Text(
                        message.message!,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: isMe ? Colors.white : chatTextDark,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 4),
            // Timestamp
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: chatTextSecondary,
                fontSize: 10,
              ),
            ),
            if (isMe) ...[
              SizedBox(width: 2),
              Icon(Icons.done_all,
                  size: 14, color: message.isRead ? Colors.blue : Colors.grey),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick Replies
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildQuickReplyButton("Sudah sampai mana?"),
              SizedBox(width: 8),
              _buildQuickReplyButton("Sesuai aplikasi ya"),
              SizedBox(width: 8),
              _buildQuickReplyButton("Terima kasih"),
            ],
          ),
        ),

        // Input Field
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.add_circle, color: chatTextSecondary),
                onPressed: () {
                  // TODO: Show attachment options
                  controller.sendImage();
                },
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: chatBackgroundLight,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller.messageController,
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan...',
                            hintStyle: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: chatTextSecondary,
                            ),
                            border: InputBorder.none,
                          ),
                          minLines: 1,
                          maxLines: 4,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            color: chatTextDark,
                          ),
                        ),
                      ),
                      Icon(Icons.mood, color: chatTextSecondary),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Obx(() => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: chatPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: controller.isSending.value
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: controller.isSending.value
                          ? null
                          : controller.sendMessage,
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickReplyButton(String text) {
    return InkWell(
      onTap: () {
        controller.messageController.text = text;
        controller.sendMessage();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: chatTextDark,
          ),
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return '';
    }
  }
}
