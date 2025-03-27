import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vjp_connected/providers/message_provider.dart';
import '../../models/message.dart';
import '../../widgets/image_gallery_view.dart';

class ChatMessageItem extends StatelessWidget {
  final Message message;

  const ChatMessageItem({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isMine = message.isMine;
    final String time = DateFormat('HH:mm').format(DateTime.parse(message.createdAt));
    final bool hasImage = (message.image?.isNotEmpty ?? false) || 
                          (message.imageUrl?.isNotEmpty ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) _buildAvatar(),
          Flexible(
            child: _buildMessageContainer(context, isMine, hasImage, time),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFF2AABEE).withOpacity(0.1),
          child: const Icon(
            Icons.person,
            size: 18,
            color: Color(0xFF2AABEE),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMessageContainer(BuildContext context, bool isMine, bool hasImage, String time) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      decoration: _buildMessageDecoration(isMine),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage) _buildImageContent(context, isMine),
          if (message.content?.isNotEmpty ?? false) _buildTextContent(isMine),
          _buildMessageFooter(isMine, time),
        ],
      ),
    );
  }

  BoxDecoration _buildMessageDecoration(bool isMine) {
    return BoxDecoration(
      color: isMine ? const Color(0xFF2AABEE) : Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(16),
        topRight: const Radius.circular(16),
        bottomLeft: Radius.circular(isMine ? 16 : 4),
        bottomRight: Radius.circular(isMine ? 4 : 16),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _buildImageContent(BuildContext context, bool isMine) {
    return GestureDetector(
      onTap: () => _openImageGallery(context),
      child: Hero(
        tag: 'image_${message.id}',
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Image.network(
            message.imageUrl ?? message.image ?? '',
            fit: BoxFit.cover,
            loadingBuilder: _buildImageLoadingIndicator,
            errorBuilder: _buildImageErrorWidget,
          ),
        ),
      ),
    );
  }

  Widget _buildImageLoadingIndicator(BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) return child;
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          value: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
              : null,
          valueColor: AlwaysStoppedAnimation<Color>(
            message.isMine ? Colors.white70 : const Color(0xFF2AABEE),
          ),
        ),
      ),
    );
  }

  Widget _buildImageErrorWidget(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      height: 200,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: message.isMine ? Colors.white70 : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Không thể tải ảnh',
              style: TextStyle(
                color: message.isMine ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent(bool isMine) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        message.content!,
        style: TextStyle(
          color: isMine ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildMessageFooter(bool isMine, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            time,
            style: TextStyle(
              color: isMine ? Colors.white70 : Colors.black45,
              fontSize: 11,
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 4),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              size: 14,
              color: message.isRead ? Colors.white : Colors.white70,
            ),
          ],
        ],
      ),
    );
  }

  void _openImageGallery(BuildContext context) {
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    final imageMessages = messageProvider.messages
        .where((m) => (m.image?.isNotEmpty ?? false) || (m.imageUrl?.isNotEmpty ?? false))
        .toList();
    final currentIndex = imageMessages.indexOf(message);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryView(
          initialImage: message.imageUrl ?? message.image ?? '',
          messages: imageMessages,
          currentMessage: message,
          initialIndex: currentIndex,
          images: imageMessages.map((m) => m.imageUrl ?? m.image ?? '').toList(),
        ),
      ),
    );
  }
}