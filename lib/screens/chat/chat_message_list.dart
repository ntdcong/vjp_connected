import 'package:flutter/material.dart';
import '../../models/message.dart';
import 'chat_message_item.dart';

class ChatMessageList extends StatelessWidget {
  final List<Message> messages;
  final ScrollController scrollController;
  final bool scrollToNewMessages;

  const ChatMessageList({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.scrollToNewMessages,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return ChatMessageItem(message: message);
          },
        ),
      ),
    );
  }
}