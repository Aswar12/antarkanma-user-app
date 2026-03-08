import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';
import '../controllers/chat_list_controller.dart';
import 'widgets/chat_list_tile.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with WidgetsBindingObserver {
  ChatListController? controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Controller will be initialized in build method using GetBuilder
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh when app comes to foreground
      debugPrint('App resumed, refreshing chat list');
      controller?.fetchChats();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatListController>(
      init: ChatListController(),
      builder: (ctrl) {
        controller = ctrl;

        return Scaffold(
          backgroundColor: backgroundColor3,
          appBar: AppBar(
            title: Text(
              'Chat Saya',
              style: primaryTextStyle.copyWith(
                fontSize: 20,
                fontWeight: semiBold,
              ),
            ),
            centerTitle: true,
            backgroundColor: backgroundColor2,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: logoColorSecondary),
                onPressed: () => controller!.refresh(),
              ),
            ],
          ),
          body: Obx(() {
            if (controller!.isLoading.value && controller!.chats.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(logoColorSecondary),
                ),
              );
            }

            if (controller!.chats.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () => controller!.refresh(),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: controller!.chats.length,
                itemBuilder: (context, index) {
                  final chat = controller!.chats[index];
                  return Dismissible(
                    key: Key('chat_${chat.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: alertColor,
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Hapus Chat'),
                          content: Text(
                            'Apakah Anda yakin ingin menghapus chat dengan ${chat.recipientName}?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Batal'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: alertColor,
                              ),
                              child: Text('Hapus'),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (direction) {
                      controller!.deleteChat(chat);
                    },
                    child: ChatListTile(chat: chat),
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: secondaryTextColor.withOpacity(0.5),
          ),
          SizedBox(height: 24),
          Text(
            'Belum Ada Chat',
            style: primaryTextStyle.copyWith(
              fontSize: 18,
              fontWeight: semiBold,
            ),
          ),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Mulai chat dengan merchant atau kurir dari halaman pesanan Anda',
              style: secondaryTextStyle.copyWith(
                fontSize: 14,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
