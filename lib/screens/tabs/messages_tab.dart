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
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Nếu chưa đăng nhập, hiển thị màn hình yêu cầu đăng nhập
    if (!authProvider.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tin nhắn'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Vui lòng đăng nhập để xem tin nhắn của bạn'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Đăng nhập ngay'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
      ),
      body: Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
          if (messageProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (messageProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    messageProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      messageProvider.fetchConversations();
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (messageProvider.conversations.isEmpty) {
            return const Center(
              child: Text('Không có cuộc trò chuyện nào'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: messageProvider.conversations.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final conversation = messageProvider.conversations[index];
              return ConversationItem(conversation: conversation);
            },
          );
        },
      ),
    );
  }
}

class ConversationItem extends StatelessWidget {
  final Conversation conversation;

  const ConversationItem({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(DateTime.parse(conversation.lastMessage.time));
    final hasUnreadMessages = !conversation.lastMessage.isRead;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              userId: conversation.userId,
              userName: conversation.name,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, size: 30, color: Colors.white),
                ),
                if (hasUnreadMessages)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: hasUnreadMessages
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnreadMessages ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation.lastMessage.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasUnreadMessages ? Colors.black87 : Colors.grey[600],
                      fontWeight: hasUnreadMessages
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
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