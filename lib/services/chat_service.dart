import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_room_model.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _rooms =>
      _firestore.collection('chatRooms');

  CollectionReference<Map<String, dynamic>> _messagesOf(String roomId) =>
      _rooms.doc(roomId).collection('messages');

  /// Envoie un message et met à jour le chatRoom parent en une transaction.
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    if (content.trim().isEmpty) return;

    final roomId = ChatRoomModel.buildId(senderId, receiverId);
    final roomRef = _rooms.doc(roomId);
    final msgRef = _messagesOf(roomId).doc();

    final message = MessageModel(
      id: msgRef.id,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      isRead: false,
    );

    await _firestore.runTransaction((tx) async {
      final roomSnap = await tx.get(roomRef);
      final previewText =
          type == MessageType.image ? '📷 Image' : content;

      if (!roomSnap.exists) {
        final room = ChatRoomModel(
          id: roomId,
          participants: [senderId, receiverId],
          lastMessage: previewText,
          lastSenderId: senderId,
          lastMessageTime: message.timestamp,
          unreadCount: {senderId: 0, receiverId: 1},
        );
        tx.set(roomRef, room.toMap());
      } else {
        final data = roomSnap.data()!;
        final unread = Map<String, int>.from(data['unreadCount'] ?? {});
        unread[receiverId] = (unread[receiverId] ?? 0) + 1;
        unread[senderId] = unread[senderId] ?? 0;

        tx.update(roomRef, {
          'lastMessage': previewText,
          'lastSenderId': senderId,
          'lastMessageTime': Timestamp.fromDate(message.timestamp),
          'unreadCount': unread,
        });
      }

      tx.set(msgRef, message.toMap());
    });
  }

  Stream<List<MessageModel>> watchMessages(String uidA, String uidB) {
    final roomId = ChatRoomModel.buildId(uidA, uidB);
    return _messagesOf(roomId)
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromMap(d.data())).toList());
  }

  /// Conversations d'un utilisateur, triées par activité récente.
  Stream<List<ChatRoomModel>> watchUserChatRooms(String uid) {
    return _rooms
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatRoomModel.fromMap(d.data())).toList());
  }

  /// Marque tous les messages reçus de [otherUid] comme lus et remet à 0 le compteur.
  Future<void> markAsRead({
    required String currentUid,
    required String otherUid,
  }) async {
    final roomId = ChatRoomModel.buildId(currentUid, otherUid);
    final unread = await _messagesOf(roomId)
        .where('receiverId', isEqualTo: currentUid)
        .where('isRead', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final d in unread.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    batch.update(_rooms.doc(roomId), {'unreadCount.$currentUid': 0});
    await batch.commit();
  }

}
