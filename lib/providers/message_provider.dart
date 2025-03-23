import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import '../models/message.dart';
import '../services/api_service.dart';

class MessageProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  int? _selectedUserId;
  bool _isLoading = false;
  bool _isLoadingConversations = false;
  String? _error;
  String? _conversationError;
  
  // Các biến cho polling
  Timer? _conversationsPollingTimer;
  Timer? _messagesPollingTimer;
  bool _isPollingActive = false;
  
  // Polling thích ứng
  static const Duration _fastPollingInterval = Duration(seconds: 3);
  static const Duration _normalPollingInterval = Duration(seconds: 5);
  static const Duration _slowPollingInterval = Duration(seconds: 10);
  
  // Theo dõi thời gian tin nhắn gần nhất
  DateTime? _lastMessageTime;
  DateTime? _lastActivityTime; // Thời gian hoạt động gần nhất của người dùng
  
  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  int? get selectedUserId => _selectedUserId;
  bool get isLoading => _isLoading;
  bool get isLoadingConversations => _isLoadingConversations;
  String? get error => _error;
  String? get conversationError => _conversationError;
  bool get isPollingActive => _isPollingActive;

  // Cập nhật thời gian hoạt động gần nhất
  void updateLastActivity() {
    _lastActivityTime = DateTime.now();
  }

  // Xác định khoảng thời gian polling dựa trên mức độ hoạt động
  Duration _getPollingInterval() {
    // Nếu chưa có thời gian hoạt động, sử dụng khoảng thời gian mặc định
    if (_lastActivityTime == null) {
      return _normalPollingInterval;
    }
    
    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(_lastActivityTime!);
    
    // Nếu vừa có tin nhắn mới trong 5 phút qua, sử dụng polling nhanh
    if (_lastMessageTime != null) {
      final timeSinceLastMessage = now.difference(_lastMessageTime!);
      if (timeSinceLastMessage < const Duration(minutes: 5)) {
        return _fastPollingInterval;
      }
    }
    
    // Nếu người dùng hoạt động gần đây (trong vòng 2 phút), sử dụng polling nhanh
    if (timeSinceLastActivity < const Duration(minutes: 2)) {
      return _fastPollingInterval;
    }
    
    // Nếu người dùng hoạt động trong vòng 5 phút, sử dụng polling thông thường
    if (timeSinceLastActivity < const Duration(minutes: 5)) {
      return _normalPollingInterval;
    }
    
    // Người dùng không hoạt động trong thời gian dài, sử dụng polling chậm
    return _slowPollingInterval;
  }

  // Khởi động polling với chế độ thích ứng
  void startPolling() {
    if (!_isPollingActive) {
      _isPollingActive = true;
      updateLastActivity();
      
      // Thiết lập polling ban đầu
      _setupPollingTimers();
      
      notifyListeners();
    }
  }
  
  // Thiết lập các timer polling
  void _setupPollingTimers() {
    // Hủy timer cũ nếu có
    _conversationsPollingTimer?.cancel();
    _messagesPollingTimer?.cancel();
    
    // Lấy khoảng thời gian polling thích ứng
    final interval = _getPollingInterval();
    
    // Thiết lập timer mới
    _conversationsPollingTimer = Timer.periodic(interval, (timer) {
      if (!_isLoadingConversations) {
        fetchConversationsSilently();
      }
    });
    
    // Thiết lập timer cho tin nhắn nếu đang xem một cuộc trò chuyện
    if (_selectedUserId != null) {
      _messagesPollingTimer = Timer.periodic(interval, (timer) {
        if (!_isLoading && _selectedUserId != null) {
          fetchMessagesSilently(_selectedUserId!);
        }
      });
    }
  }
  
  // Cập nhật timer polling khi có hoạt động mới
  void _updatePollingRate() {
    if (_isPollingActive) {
      _setupPollingTimers();
    }
  }
  
  // Dừng polling
  void stopPolling() {
    _isPollingActive = false;
    _conversationsPollingTimer?.cancel();
    _messagesPollingTimer?.cancel();
    _conversationsPollingTimer = null;
    _messagesPollingTimer = null;
    notifyListeners();
  }
  
  // Fetch cuộc trò chuyện mà không hiển thị loading indicator
  Future<void> fetchConversationsSilently() async {
    try {
      final updatedConversations = await _apiService.getConversations();
      
      // Kiểm tra xem có thay đổi không trước khi cập nhật
      if (_areConversationsDifferent(_conversations, updatedConversations)) {
        _conversations = updatedConversations;
        
        // Cập nhật thời gian tin nhắn mới nhất nếu có cuộc trò chuyện
        if (updatedConversations.isNotEmpty) {
          // Tìm tin nhắn gần nhất
          DateTime? newestMessageTime;
          for (var conversation in updatedConversations) {
            final msgTime = DateTime.parse(conversation.lastMessage.time);
            if (newestMessageTime == null || msgTime.isAfter(newestMessageTime)) {
              newestMessageTime = msgTime;
            }
          }
          
          // Nếu có tin nhắn mới hơn tin nhắn cuối cùng đã biết, cập nhật
          if (_lastMessageTime == null || 
              (newestMessageTime != null && newestMessageTime.isAfter(_lastMessageTime!))) {
            _lastMessageTime = newestMessageTime;
            // Có tin nhắn mới, nên cập nhật tốc độ polling
            _updatePollingRate();
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Lỗi khi cập nhật cuộc trò chuyện (silent): $e');
      // Không cập nhật error state để tránh gây khó chịu cho người dùng
    }
  }
  
  // Fetch tin nhắn mà không hiển thị loading indicator
  Future<void> fetchMessagesSilently(int userId) async {
    try {
      final updatedMessages = await _apiService.getConversation(userId);
      
      // Kiểm tra xem có tin nhắn mới không
      if (_areMessagesDifferent(_messages, updatedMessages)) {
        _messages = updatedMessages;
        
        // Cập nhật thời gian tin nhắn mới nhất nếu có tin nhắn
        if (updatedMessages.isNotEmpty) {
          final latestMessage = updatedMessages.last;
          final latestMessageTime = DateTime.parse(latestMessage.createdAt);
          
          if (_lastMessageTime == null || latestMessageTime.isAfter(_lastMessageTime!)) {
            _lastMessageTime = latestMessageTime;
            // Có tin nhắn mới, nên cập nhật tốc độ polling
            _updatePollingRate();
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      print('Lỗi khi cập nhật tin nhắn (silent): $e');
      // Không cập nhật error state
    }
  }
  
  // Kiểm tra xem danh sách cuộc trò chuyện có thay đổi không
  bool _areConversationsDifferent(List<Conversation> oldList, List<Conversation> newList) {
    if (oldList.length != newList.length) {
      return true;
    }
    
    for (int i = 0; i < oldList.length; i++) {
      // So sánh id tin nhắn cuối cùng và trạng thái đã đọc
      if (oldList[i].lastMessage.id != newList[i].lastMessage.id ||
          oldList[i].lastMessage.isRead != newList[i].lastMessage.isRead) {
        return true;
      }
    }
    
    return false;
  }
  
  // Kiểm tra xem danh sách tin nhắn có thay đổi không
  bool _areMessagesDifferent(List<Message> oldList, List<Message> newList) {
    if (oldList.length != newList.length) {
      return true;
    }
    
    // Chỉ kiểm tra tin nhắn cuối cùng để tối ưu hiệu suất
    if (oldList.isNotEmpty && newList.isNotEmpty) {
      final oldLastMsg = oldList.last;
      final newLastMsg = newList.last;
      
      return oldLastMsg.id != newLastMsg.id || 
             oldLastMsg.isRead != newLastMsg.isRead;
    }
    
    return false;
  }

  Future<void> fetchConversations() async {
    _isLoadingConversations = true;
    _conversationError = null;
    notifyListeners();

    try {
      _conversations = await _apiService.getConversations();
      _conversationError = null;
      
      // Cập nhật thời gian hoạt động
      updateLastActivity();
    } catch (e) {
      _conversationError = 'Không thể tải danh sách cuộc trò chuyện: ${e.toString()}';
      print('Error fetching conversations: $e');
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(int userId) async {
    _isLoading = true;
    _error = null;
    _selectedUserId = userId;
    notifyListeners();

    try {
      _messages = await _apiService.getConversation(userId);
      
      // Cập nhật thời gian hoạt động
      updateLastActivity();
      
      // Nếu đang xem tin nhắn, khởi động polling cho tin nhắn nếu chưa active
      if (_isPollingActive && _messagesPollingTimer == null) {
        // Sử dụng interval thích ứng
        final interval = _getPollingInterval();
        _messagesPollingTimer = Timer.periodic(interval, (timer) {
          if (!_isLoading && _selectedUserId != null) {
            fetchMessagesSilently(_selectedUserId!);
          }
        });
      }
    } catch (e) {
      _error = 'Không thể tải tin nhắn: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMessage(int receiverId, {String? content, File? image}) async {
    if (content == null && image == null) {
      return false;
    }
    if (content != null && content.trim().isEmpty && image == null) {
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.sendMessage(receiverId, content: content, image: image);
      if (response['status'] == 'success') {
        // Cập nhật thời gian hoạt động và tin nhắn mới nhất
        updateLastActivity();
        _lastMessageTime = DateTime.now();
        
        // Cập nhật tốc độ polling sau khi gửi tin nhắn
        _updatePollingRate();
        
        // Làm mới danh sách tin nhắn nếu đang xem cuộc trò chuyện này
        if (_selectedUserId == receiverId) {
          await fetchMessages(receiverId);
        }
        
        // Làm mới danh sách cuộc trò chuyện để cập nhật tin nhắn mới nhất
        await fetchConversations();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Gửi tin nhắn thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteMessage(int messageId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.deleteMessage(messageId);
      if (response['status'] == 'success') {
        // Cập nhật thời gian hoạt động
        updateLastActivity();
        
        // Xóa tin nhắn khỏi danh sách local
        _messages.removeWhere((message) => message.id == messageId);
        
        // Làm mới danh sách cuộc trò chuyện
        await fetchConversations();
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Xóa tin nhắn thất bại';
      }
    } catch (e) {
      _error = 'Lỗi kết nối: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Đảm bảo hủy tất cả timer khi dispose provider
  void dispose() {
    stopPolling();
    super.dispose();
  }
}