import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<bool> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _apiService.getToken();
      if (token != null) {
        _user = await _apiService.getUserProfile();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> checkApiConnection() async {
    try {
      return await _apiService.checkApiConnection();
    } catch (e) {
      _error = 'Không thể kết nối đến máy chủ: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Kiểm tra kết nối trước khi thử đăng nhập
    final isConnected = await checkApiConnection();
    if (!isConnected) {
      _error = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và API server.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await _apiService.login(email, password);
      print('Login response: $response');
      
      if (response['status'] == 'success') {
        try {
          // Phản hồi thành công, trích xuất thông tin user
          final userData = response['data']['user'];
          print('User data: $userData');
          
          _user = User.fromJson(userData);
          print('User đã được tạo: ${_user?.name}, ${_user?.role}');
          
          _isLoading = false;
          notifyListeners();
          return true;
        } catch (e) {
          print('Lỗi khi phân tích dữ liệu người dùng: $e');
          print('Response data structure: ${response['data']}');
          _error = 'Lỗi khi xử lý dữ liệu người dùng: ${e.toString()}';
        }
      } else {
        _error = response['message'] ?? 'Đăng nhập thất bại';
      }
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      _error = 'Lỗi kết nối: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String name, String email, String password, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    // Kiểm tra kết nối trước khi thử đăng ký
    final isConnected = await checkApiConnection();
    if (!isConnected) {
      _error = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và API server.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final response = await _apiService.register(name, email, password, role);
      print('Register response: $response');
      
      if (response['status'] == 'success') {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Đăng ký thất bại';
      }
    } catch (e) {
      print('Lỗi đăng ký: $e');
      _error = 'Lỗi kết nối: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 