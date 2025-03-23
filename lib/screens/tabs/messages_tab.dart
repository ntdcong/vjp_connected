import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/message_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/message.dart';
import '../chat_screen.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        Provider.of<MessageProvider>(context, listen: false).fetchConversations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tin nhắn',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF2AABEE)),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Consumer<MessageProvider>(
          builder: (context, messageProvider, child) {
            if (messageProvider.isLoadingConversations) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2AABEE)),
                ),
              );
            }

            if (messageProvider.conversationError != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      messageProvider.conversationError!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        messageProvider.fetchConversations();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2AABEE),
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              );
            }

            if (messageProvider.conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có cuộc trò chuyện nào',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2AABEE),
                      ),
                      child: const Text('Tạo cuộc trò chuyện mới'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                await messageProvider.fetchConversations();
              },
              color: const Color(0xFF2AABEE),
              child: ListView.separated(
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 16,
                ),
                itemCount: messageProvider.conversations.length,
                itemBuilder: (context, index) {
                  final conversation = messageProvider.conversations[index];
                  return _buildConversationItem(context, conversation);
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF2AABEE),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildConversationItem(BuildContext context, Conversation conversation) {
    // Lấy nội dung tin nhắn cuối cùng
    String lastMessageContent = conversation.lastMessage.content;
    if (conversation.lastMessage.imageUrl != null && conversation.lastMessage.imageUrl!.isNotEmpty) {
      lastMessageContent = '🖼️ Hình ảnh';
    }

    // Định dạng thời gian
    DateTime messageTime = DateTime.parse(conversation.lastMessage.time);
    String formattedTime = '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(messageTime.year, messageTime.month, messageTime.day);
    
    if (messageDate == today) {
      // Nếu là tin nhắn của hôm nay, hiển thị giờ
      formattedTime = DateFormat('HH:mm').format(messageTime);
    } else if (messageDate == yesterday) {
      // Nếu là tin nhắn của hôm qua, hiển thị "Hôm qua"
      formattedTime = 'Hôm qua';
    } else {
      // Nếu là tin nhắn cũ hơn, hiển thị ngày tháng
      formattedTime = DateFormat('dd/MM').format(messageTime);
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userId: conversation.userId,
              userName: conversation.name,
            ),
          ),
        ).then((_) {
          // Refresh conversations when coming back
          Provider.of<MessageProvider>(context, listen: false).fetchConversations();
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFF2AABEE).withOpacity(0.2),
                  child: Text(
                    conversation.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2AABEE),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        formattedTime,
                        style: TextStyle(
                          color: conversation.lastMessage.isRead
                              ? Colors.grey[500]
                              : const Color(0xFF2AABEE),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // Nếu tin nhắn chưa đọc thì hiển thị đậm
                      Expanded(
                        child: Text(
                          lastMessageContent,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: conversation.lastMessage.isRead
                                ? Colors.grey[600]
                                : Colors.black87,
                            fontWeight: conversation.lastMessage.isRead
                                ? FontWeight.normal
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!conversation.lastMessage.isRead)
                        Container(
                          padding: const EdgeInsets.all(6),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2AABEE),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 