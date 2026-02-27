class Chat {
  final int id;
  final int orderId;
  final int customerId;
  final int? driverId;
  final String status;
  final String createdAt;
  final String updatedAt;
  final List<ChatMessage>? messages;

  Chat({
    required this.id,
    required this.orderId,
    required this.customerId,
    this.driverId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.messages,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      orderId: json['order_id'],
      customerId: json['customer_id'],
      driverId: json['driver_id'],
      status: json['status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((i) => ChatMessage.fromJson(i))
              .toList()
          : null,
    );
  }
}

class ChatMessage {
  final int id;
  final int chatId;
  final int senderId;
  final String? message;
  final String type; // 'text', 'image', 'system'
  final String? imagePath;
  final bool isRead;
  final String createdAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.message,
    required this.type,
    this.imagePath,
    required this.isRead,
    required this.createdAt,
    required String updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: int.tryParse(json['id'].toString()) ?? 0,
      chatId: int.tryParse(json['chat_id'].toString()) ?? 0,
      senderId: int.tryParse(json['sender_id'].toString()) ?? 0,
      message: json['message'],
      type: json['type'],
      imagePath: json['image_path'],
      isRead: json['is_read'] == 1 ||
          json['is_read'] == true ||
          json['is_read'] == '1',
      createdAt: json['created_at'],
      updatedAt: '',
    );
  }
}
