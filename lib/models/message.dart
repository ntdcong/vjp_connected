class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final bool isRead;
  final String createdAt;
  final bool isMine;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.isRead,
    required this.createdAt,
    required this.isMine,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      isRead: json['is_read'],
      createdAt: json['created_at'],
      isMine: json['is_mine'],
    );
  }
}

class Conversation {
  final int userId;
  final String name;
  final String email;
  final LastMessage lastMessage;

  Conversation({
    required this.userId,
    required this.name,
    required this.email,
    required this.lastMessage,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      lastMessage: LastMessage.fromJson(json['last_message']),
    );
  }
}

class LastMessage {
  final int id;
  final String content;
  final String time;
  final bool isRead;

  LastMessage({
    required this.id,
    required this.content,
    required this.time,
    required this.isRead,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      id: json['id'],
      content: json['content'],
      time: json['time'],
      isRead: json['is_read'],
    );
  }
} 