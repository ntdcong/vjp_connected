import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/message_provider.dart';
import '../models/message.dart';
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
      // Bắt sự kiện chạm để cập nhật thời gian hoạt động
      onTap: _updateUserActivity,
      child: Scaffold(
        appBar: AppBar(
          elevation: 1,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2AABEE)),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF2AABEE).withOpacity(0.2),
                child: const Icon(Icons.person, size: 24, color: Color(0xFF2AABEE)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Trực tuyến',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.call, color: Color(0xFF2AABEE)),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF2AABEE)),
              onPressed: () {},
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            image: DecorationImage(
              image: const AssetImage('assets/images/chat_bg.png'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.white.withOpacity(0.05),
                BlendMode.dstATop,
              ),
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
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.person, size: 18, color: Colors.blue),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xFFE3F2FD) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isMine ? const Radius.circular(16) : const Radius.circular(4),
                  bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 1,
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
                            builder: (context) => Scaffold(
                              appBar: AppBar(
                                backgroundColor: Colors.black,
                                leading: IconButton(
                                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                              body: Center(
                                child: InteractiveViewer(
                                  minScale: 0.5,
                                  maxScale: 4.0,
                                  child: Image.network(
                                    _sanitizeUrl(message.imageUrl ?? message.image ?? ''),
                                    fit: BoxFit.contain,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Lỗi tải ảnh: $error');
                                      print('URL ảnh: ${message.imageUrl ?? message.image}');
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.error, size: 48, color: Colors.red),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Không thể tải ảnh',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              backgroundColor: Colors.black,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                          maxHeight: 200,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _sanitizeUrl(message.imageUrl ?? message.image ?? ''),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 200,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isMine ? const Color(0xFF2AABEE) : Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print('Lỗi tải ảnh: $error');
                              print('URL ảnh: ${message.imageUrl ?? message.image}');
                              return Container(
                                width: 200,
                                height: 150,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error, size: 32, color: Colors.red),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Không thể tải ảnh',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        time,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 11,
                        ),
                      ),
                      if (isMine) ...[  
                        const SizedBox(width: 4),
                        Icon(
                          isRead ? Icons.done_all : Icons.done,
                          size: 14,
                          color: isRead ? const Color(0xFF2AABEE) : Colors.black38,
                        ),
                      ],
                    ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            offset: const Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, size: 22),
            color: const Color(0xFF2AABEE),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Tin nhắn',
                        hintStyle: TextStyle(color: Colors.black54),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined, size: 22),
                    color: const Color(0xFF2AABEE),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _messageController.text.trim().isEmpty ? _pickImage : _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2AABEE),
              ),
              child: Icon(
                _messageController.text.trim().isEmpty ? Icons.camera_alt : Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
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