import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final String lastSenderId;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;

  ChatRoomModel({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastSenderId,
    required this.lastMessageTime,
    required this.unreadCount,
  });

  /// ID déterministe pour une conversation 1-à-1 : trie les UIDs puis les joint.
  static String buildId(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'participants': participants,
        'lastMessage': lastMessage,
        'lastSenderId': lastSenderId,
        'lastMessageTime': Timestamp.fromDate(lastMessageTime),
        'unreadCount': unreadCount,
      };

  factory ChatRoomModel.fromMap(Map<String, dynamic> map) {
    return ChatRoomModel(
      id: map['id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastSenderId: map['lastSenderId'] ?? '',
      lastMessageTime:
          (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
    );
  }

  String otherParticipant(String currentUid) =>
      participants.firstWhere((id) => id != currentUid, orElse: () => '');
}
