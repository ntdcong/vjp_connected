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

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _settingsScrollController = ScrollController();
  bool _scrollToNewMessages = true;
  late TabController _tabController;
  
  // Sử dụng để theo dõi hoạt động của người dùng
  DateTime _lastUserActivity = DateTime.now();
  Timer? _userActivityTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _tabController.dispose();
    _settingsScrollController.dispose();
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                // Chuyển sang tab cài đặt
                _tabController.animateTo(1);
                
                // Đợi animation chuyển tab hoàn tất
                Future.delayed(const Duration(milliseconds: 300), () {
                  switch (value) {
                    case 'search':
                      // Scroll đến phần tìm kiếm
                      _settingsScrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      break;
                    case 'media':
                      // Scroll đến phần media (khoảng 300px từ đầu)
                      _settingsScrollController.animateTo(
                        300,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      break;
                    case 'settings':
                      // Scroll đến phần cài đặt (khoảng 600px từ đầu)
                      _settingsScrollController.animateTo(
                        600,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      break;
                  }
                });
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'search',
                  child: Row(
                    children: [
                      Icon(Icons.search, color: Color(0xFF2AABEE)),
                      SizedBox(width: 8),
                      Text('Tìm kiếm tin nhắn'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'media',
                  child: Row(
                    children: [
                      Icon(Icons.photo_library, color: Color(0xFF2AABEE)),
                      SizedBox(width: 8),
                      Text('Xem ảnh và file'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Color(0xFF2AABEE)),
                      SizedBox(width: 8),
                      Text('Cài đặt chat'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab Chat
            Container(
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
            // Tab Cài đặt
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Container(
      color: Colors.grey[50],
      child: ListView(
        controller: _settingsScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          _buildSearchSection(),
          const SizedBox(height: 20),
          _buildMediaSection(),
          const SizedBox(height: 20),
          _buildChatSettingsSection(),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2AABEE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.search, color: Color(0xFF2AABEE), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tìm kiếm tin nhắn',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Nhập từ khóa tìm kiếm...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2AABEE), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onChanged: (value) {
                // TODO: Implement search functionality
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2AABEE).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.photo_library, color: Color(0xFF2AABEE), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Album ảnh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full media gallery
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2AABEE),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
          ),
          Consumer<MessageProvider>(
            builder: (context, messageProvider, child) {
              final mediaMessages = messageProvider.messages
                  .where((m) => m.image != null || m.imageUrl != null)
                  .toList();

              if (mediaMessages.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Icon(Icons.photo_library_outlined, color: Colors.grey[400], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Chưa có ảnh nào trong cuộc trò chuyện',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Chỉ lấy 9 ảnh mới nhất
              final recentMediaMessages = mediaMessages.take(9).toList();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: recentMediaMessages.length,
                itemBuilder: (context, index) {
                  final message = recentMediaMessages[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageGalleryView(
                            initialImage: _sanitizeUrl(message.imageUrl ?? message.image ?? ''),
                            messages: mediaMessages, // Truyền toàn bộ ảnh vào gallery
                            currentMessage: message,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _sanitizeUrl(message.imageUrl ?? message.image ?? ''),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Color(0xFF2AABEE),
                                    ),
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                          if (index == 8 && mediaMessages.length > 9)
                            Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Center(
                                child: Text(
                                  '+${mediaMessages.length - 9}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChatSettingsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2AABEE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.settings, color: Color(0xFF2AABEE), size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cài đặt chat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Thông báo',
            subtitle: 'Bật/tắt thông báo tin nhắn mới',
            onTap: () {
              // TODO: Implement notification settings
            },
          ),
          _buildSettingItem(
            icon: Icons.block,
            title: 'Chặn người dùng',
            subtitle: 'Chặn ${widget.userName}',
            onTap: () {
              // TODO: Implement block user
            },
          ),
          _buildSettingItem(
            icon: Icons.delete,
            title: 'Xóa lịch sử chat',
            subtitle: 'Xóa tất cả tin nhắn trong cuộc trò chuyện',
            onTap: () {
              // TODO: Implement clear chat history
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2AABEE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF2AABEE), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2AABEE).withOpacity(0.1),
              child: const Icon(Icons.person, size: 18, color: Color(0xFF2AABEE)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isMine ? 64 : 0,
                right: isMine ? 0 : 64,
              ),
              padding: hasImage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isMine 
                    ? const Color(0xFF2AABEE)
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(24),
                  topRight: const Radius.circular(24),
                  bottomLeft: isMine ? const Radius.circular(24) : const Radius.circular(6),
                  bottomRight: isMine ? const Radius.circular(6) : const Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
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
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          _sanitizeUrl(message.imageUrl ?? message.image ?? ''),
                          fit: BoxFit.cover,
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: 200,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: MediaQuery.of(context).size.width * 0.6,
                              height: 200,
                              color: Colors.grey[100],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isMine ? Colors.white : const Color(0xFF2AABEE),
                                  ),
                                  strokeWidth: 2,
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
                          height: 1.3,
                        ),
                      ),
                    ),
                  Padding(
                    padding: hasImage 
                        ? const EdgeInsets.only(left: 12, right: 12, bottom: 8)
                        : const EdgeInsets.only(top: 4),
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