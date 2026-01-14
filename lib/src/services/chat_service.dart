import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatService {
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  String get myUid => _auth.currentUser!.uid;

  DatabaseReference chatRoomRef(String chatRoomId) {
    return _db.child('chat_rooms').child(chatRoomId);
  }

  /// 🔥 SEND MESSAGE
  Future<void> sendMessage({
    required String chatRoomId,
    required String text,
  }) async {
    final msgRef = chatRoomRef(chatRoomId)
        .child('messages')
        .push();

    await msgRef.set({
      'senderId': myUid,
      'text': text.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// 🔥 LISTEN TO MESSAGES (REALTIME)
  Query messageStream(String chatRoomId) {
    return chatRoomRef(chatRoomId)
        .child('messages')
        .orderByChild('timestamp');
  }
}
