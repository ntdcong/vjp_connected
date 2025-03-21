import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';

class MessageProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  int? _selectedUserId;
  bool _isLoading = false;
  String? _error;

  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  int? get selectedUserId => _selectedUserId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _apiService.getConversations();
    } catch (e) {
      _error = 'Không thể tải cuộc trò chuyện: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMessages(int userId) async {
    _isLoading = true;
    _error = null;
    _selectedUserId = userId;
    notifyListeners();

    try {
      _messages = await _apiService.getConversation(userId);
    } catch (e) {
      _error = 'Không thể tải tin nhắn: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> sendMessage(int receiverId, String content) async {
    if (content.trim().isEmpty) {
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.sendMessage(receiverId, content);
      if (response['status'] == 'success') {
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
} 