import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:antarkanma/app/data/models/chat_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _chatsCollection => _firestore.collection('chats');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create or Get Chat
  Future<void> createChat(int orderId, int customerId, int? driverId) async {
    final docRef = _chatsCollection.doc(orderId.toString());

    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await docRef.set({
        'order_id': orderId,
        'participants': [customerId, if (driverId != null) driverId],
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'status': 'open',
      });
    }
  }

  // Send Message
  Future<void> sendMessage(int orderId, ChatMessage message) async {
    final chatDoc = _chatsCollection.doc(orderId.toString());
    final messagesCollection = chatDoc.collection('messages');

    await messagesCollection.add({
      'sender_id': message.senderId,
      'text': message.message,
      'type': message.type,
      'image_url': message
          .imagePath, // Assuming imagePath stores URL or local path (needs handling for upload)
      'timestamp': FieldValue.serverTimestamp(),
      'is_read': false,
    });

    await chatDoc.update({
      'last_message': {
        'text': message.type == 'image' ? 'Sent an image' : message.message,
        'sender_id': message.senderId,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
      },
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Get Messages Stream
  Stream<List<ChatMessage>> getMessagesStream(int orderId) {
    return _chatsCollection
        .doc(orderId.toString())
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Handle Timestamp conversion
        String createdAt = '';
        if (data['timestamp'] is Timestamp) {
          createdAt = (data['timestamp'] as Timestamp).toDate().toString();
        } else {
          createdAt = DateTime.now().toString();
        }

        return ChatMessage(
          id: doc.id.hashCode, // Temporary ID generation
          chatId: orderId,
          senderId: data['sender_id'],
          message: data['text'] ?? '',
          type: data['type'] ?? 'text',
          imagePath: data['image_url'], // Map back to model field
          isRead: data['is_read'] ?? false,
          createdAt: createdAt,
          updatedAt: createdAt,
        );
      }).toList();
    });
  }
}
