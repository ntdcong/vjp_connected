import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vjp_connected/widgets/image_gallery_view.dart';
import 'dart:io';
import '../providers/message_provider.dart';
import 'dart:async';

class ChatScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _scrollToNewMessages = true;
  
  // Sử dụng để theo dõi hoạt động của người dùng
  DateTime _lastUserActivity = DateTime.now();
  Timer? _userActivityTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Tải tin nhắn ban đầu
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      messageProvider.fetchMessages(widget.userId);
      
      // Đảm bảo polling được kích hoạt khi màn hình chat mở
      if (!messageProvider.isPollingActive) {
        messageProvider.startPolling();
      }
      
      // Cập nhật thời gian hoạt động
      messageProvider.updateLastActivity();
    });
    
    // Lắng nghe sự kiện cuộn để quyết định có tự động cuộn xuống khi có tin nhắn mới không
    _scrollController.addListener(_scrollListener);
    
    // Thiết lập timer để theo dõi khi nào người dùng không hoạt động
    _setupUserActivityTimer();
  }
  
  void _setupUserActivityTimer() {
    // Hủy timer cũ nếu có
    _userActivityTimer?.cancel();
    
    // Tạo timer mới kiểm tra mỗi 30 giây
    _userActivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final now = DateTime.now();
      final timeSinceLastActivity = now.difference(_lastUserActivity);
      
      // Nếu người dùng không hoạt động trong 2 phút, không cần polling nhanh nữa
      if (timeSinceLastActivity > const Duration(minutes: 2)) {
        // Không cần cập nhật gì ở đây vì MessageProvider sẽ tự động điều chỉnh tốc độ
      }
    });
  }
  
  // Cập nhật thời gian hoạt động của người dùng
  void _updateUserActivity() {
    _lastUserActivity = DateTime.now();
    Provider.of<MessageProvider>(context, listen: false).updateLastActivity();
  }
  
  void _scrollListener() {
    // Cập nhật hoạt động người dùng khi cuộn
    _updateUserActivity();
    
    // Nếu người dùng đang ở cuối danh sách tin nhắn, tự động cuộn xuống khi có tin nhắn mới
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      // Nếu vị trí cuộn hiện tại gần với vị trí cuộn tối đa, coi như người dùng ở cuối
      _scrollToNewMessages = (maxScroll - currentScroll) < 50;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quản lý polling dựa trên trạng thái ứng dụng
    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // Ứng dụng trở lại foreground, bắt đầu polling lại (nếu đã dừng)
        _updateUserActivity(); // Cập nhật hoạt động khi người dùng quay lại ứng dụng
        if (!messageProvider.isPollingActive) {
          messageProvider.startPolling();
        }
        // Cập nhật tin nhắn ngay lập tức
        messageProvider.fetchMessages(widget.userId);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        // Ứng dụng vào background, không cần dừng polling vì đã xử lý ở MessagesTab
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _userActivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Cập nhật hoạt động người dùng
    _updateUserActivity();
    
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      await messageProvider.sendMessage(widget.userId, image: File(image.path));
    }
  }

  void _sendMessage() async {
    // Cập nhật hoạt động người dùng khi gửi tin nhắn
    _updateUserActivity();
    
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    _messageController.clear();

    final messageProvider = Provider.of<MessageProvider>(context, listen: false);
    await messageProvider.sendMessage(widget.userId, content: messageText);

    // Cuộn xuống tin nhắn mới nhất
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _updateUserActivity,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF2AABEE),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Hero(
                tag: 'avatar_${widget.userId}',
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withOpacity(0.9),
                  child: const Icon(Icons.person, size: 24, color: Color(0xFF2AABEE)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'Trực tuyến',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.videocam, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2AABEE).withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Consumer<MessageProvider>(
                  builder: (context, messageProvider, child) {
                    if (messageProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2AABEE)),
                        ),
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
                                messageProvider.fetchMessages(widget.userId);
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

                    if (messageProvider.messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Chưa có tin nhắn nào',
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }

                    // Cuộn xuống tin nhắn cuối cùng khi có tin nhắn mới
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients && _scrollToNewMessages) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: messageProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = messageProvider.messages[index];
                        return _buildMessageItem(message);
                      },
                    );
                  },
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(Message message) {
    final isMine = message.isMine;
    final time = DateFormat('HH:mm').format(DateTime.parse(message.createdAt));
    final isRead = message.isRead;
    final hasImage = (message.image != null && message.image!.isNotEmpty) || 
                     (message.imageUrl != null && message.imageUrl!.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2AABEE).withOpacity(0.2),
              child: const Icon(Icons.person, size: 18, color: Color(0xFF2AABEE)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                top: 2,
                bottom: 2,
                left: isMine ? 64 : 0,
                right: isMine ? 0 : 64,
              ),
              padding: hasImage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xFF2AABEE) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMine ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasImage)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageGalleryView(
                              initialImage: _sanitizeUrl(message.imageUrl ?? message.image ?? ''),
                              messages: Provider.of<MessageProvider>(context, listen: false)
                                  .messages
                                  .where((m) => m.image != null || m.imageUrl != null)
                                  .toList(),
                              currentMessage: message,
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          _sanitizeUrl(message.imageUrl ?? message.image ?? ''),
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width * 0.65,
                          height: 200,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.65,
                              height: 200,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isMine ? Colors.white : const Color(0xFF2AABEE),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  if (message.content.isNotEmpty)
                    Padding(
                      padding: hasImage 
                          ? const EdgeInsets.all(12)
                          : EdgeInsets.zero,
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: isMine ? Colors.white : Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  Padding(
                    padding: hasImage 
                        ? const EdgeInsets.only(left: 12, right: 12, bottom: 8)
                        : const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            color: isMine ? Colors.white70 : Colors.black54,
                            fontSize: 11,
                          ),
                        ),
                        if (isMine) ...[  
                          const SizedBox(width: 4),
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            size: 14,
                            color: isRead ? Colors.white : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2AABEE).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add_photo_alternate, size: 24),
                color: const Color(0xFF2AABEE),
                onPressed: _pickImage,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập tin nhắn...',
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      color: const Color(0xFF2AABEE),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2AABEE), Color(0xFF0D8ECF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x292AABEE),
                    offset: Offset(0, 3),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: _messageController.text.trim().isEmpty ? null : _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    child: Icon(
                      _messageController.text.trim().isEmpty ? Icons.mic : Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _sanitizeUrl(String url) {
    // Loại bỏ thẻ HTML từ URL
    if (url.contains('<br />')) {
      print('URL có chứa thẻ HTML: $url');
      return url.replaceAll('<br />', '').trim();
    }
    return url;
  }
}