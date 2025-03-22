class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final String? image;
  final String? imageUrl;
  final bool isRead;
  final String createdAt;
  final bool isMine;
  final bool isOnline;
  final String? readAt;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.image,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
    required this.isMine,
    this.isOnline = false,
    this.readAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['image_url'];
    if (imageUrl != null && imageUrl.contains('<br />')) {
      imageUrl = imageUrl.replaceAll('<br />', '').trim();
    }
    
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      image: json['image'],
      imageUrl: imageUrl,
      isRead: json['is_read'],
      createdAt: json['created_at'],
      isMine: json['is_mine'],
      isOnline: json['is_online'] ?? false,
      readAt: json['read_at'],
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
  final String? imageUrl;

  LastMessage({
    required this.id,
    required this.content,
    required this.time,
    required this.isRead,
    this.imageUrl,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    String? imageUrl = json['image_url'];
    if (imageUrl != null && imageUrl.contains('<br />')) {
      imageUrl = imageUrl.replaceAll('<br />', '').trim();
    }
    
    return LastMessage(
      id: json['id'],
      content: json['content'],
      time: json['time'],
      isRead: json['is_read'],
      imageUrl: imageUrl,
    );
  }
}