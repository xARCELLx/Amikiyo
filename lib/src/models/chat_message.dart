class ChatMessage {
  final String senderId;
  final String text;
  final int timestamp;

  ChatMessage({
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<dynamic, dynamic> data) {
    return ChatMessage(
      senderId: data['senderId'],
      text: data['text'],
      timestamp: data['timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
